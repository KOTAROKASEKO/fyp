
import 'package:flutter/foundation.dart';
import 'package:fyp_proj/features/4_plan/model/thumbnail.dart';
import 'package:fyp_proj/features/4_plan/repository/repo.dart';

class PlanScreenViewModel extends ChangeNotifier{

  Stream<List<TravelThumbnail>> get travelPlansStream => _repo.getTravelPlansStream();


  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _hasData = false;
  bool get hasData => _hasData;

  List<TravelThumbnail> _thumbnail = [];
  List<TravelThumbnail> get thumbnail => _thumbnail;

  PlanRepo _repo = PlanRepo();

  PlanScreenViewModel() {
    hasTravelPlans();
  }

  // In lib/features/4_plan/ViewModel/plan_screen_viewmodel.dart

  Future<void> deletePlan(String documentId) async {
    try {
      await _repo.deletePlan(documentId);
      
      // Remove the plan from the local list for an immediate UI update.
      _thumbnail.removeWhere((plan) => plan.documentId == documentId);
      
      // If the list becomes empty after deletion, update the hasData flag.
      if (_thumbnail.isEmpty) {
        _hasData = false;
      }

      notifyListeners();
    } catch (e) {
      print("Failed to delete plan from ViewModel: $e");
      // Optionally, implement error-handling state to show a SnackBar.
    }
  }

  
  Future<void> hasTravelPlans() async {
    _thumbnail = await _repo.hasTravelPlans();

    if (_thumbnail.isNotEmpty) {
      print('--- SUCCESS: Travel plans found ---');
      _hasData = true;
    } else {
      print('--- INFO: No travel plans found ---');
      _hasData = false;
    }

    _isLoading = false;

    notifyListeners();
  }
}