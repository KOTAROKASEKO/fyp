# post_notifications.py

import logging
import firebase_admin
from firebase_admin import firestore, messaging
from firebase_functions import firestore_fn

# IMPORTANT: Do NOT initialize the app here. main.py handles that.

@firestore_fn.on_document_updated(document="posts/{postId}")
def send_like_notification(event: firestore_fn.Event[firestore_fn.Change]) -> None:
    """
    Triggers when a post document is updated. If a new user was added to the
    'likedBy' array, it sends a notification to the post's author.
    """
    db = firebase_admin.firestore.client()

    # Get the data before and after the change
    before_data = event.data.before.to_dict()
    after_data = event.data.after.to_dict()

    before_likes = set(before_data.get("likedBy", []))
    after_likes = set(after_data.get("likedBy", []))

    # Check if a new user was added to the likedBy array
    new_likers = after_likes - before_likes
    if not new_likers:
        logging.info(f"No new likes on post {event.params['postId']}. Exiting.")
        return

    liker_id = new_likers.pop()
    post_id = event.params["postId"]
    author_id = after_data.get("userId")

    logging.info(f"New like on post {post_id} by user {liker_id}")

    if not author_id or author_id == liker_id:
        logging.info("Author not found or user liked their own post. No notification sent.")
        return

    try:
        author_ref = db.collection("users_token").document(author_id)
        author_doc = author_ref.get()
        if not author_doc.exists:
            logging.error(f"Author {author_id} does not exist.")
            return
        fcm_token = author_doc.to_dict().get("fcmToken")
        if not fcm_token:
            logging.warning(f"Author {author_id} does not have an FCM token.")
            return
    except Exception as e:
        logging.error(f"Error getting author's FCM token: {e}")
        return

    # Get Liker's Username
    try:
        liker_ref = db.collection("users_token").document(liker_id)
        liker_doc = liker_ref.get()
        liker_username = liker_doc.to_dict().get("username", "Someone") if liker_doc.exists else "Someone"
    except Exception as e:
        logging.error(f"Error getting liker's username: {e}")
        liker_username = "Someone"

    # Construct and Send Notification
    message = messaging.Message(
        notification=messaging.Notification(
            title="New Like! ❤️",
            body=f"{liker_username} liked your post.",
        ),
        token=fcm_token,
        data={'postId': post_id, 'type': 'like'},
    )

    try:
        response = messaging.send(message)
        logging.info(f"Successfully sent 'like' notification: {response}")
    except Exception as e:
        logging.error(f"Error sending 'like' notification: {e}")