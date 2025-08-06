import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';

class GeneratingViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> createTravelRequest({
    required String city,
    required String budget,
    required String request,
    required String fcmToken, // Add fcmToken parameter
  }) async {
    try {
      print('--- Creating travel request in Firestore... ---');

      final docRef = await _db.collection('travelRequests').doc(userData.userId).collection('plans').add({
        'city': city,
        'budget': budget,
        'request': request,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'fcmToken': fcmToken, // Save the token to the document
      });

      print('--- SUCCESS: Created document with ID: ${docRef.id} ---');
      return docRef.id;

    } catch (e) {
      print('--- CRITICAL ERROR: Failed to create travel request ---');
      print(e);
      return null;
    }
  }
}