import logging
import json
from datetime import datetime, timezone

from firebase_admin import initialize_app, firestore
from firebase_functions import scheduler_fn, options

import vertexai
from vertexai.generative_models import GenerativeModel

initialize_app()

options.set_global_options(
    region="asia-southeast1",
    memory=options.MemoryOption.MB_512,
)

@scheduler_fn.on_schedule(schedule="every day 00:05", timezone="UTC")
def generate_daily_quiz(event: scheduler_fn.ScheduledEvent) -> None:
    """
    A scheduled function to generate a daily quiz using AI and save it to Firestore.
    """
    logging.info("--- Function execution started. ---") # チェックポイント1
    
    try:
        # Lazy Initialization
        PROJECT_ID = "aetherchat-sm72i"
        vertexai.init(project=PROJECT_ID)
        db = firestore.client()
        gemini_model = GenerativeModel("gemini-2.0-flash-001")
        logging.info("Checkpoint 2: Clients initialized.")

        date_string = datetime.now(timezone.utc).strftime('%Y-%m-%d')
        quiz_doc_ref = db.collection("quizzes").document(date_string)

        if quiz_doc_ref.get().exists:
            logging.warning(f"Quiz for {date_string} already exists. Skipping generation.")
            return

        logging.info("Checkpoint 3: Document does not exist. Proceeding to generate quiz.")
        
        prompt = """
        Generate a single multiple-choice quiz question about personal productivity.
        Provide the response in a valid JSON format only.
        Example: {"question": "Q text", "options": ["A", "B", "C", "D"], "correctOptionIndex": 0, "explanation": "Expl text"}
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
        logging.info("Quiz Data: %s", quiz_data)

        quiz_data['createdAt'] = firestore.SERVER_TIMESTAMP
        quiz_data['date'] = date_string
        
        quiz_doc_ref.set(quiz_data)
        logging.info("--- SUCCESS: Quiz saved to Firestore! ---")

    except Exception as e:
        # exc_info=True を追加して、より詳細なエラー情報をログに出力する
        logging.error(f"CRITICAL ERROR in try block: {e}", exc_info=True)