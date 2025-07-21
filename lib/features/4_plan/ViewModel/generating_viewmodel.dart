

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';

class GeneratingViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Creates a travel request document in Firestore.
  ///
  /// This function takes the user's input, creates a document in the 'travelRequests'
  /// collection, and returns the ID of the newly created document.
  /// Returning the ID is crucial for the app to listen for the plan's completion.
  /// Returns `null` if the operation fails.
  Future<String?> createTravelRequest({
    required String city,
    required String budget,
    required String request,
    // You should also pass the user's ID
    // required String userId, 
  }) async {
    try {
      print('--- Creating travel request in Firestore... ---');
      
      // The data structure here MUST match what your Cloud Function expects.
      final docRef = await _db.collection('travelRequests').doc(userData.userId).collection('plans').add({
        'city': city,
        'budget': budget,
        'request': request,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
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