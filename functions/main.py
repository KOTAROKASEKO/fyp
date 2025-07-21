# main.py

import logging
import os
import json
import firebase_admin
from firebase_admin import firestore
from firebase_functions import options, firestore_fn

# Google Cloud Services
from google.cloud import secretmanager
import google.generativeai as genai
import googlemaps
import vertexai # Keep this for other potential functions

# --- Step 1: Initialize Firebase Admin SDK ---
# This runs once per instance, which is safe.
firebase_admin.initialize_app()

# --- Step 2: Set Global Function Options ---
options.set_global_options(
    region="asia-southeast1",
    memory=options.MemoryOption.GB_1,
)

# --- Step 3: Define Global Client Placeholders ---
# These are placeholders. We will initialize them lazily (on-demand)
# to avoid running code during deployment analysis.
gmaps_client = None
generative_model = None

# --- Step 4: Import Function Definitions ---
# This allows Firebase to discover functions in other files.
from dailyquiz import generate_daily_quiz
from posts import autoTagPost, onPostInteraction, onPostSaved, onPostUnsaved


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
    This function is called at the beginning of any HTTP or event-triggered function
    that needs these clients. It runs only on a 'cold start'.
    """
    global gmaps_client, generative_model

    # The GCP_PROJECT environment variable is reliably available in the runtime environment.
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
            generative_model = genai.GenerativeModel('gemini-2.5-flash')
        else:
            logging.error("Google AI API Key is missing. AI functionality will be disabled.")
            
    # Initialize Vertex AI (if needed by other functions in the future)
    # This is a lightweight init and generally safe, but can also be done here.
    try:
        vertexai.init(project=PROJECT_ID)
    except Exception as e:
        logging.warning(f"Could not initialize Vertex AI: {e}")


#
# 👇 CORRECTED TRIGGER PATH
# This now listens for new documents inside any 'plans' subcollection.
#
@firestore_fn.on_document_created(document="travelRequests/{userId}/plans/{planId}")
def generate_travel_plan(event: firestore_fn.Event[firestore.DocumentSnapshot]) -> None:
    """
    Triggered by Firestore document creation in the 'plans' subcollection.
    Orchestrates the AI travel plan generation.
    """
    # --- LAZY INITIALIZATION ---
    _initialize_clients()
    
    if not gmaps_client or not generative_model:
        logging.error("Aborting travel plan generation due to client initialization failure.")
        return

    db = firestore.client()

    # --- 👇 CORRECTED PARAMETER USAGE ---
    # Get the wildcards from the trigger path
    user_id = event.params["userId"]
    plan_id = event.params["planId"]
    
    # Get the data from the document that was just created
    request_data = event.data.to_dict()

    # --- 👇 CORRECTED DOCUMENT REFERENCE ---
    # This now points to the specific document that was created (e.g., /travelRequests/user123/plans/abc456)
    doc_ref = db.collection("travelRequests").document(user_id).collection("plans").document(plan_id)

    logging.info(f"🚀 Processing request {plan_id} for user {user_id}.")
    # Update the status on the document that was just created
    doc_ref.update({"status": "processing"})

    try:
        user_prompt = request_data.get("request", "")
        city = request_data.get("city", "")
        
        deconstruction_prompt = f"""
        Analyze the following user request for a trip to {city}. 
        Extract key activities and themes the user is interested in.
        Based on the request "{user_prompt}", generate a JSON object with a key "search_keywords" 
        which is a list of 3-5 specific, practical search terms for Google Maps Places API.
        For example: "historical landmarks", "highly-rated local restaurants", "modern art museums".
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
            places_result = gmaps_client.places(query=keyword, location=start_location, radius=10000)
            for place in places_result.get('results', []):
                candidate_place_ids.add(place['place_id'])
        
        logging.info(f"📍 Found {len(candidate_place_ids)} candidate places.")

        valid_places = []
        place_ids_for_matrix = []
        # Limit to 9 candidates to stay within API limits and keep plans concise
        for place_id in list(candidate_place_ids)[:9]: 
            details = gmaps_client.place(place_id=place_id, fields=['place_id', 'name', 'vicinity', 'rating', 'opening_hours'])
            place_data = details.get('result', {})
            if place_data.get('rating'):
                valid_places.append({
                    "place_id": place_data.get('place_id'),
                    "name": place_data.get('name'),
                    "address": place_data.get('vicinity'),
                    "rating": place_data.get('rating')
                })
                place_ids_for_matrix.append(place_data['place_id'])

        logging.info(f"✅ Filtered down to {len(valid_places)} valid places.")
        
        if not valid_places:
            raise ValueError("No valid places found after filtering.")

        origins = [start_location]
        destinations = [f"place_id:{pid}" for pid in place_ids_for_matrix]

        matrix = gmaps_client.distance_matrix(
            origins=origins,
            destinations=destinations,
            mode="driving"
        )
        logging.info("✅ Efficiently fetched travel times from origin to all candidate places.")

        rows = matrix.get('rows', [])
        if rows and 'elements' in rows[0]:
            travel_times = rows[0]['elements']
            for i, place in enumerate(valid_places):
                if i < len(travel_times) and travel_times[i]['status'] == 'OK':
                    place['travel_time_from_start_seconds'] = travel_times[i]['duration']['value']
                    place['travel_time_from_start_text'] = travel_times[i]['duration']['text']

        synthesis_prompt = f"""
        You are an expert travel planner. Create a logical and enjoyable half-day itinerary in {city}.
        Here are the available places, including the travel time from the user's starting point: {json.dumps(valid_places, indent=2)}
        Your task is to select 3-4 places from the list that form a coherent schedule.
        Prioritize places that are relatively close to each other.
        Allocate reasonable time for each activity and account for travel time between the selected spots (you can estimate this based on their proximity).
        The final output must be a JSON object representing the plan as an array of events.
        Each event should have 'time', 'place_name', and 'activity_description'.
        Output ONLY the JSON object.
        """
        final_plan_response = generative_model.generate_content(synthesis_prompt)
        final_plan = json.loads(final_plan_response.text.strip().replace("```json", "").replace("```", ""))

        # --- 👇 CORRECTED FINAL UPDATE ---
        # Update the same document that triggered the function with the final plan.
        doc_ref.update({
            "status": "completed",
            "plan": final_plan, # Save the plan into a 'plan' field
            "updatedAt": firestore.SERVER_TIMESTAMP
        })
        logging.info(f"🎉 Successfully generated and saved plan for request {plan_id}.")

    except Exception as e:
        logging.error(f"❌ Error processing request {plan_id}: {e}", exc_info=True)
        # Update the triggering document with the error status
        doc_ref.update({"status": "error", "errorMessage": str(e)})