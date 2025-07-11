import logging
import json
import random
from datetime import datetime
from zoneinfo import ZoneInfo

# 統合されたFirebaseとGoogle Cloudのインポート
import firebase_admin
from firebase_admin import firestore
from firebase_functions import firestore_fn, scheduler_fn, options
from google.cloud import vision
import vertexai
from vertexai.generative_models import GenerativeModel

firebase_admin.initialize_app()
options.set_global_options(
    region="asia-southeast1",
    memory=options.MemoryOption.GB_1,
)

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
            "Japan", "Italy", "China", "Mexico", "India", "France", "Spain",
            "Greece", "Vietnam", "Turkey", "South Korea", "United States", "Brazil",
            "Argentina", "Peru", "Morocco","Indonesia",
            "Malaysia", "Germany", "United Kingdom", "Russia", "Portugal", "Hungary",
            "Canada", "Australia", "New Zealand",
            "Sweden", "Philippines"
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


@firestore_fn.on_document_created(document="posts/{postId}")
def autoTagPost(event: firestore_fn.Event[firestore.DocumentSnapshot]) -> None:
    """
    Analyzes a list of images from a new post, aggregates all relevant tags,
    and updates the document with a unique list of tags.
    """
    if event.data is None:
        logging.warning("Document data does not exist. Skipping processing.")
        return

    post_ref = event.data.reference
    post_data = event.data.to_dict()
    
    # MODIFIED: Get the list of URLs, not a single URL.
    image_urls = post_data.get("imageUrls") 
    
    # VALIDATION: Ensure imageUrls is a non-empty list.
    if not isinstance(image_urls, list) or not image_urls:
        logging.info(f"Post {post_ref.id} has no valid list of imageUrls. Skipping.")
        return

    logging.info(f"Analyzing {len(image_urls)} image(s) for post {post_ref.id}.")
    
    aggregated_tags = set()

    try:
        # LAZY INITIALIZATION: Initialize the client inside the function.
        client = vision.ImageAnnotatorClient()

        # LOOP: Analyze each image URL from the list.
        for url in image_urls:
            if not url: # Skip empty URL strings
                continue
            
            logging.info(f"Processing URL: {url}")
            image = vision.Image(source=vision.ImageSource(image_uri=url))
            response = client.label_detection(image=image)
            labels = response.label_annotations

            # Add high-confidence labels to the set.
            for label in labels:
                if label.score > 0.75:
                    aggregated_tags.add(label.description.lower())

        # WRITE ONCE: After analyzing all images, update Firestore a single time.
        if aggregated_tags:
            # Convert the set to a list for Firestore.
            final_tags = list(aggregated_tags)
            logging.info(f"Aggregated unique tags: {', '.join(final_tags)}")
            post_ref.update({"AutoTags": final_tags})
        else:
            logging.info("No tags above the confidence threshold were found in any image.")

    except Exception as e:
        logging.error(f"Error occurred during image processing for post {post_ref.id}: {e}", exc_info=True)

def _update_user_preferences(user_id: str, post_tags: list, weight: int):
    """
    Updates a user's preference scores based on post tags.

    Args:
        user_id (str): The ID of the user to update.
        post_tags (list): A list of tags from the post.
        weight (int): The value to increment the score by (e.g., 1 for a like, -1 for an unlike).
    """
    if not user_id or not isinstance(post_tags, list) or not post_tags:
        logging.warning("Invalid input for preference update. Skipping.")
        return

    db = firestore.client()
    
    # 1. Fetch the master taxonomy list to categorize tags.
    # ASSUMPTION: Your taxonomies are stored in a single document named 'master_list'.
    # If your document has a different name (like 'id' from your screenshot), change it here.
    try:
        taxonomy_ref = db.collection("taxonomies").document("master_list")
        taxonomies_doc = taxonomy_ref.get()
        if not taxonomies_doc.exists:
            logging.error("Taxonomy document 'master_list' not found. Cannot categorize tags.")
            return
        taxonomies = taxonomies_doc.to_dict()
    except Exception as e:
        logging.error(f"Failed to fetch taxonomies: {e}", exc_info=True)
        return
        
    user_ref = db.collection("users").document(user_id)
    lower_case_post_tags = {tag.lower() for tag in post_tags}
    update_payload = {}
    
    # 2. Match post tags against each taxonomy category.
    for category, valid_tags in taxonomies.items():
        if isinstance(valid_tags, list):
            # Find the intersection between the post's tags and the category's valid tags.
            matched_tags = lower_case_post_tags.intersection({t.lower() for t in valid_tags})
            for tag in matched_tags:
                # 3. Build the update payload using dot notation for nested fields.
                # This will atomically increment the score for 'preferences.activities.beach', for example.
                field_path = f"preferences.{category}.{tag}"
                update_payload[field_path] = firestore.FieldValue.increment(weight)
    
    # 4. Atomically update the user's document if any matches were found.
    if update_payload:
        logging.info(f"Updating preferences for user {user_id} with weight {weight}. Payload: {update_payload}")
        user_ref.update(update_payload)
    else:
        logging.info(f"No tags from post matched any taxonomy for user {user_id}.")


