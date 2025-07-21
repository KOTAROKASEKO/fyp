# dailyquiz.py

# Keep only the imports needed for THIS function's logic
import logging
import json
import random
from datetime import datetime
from zoneinfo import ZoneInfo

from firebase_admin import firestore
from firebase_functions import scheduler_fn
from vertexai.generative_models import GenerativeModel
import vertexai # Keep this import

# The function definition remains the same, but it will now rely on the
# initialization performed in main.py
@scheduler_fn.on_schedule(schedule="every day 00:05", timezone="Pacific/Kiritimati")
def generate_daily_quiz(event: scheduler_fn.ScheduledEvent) -> None:
    """
    A scheduled function to generate a daily quiz about a random country's food.
    """
    logging.info("--- Daily Quiz Function execution started. ---")
    
    try: 
        countries = [
            "Japan", "Italy", "China", "Mexico", "India", "France", "Spain",
            "Greece", "Vietnam", "Turkey", "South Korea", "United States", "Brazil",
            "Argentina", "Peru", "Morocco","Indonesia",
            "Malaysia", "Germany", "United Kingdom", "Russia", "Portugal", "Hungary",
            "Canada", "Australia", "New Zealand",
            "Sweden", "Philippines"
        ]
        chosen_country = random.choice(countries)
        logging.info(f"Chosen country for today's food quiz: {chosen_country}")

        # The clients are already initialized in main.py, so we just get a reference
        db = firestore.client()
        gemini_model = GenerativeModel("gemini-2.5-flash")

        kiribati_tz = ZoneInfo("Pacific/Kiritimati")
        date_string = datetime.now(kiribati_tz).strftime('%Y-%m-%d')
        
        quiz_doc_ref = db.collection("quizzes").document(date_string)

        if quiz_doc_ref.get().exists:
            logging.warning(f"Quiz for {date_string} already exists. Skipping generation.")
            return

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
        
        response = gemini_model.generate_content(prompt)
        content = response.text

        if not content:
            logging.error("AI response content was empty. Stopping execution.")
            return
            
        quiz_data = json.loads(content)
        quiz_data['createdAt'] = firestore.SERVER_TIMESTAMP
        quiz_data['date'] = date_string
        
        quiz_doc_ref.set(quiz_data)
        logging.info(f"--- SUCCESS: Quiz for {date_string} ({chosen_country}) saved to Firestore! ---")

    except Exception as e:
        logging.error(f"CRITICAL ERROR in generate_daily_quiz: {e}", exc_info=True)