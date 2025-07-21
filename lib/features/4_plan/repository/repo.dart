import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/features/4_plan/model/plan_model.dart';
import 'package:fyp_proj/features/4_plan/model/thumbnail.dart';

class PlanRepo{

FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<TravelThumbnail>> hasTravelPlans() async {

    
    var snapshot = await _firestore.collection('travelRequests').doc(userData.userId).collection('plans').get();
    List<TravelThumbnail> travelPlans = [];
    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        var data = doc.data();
        travelPlans.add(TravelThumbnail.fromMap(data, doc.id));
      }
    }
    return travelPlans;
  }

  Future<List<TravelStep>> getTravelPlan(String documentId) async {
    try {
      var snapshot = await _firestore
          .collection('travelRequests')
          .doc(userData.userId)
          .collection('plans')
          .doc(documentId)
          .get();

      List<TravelStep> destinations = [];
      if (snapshot.exists) {
        var data = snapshot.data()?['plan'];
        if (data is List) {
          for (var stepData in data) {
            if (stepData is Map<String, dynamic>) {
              destinations.add(TravelStep.fromMap(stepData));
            }
          }
        }
      } else {
        throw Exception("Plan not found");
      }
      return destinations;
    } catch (error) {
      throw Exception("Error fetching plan: $error");
    }
  }
}