# --- Trigger 1: Handling Likes and Unlikes ---

@firestore_fn.on_document_updated(document="posts/{postId}")
def onPostInteraction(event: firestore_fn.Event[firestore_fn.Change]) -> None:
    """
    Triggers on post updates to detect new likes or unlikes.
    """
    before_data = event.data.before.to_dict() if event.data.before else {}
    after_data = event.data.after.to_dict() if event.data.after else {}

    # Ensure 'likedBy' and 'AutoTags' fields exist
    if "likedBy" not in after_data or "AutoTags" not in after_data:
        logging.info("Update was not related to 'likedBy' or 'AutoTags' are missing. Skipping.")
        return

    post_tags = after_data.get("AutoTags", [])
    before_likers = set(before_data.get("likedBy", []))
    after_likers = set(after_data.get("likedBy", []))

    # Case 1: Detect a new "like" (a user was added)
    new_likers = after_likers - before_likers
    if new_likers:
        liker_id = new_likers.pop()
        logging.info(f"User {liker_id} liked post {event.params['postId']}.")
        _update_user_preferences(liker_id, post_tags, weight=1)
        return

    # Case 2: Detect an "unlike" (a user was removed)
    unlikers = before_likers - after_likers
    if unlikers:
        unliker_id = unlikers.pop()
        logging.info(f"User {unliker_id} unliked post {event.params['postId']}.")
        _update_user_preferences(unliker_id, post_tags, weight=-1)
        return


@firestore_fn.on_document_created(document="users/{userId}/savedPosts/{postId}")
def onPostSaved(event: firestore_fn.Event[firestore.DocumentSnapshot]) -> None:
    """
    Triggers when a user saves a post.
    """
    user_id = event.params["userId"]
    post_id = event.params["postId"]
    logging.info(f"User {user_id} saved post {post_id}.")

    db = firestore.client()
    post_ref = db.collection("posts").document(post_id)
    post_doc = post_ref.get()

    if not post_doc.exists:
        logging.error(f"Post document {post_id} not found, cannot update preferences.")
        return
        
    post_tags = post_doc.to_dict().get("AutoTags", [])
    _update_user_preferences(user_id, post_tags, weight=1)


@firestore_fn.on_document_deleted(document="users/{userId}/savedPosts/{postId}")
def onPostUnsaved(event: firestore_fn.Event[firestore.DocumentSnapshot]) -> None:
    """
    Triggers when a user unsaves a post (deletes the saved document).
    """
    user_id = event.params["userId"]
    post_id = event.params["postId"]
    logging.info(f"User {user_id} unsaved post {post_id}.")

    db = firestore.client()
    post_ref = db.collection("posts").document(post_id)
    post_doc = post_ref.get()

    if not post_doc.exists:
        # The post might be deleted, but we should still try to lower the score.
        # We can get the tags from the deleted 'savedPost' document if we store them there.
        # For now, we'll assume the original post still exists.
        logging.warning(f"Post document {post_id} not found, cannot update preferences.")
        return
        
    post_tags = post_doc.to_dict().get("AutoTags", [])
    _update_user_preferences(user_id, post_tags, weight=-1)

