# main.py

import logging
import os
import json
import firebase_admin
from firebase_admin import firestore, messaging
from firebase_functions import options, firestore_fn

# Google Cloud Services
from google.cloud import secretmanager
import google.generativeai as genai
import googlemaps
import vertexai

# --- Step 1: Initialize Firebase Admin SDK ---
firebase_admin.initialize_app()

# --- Step 2: Set Global Function Options ---
options.set_global_options(
    region="asia-southeast1",
    memory=options.MemoryOption.GB_1,
    timeout_sec=120
)

gmaps_client = None
generative_model = None

# --- Step 4: Import Function Definitions ---
from posts import autoTagPost, onPostInteraction, onPostSaved, onPostUnsaved
from post_notifications import send_like_notification


def _get_secret(secret_id: str, project_id: str) -> str | None:
    """Fetches a secret from Google Cloud Secret Manager."""
    try:
        client = secretmanager.SecretManagerServiceClient()
        name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
        response = client.access_secret_version(request={"name": name})
        return response.payload.data.decode("UTF-8")
    except Exception as e:
        logging.error(f"Failed to access secret {secret_id}. Error: {e}")
        return None

def _initialize_clients():
    """
    Initializes API clients if they haven't been already.
    """
    global gmaps_client, generative_model

    PROJECT_ID = os.environ.get("GCP_PROJECT")
    if not PROJECT_ID:
        logging.critical("GCP_PROJECT environment variable not set. Cannot initialize clients.")
        return

    # Initialize Google Maps Client
    if gmaps_client is None:
        MAPS_API_KEY = _get_secret("Maps_API_KEY", PROJECT_ID)
        if MAPS_API_KEY:
            gmaps_client = googlemaps.Client(key=MAPS_API_KEY)
        else:
            logging.error("Maps API Key is missing. Maps functionality will be disabled.")

    # Initialize Generative AI Model
    if generative_model is None:
        GOOGLE_AI_API_KEY = _get_secret("GOOGLE_AI_API_KEY", PROJECT_ID)
        if GOOGLE_AI_API_KEY:
            genai.configure(api_key=GOOGLE_AI_API_KEY)
            generative_model = genai.GenerativeModel('gemini-1.5-flash')
        else:
            logging.error("Google AI API Key is missing. AI functionality will be disabled.")
            
    try:
        vertexai.init(project=PROJECT_ID)
    except Exception as e:
        logging.warning(f"Could not initialize Vertex AI: {e}")


