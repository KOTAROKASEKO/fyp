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
firebase_admin.initialize_app()

# --- Step 2: Set Global Function Options ---
options.set_global_options(
    region="asia-southeast1",
    memory=options.MemoryOption.GB_1,
)

# --- Step 3: Define Global Client Placeholders ---
gmaps_client = None
generative_model = None

# --- Step 4: Import Function Definitions ---
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
            # It's better to use a specific version for stability, e.g., 'gemini-1.5-flash'
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

    db = firestore.client()
    user_id = event.params["userId"]
    plan_id = event.params["planId"]
    request_data = event.data.to_dict()
    doc_ref = db.collection("travelRequests").document(user_id).collection("plans").document(plan_id)

    logging.info(f"🚀 Processing request {plan_id} for user {user_id}.")
    doc_ref.update({"status": "processing"})

    try:
        user_prompt = request_data.get("request", "")
        city = request_data.get("city", "")
        
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
            places_result = gmaps_client.places(query=keyword, location=start_location, radius=10000)
            for place in places_result.get('results', []):
                candidate_place_ids.add(place['place_id'])
        
        logging.info(f"📍 Found {len(candidate_place_ids)} candidate places.")

        valid_places = []
        # Limit to 9 candidates to stay within API limits
        for place_id in list(candidate_place_ids)[:9]: 
            # --- 👇 MODIFIED: Added 'geometry' to the requested fields ---
            details = gmaps_client.place(place_id=place_id, fields=['place_id', 'name', 'vicinity', 'rating', 'geometry'])
            place_data = details.get('result', {})
            if place_data.get('rating'):
                valid_places.append({
                    "place_id": place_data.get('place_id'),
                    "name": place_data.get('name'),
                    "address": place_data.get('vicinity'),
                    "rating": place_data.get('rating'),
                    # --- 👇 ADDED: Storing the geometry data ---   
                    "geometry": place_data.get('geometry', {}).get('location', {})
                })
        
        logging.info(f"✅ Filtered down to {len(valid_places)} valid places with details.")
        
        if not valid_places:
            raise ValueError("No valid places found after filtering.")

        synthesis_prompt = f"""
        You are an expert travel planner. Create a logical and enjoyable half-day itinerary in {city}.
        Here is a list of available places with their details: {json.dumps(valid_places, indent=2)}
        Your task is to select 3-4 places from the list that form a coherent schedule.
        The final output must be a JSON object with a key "plan" which is an array of events.
        Each event in the array should have 'time', 'place_name', and 'activity_description'.
        Do not include places that are not in the provided list.
        Ensure the 'place_name' in your output exactly matches a 'name' from the provided list.
        Output ONLY the JSON object.
        """
        final_plan_response = generative_model.generate_content(synthesis_prompt)
        # The AI returns a plan with only name, time, and description
        ai_plan_data = json.loads(final_plan_response.text.strip().replace("```json", "").replace("```", ""))
        ai_plan = ai_plan_data.get("plan", [])

        # --- 👇 NEW: Enrich the AI's plan with the missing data (place_id and geometry) ---
        enriched_plan = []
        for step in ai_plan:
            place_name = step.get("place_name")
            # Find the corresponding place from our detailed list
            matching_place = next((p for p in valid_places if p["name"] == place_name), None)
            
            if matching_place:
                # Add the missing details to the step
                step["place_id"] = matching_place.get("place_id")
                step["geometry"] = matching_place.get("geometry")
                enriched_plan.append(step)
            else:
                # If the AI hallucinates a place not in our list, we log it but might skip it
                logging.warning(f"AI generated a place '{place_name}' not found in the valid places list. Skipping.")

        if not enriched_plan:
            raise ValueError("AI failed to generate a valid plan from the provided places.")

        doc_ref.update({
            "status": "completed",
            "plan": enriched_plan, # Save the enriched plan
            "updatedAt": firestore.SERVER_TIMESTAMP
        })
        logging.info(f"🎉 Successfully generated and saved enriched plan for request {plan_id}.")

    except Exception as e:
        logging.error(f"❌ Error processing request {plan_id}: {e}", exc_info=True)
        doc_ref.update({"status": "error", "errorMessage": str(e)})