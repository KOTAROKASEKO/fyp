import logging
import json
from datetime import datetime
from zoneinfo import ZoneInfo
import random  # Change 1: Imported for random selection

from firebase_admin import initialize_app, firestore
from firebase_functions import scheduler_fn, options

import vertexai
from vertexai.generative_models import GenerativeModel

initialize_app()

options.set_global_options(
    region="asia-southeast1",
    memory=options.MemoryOption.GB_1,
)

@scheduler_fn.on_schedule(schedule="every day 00:05", timezone="Pacific/Kiritimati")
def generate_daily_quiz(event: scheduler_fn.ScheduledEvent) -> None:
    """
    A scheduled function to generate a daily quiz about a random country's food.
    """
    logging.info("--- Function execution started. ---")
    
    try:
        # Change 2: Defined a list of countries for the quiz
        countries = [
            "Japan", "Italy", "China", "Mexico", "India", "Thailand", "France", "Spain",
            "Greece", "Vietnam", "Turkey", "South Korea", "United States", "Lebanon", "Brazil",
            "Argentina", "Peru", "Morocco", "Egypt", "Ethiopia", "Indonesia",
            "Malaysia", "Germany", "United Kingdom", "Russia", "Portugal", "Hungary",
            "Canada", "Australia", "New Zealand", "South Africa", "Nigeria",
            "Sweden", "Poland", "Philippines", "Pakistan", "Iran", "Israel",
            "Jamaica", "Cuba"
        ]
        chosen_country = random.choice(countries)
        logging.info(f"Chosen country for today's food quiz: {chosen_country}")

        PROJECT_ID = "aetherchat-sm72i"
        vertexai.init(project=PROJECT_ID)
        db = firestore.client()
        gemini_model = GenerativeModel("gemini-2.5-flash")
        logging.info("Checkpoint 2: Clients initialized.")

        kiribati_tz = ZoneInfo("Pacific/Kiritimati")
        date_string = datetime.now(kiribati_tz).strftime('%Y-%m-%d')
        
        quiz_doc_ref = db.collection("quizzes").document(date_string)

        if quiz_doc_ref.get().exists:
            logging.warning(f"Quiz for {date_string} already exists. Skipping generation.")
            return

        logging.info("Checkpoint 3: Document does not exist. Proceeding to generate quiz.")
        
        # Change 3: Updated prompt to generate a quiz about the chosen country's food
        prompt = f"""
        As an assistant, you will generate a quiz about the cuisine of a specific country.
        Today's country is "{chosen_country}".

        Please generate a thought-provoking multiple-choice quiz question about "{chosen_country}"'s cuisine.
        Mixing in names of dishes from that country or neighboring countries will make the quiz more interesting.

        The response MUST be a single, valid JSON object that follows this strict format:
        {{
          "question": "string (The question text in English.)",
          "options": "array of 4 strings (The multiple choice options in English.)",
          "correctOptionIndex": "integer (0-3, the index of the correct answer in the options array.)",
          "explanation": "string (A brief explanation in English of why the answer is correct.)",
          "country": "{chosen_country}"
        }}
        Output ONLY the valid JSON object. DO NOT use markdown. DO NOT add any extra text before or after the JSON object.
        """
        logging.info("Checkpoint 4: Prompt created. Calling Gemini API...")

        response = gemini_model.generate_content(prompt)
        logging.info("Checkpoint 5: Gemini API call finished.")

        content = response.text
        if not content:
            logging.error("AI response content was empty. Stopping execution.")
            return

        logging.info(f"Checkpoint 6: AI response received, length: {len(content)}. Attempting to parse JSON.")
        
        quiz_data = json.loads(content)
        logging.info("Checkpoint 7: JSON parsing successful. Preparing to save to Firestore.")

        quiz_data['createdAt'] = firestore.SERVER_TIMESTAMP
        quiz_data['date'] = date_string
        
        quiz_doc_ref.set(quiz_data)
        logging.info(f"--- SUCCESS: Quiz for {date_string} ({chosen_country}) saved to Firestore! ---")

    except Exception as e:
        logging.error(f"CRITICAL ERROR in try block: {e}", exc_info=True)