@firestore_fn.on_document_created(document="travelRequests/{userId}/plans/{planId}")
def generate_travel_plan(event: firestore_fn.Event[firestore.DocumentSnapshot]) -> None:
    """
    Triggered by Firestore document creation to generate an AI travel plan.
    """
    _initialize_clients()
    
    if not gmaps_client or not generative_model:
        logging.error("Aborting travel plan generation due to client initialization failure.")
        return

    db = firebase_admin.firestore.client()
    user_id = event.params["userId"]
    plan_id = event.params["planId"]
    request_data = event.data.to_dict()
    doc_ref = db.collection("travelRequests").document(user_id).collection("plans").document(plan_id)

    logging.info(f"🚀 Processing request {plan_id} for user {user_id}.")
    doc_ref.update({"status": "processing"})

    try:
        user_prompt = request_data.get("request", "")
        city = request_data.get("city", "")
        fcm_token = request_data.get("fcmToken")
        
        deconstruction_prompt = f"""
        Analyze the following user request for a trip to {city}. 
        Based on the request "{user_prompt}", generate a JSON object with a key "search_keywords" 
        which is a list of 3-5 specific, practical search terms for Google Maps Places API.
        For example: "historical landmarks in {city}", "highly-rated local restaurants in {city}", "modern art museums in {city}".
        Output ONLY the JSON object.
        """
        response = generative_model.generate_content(deconstruction_prompt)
        structured_query = json.loads(response.text.strip().replace("```json", "").replace("```", ""))
        search_keywords = structured_query.get("search_keywords", [])
        logging.info(f"🔍 Deconstructed keywords: {search_keywords}")

        geocode_result = gmaps_client.geocode(city)
        if not geocode_result:
            raise ValueError(f"Could not find coordinates for city: {city}")
        
        start_location = geocode_result[0]['geometry']['location']
        candidate_place_ids = set()
        for keyword in search_keywords:
            places_result = gmaps_client.places(query=keyword, location=start_location, radius=20000)
            for place in places_result.get('results', []):
                candidate_place_ids.add(place['place_id'])
        
        logging.info(f"📍 Found {len(candidate_place_ids)} candidate places.")

        valid_places = []
        for place_id in list(candidate_place_ids)[:15]:
            details = gmaps_client.place(place_id=place_id, fields=['place_id', 'name', 'vicinity', 'rating', 'geometry', 'photo', 'type'])
            place_data = details.get('result', {})
            if place_data.get('rating'):
                valid_places.append({
                    "place_id": place_data.get('place_id'),
                    "name": place_data.get('name'),
                    "address": place_data.get('vicinity'),
                    "rating": place_data.get('rating'), 
                    "geometry": place_data.get('geometry', {}).get('location', {}),
                    "photos": place_data.get('photos'),
                    "types": place_data.get('types')
                })
        
        logging.info(f"✅ Filtered down to {len(valid_places)} valid places with details.")
        
        if not valid_places:
            raise ValueError("No valid places found after filtering.")

        # main.py の修正案 (synthesis_prompt の部分)

        synthesis_prompt = f"""
        You are a master storyteller and a travel poet, creating an unforgettable narrative for a trip to {city}.
        The user's preferences are: "{user_prompt}".

        Here is a palette of inspirational places, including potential hotels:
        {json.dumps(valid_places, indent=2)}

        **Your Mission:**
        1. **Select a Hotel:** From the list, choose ONE suitable hotel that will serve as the starting and ending point of the journey.
        2. **Curate a Journey:** Select 3-5 additional places that perfectly align with the user's request, creating a logical and magical flow for their day.
        3. **Breathe Life into Each Step:** For each place (including the hotel check-in), write a captivating 'activity_description'. Frame each activity as a unique experience. Adapt your voice to the user's occasion.
        4. **Calculate Estimated Cost:** Based on the selected places and activities, calculate an estimated total cost for the entire plan in Japanese Yen (JPY). Consider typical expenses like food, tickets, and transport.
        5. **Format as JSON:** The final output MUST be a valid JSON object. It should have a key "plan" (an array of events) and a key "estimated_total_cost" (an integer). The first event in the plan should always be the hotel check-in.

        **Example of Your Art:**
        {{
            "plan": [
                {{
                    "time": "3:00 PM",
                    "place_name": "The Grand Palace Hotel",
                    "activity_description": "Your adventure begins here. Drop off your bags in a room with a view, take a deep breath, and feel the excitement of the city settle in. This is your sanctuary, your basecamp for the story you're about to write."
                }},
                {{
                    "time": "5:00 PM",
                    "place_name": "Serenity Art Gallery",
                    "activity_description": "As the afternoon sun casts a golden glow, wander hand-in-hand with your partner through halls of inspiration. Let the quiet hum of the gallery be the soundtrack to your own private world."
                }}
            ],
            "estimated_total_cost": 25000
        }}

        Now, begin your creation for the user's trip to {city}. Output ONLY the JSON object.
        """
        
        final_plan_response = generative_model.generate_content(synthesis_prompt)
        ai_plan_data = json.loads(final_plan_response.text.strip().replace("```json", "").replace("```", ""))
        ai_plan = ai_plan_data.get("plan", [])

        enriched_plan = []
        for step in ai_plan:
            place_name = step.get("place_name")
            matching_place = next((p for p in valid_places if p["name"] == place_name), None)
            
            if matching_place:
                step["place_id"] = matching_place.get("place_id")
                step["geometry"] = matching_place.get("geometry")
                # Add photo reference to each step if available
                if matching_place.get('photos'):
                    step['photo_reference'] = matching_place['photos'][0].get('photo_reference')
                enriched_plan.append(step)
            else:
                logging.warning(f"AI generated a place '{place_name}' not found in the valid places list. Skipping.")

        if not enriched_plan:
            raise ValueError("AI failed to generate a valid plan from the provided places.")

        thumbnail_photo_reference = None
        if enriched_plan:
            first_step_place_id = enriched_plan[0].get("place_id")
            first_place_details = next((p for p in valid_places if p["place_id"] == first_step_place_id), None)
            
            if first_place_details and 'photos' in first_place_details and first_place_details['photos']:
                thumbnail_photo_reference = first_place_details['photos'][0].get('photo_reference')
                logging.info(f"📸 Found photo reference for thumbnail.")

        update_data = {
            "status": "completed",
            "plan": enriched_plan,
            "updatedAt": firestore.SERVER_TIMESTAMP
        }
        if thumbnail_photo_reference:
            update_data["thumbnail_photo_reference"] = thumbnail_photo_reference

        doc_ref.update(update_data)
        logging.info(f"🎉 Successfully generated and saved enriched plan for request {plan_id}.")

        if fcm_token:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=f"Your plan for {city} is ready! ✈️",
                        body="Open the app to see your personalized travel itinerary.",
                    ),
                    token=fcm_token,
                )
                response = messaging.send(message)
                logging.info(f"✅ Successfully sent notification: {response}")
            except Exception as e:
                logging.error(f"❌ Failed to send notification for plan {plan_id}: {e}")
        else:
            logging.warning(f"⚠️ No FCM token found for plan {plan_id}. Cannot send notification.")

    except Exception as e:
        logging.error(f"❌ Error processing request {plan_id}: {e}", exc_info=True)
        doc_ref.update({"status": "error", "errorMessage": str(e)})