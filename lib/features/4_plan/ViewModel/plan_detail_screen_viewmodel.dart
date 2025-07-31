import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/features/4_plan/model/plan_model.dart'; // TravelStepモデルをインポート
import 'package:fyp_proj/features/4_plan/repository/repo.dart';

class PlanDetailViewmodel extends ChangeNotifier {
  final String _documentId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PlanRepo _repo = PlanRepo();


  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<TravelStep> _planSteps = [];
  List<TravelStep> get planSteps => _planSteps;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 1. コンストラクタでdocumentIdを受け取る
  PlanDetailViewmodel(this._documentId) {
    // 2. 初期化と同時にデータ取得を開始する
    fetchPlanDetails();
  }

  // 3. データ取得メソッドを実装
  Future<void> fetchPlanDetails() async {
    try {
      final docSnapshot = await _db
          .collection('travelRequests')
          .doc(userData.userId)
          .collection('plans')
          .doc(_documentId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> rawPlan = data['plan'] as List<dynamic>;
        
        _planSteps = rawPlan
            .map((stepData) => TravelStep.fromMap(stepData as Map<String, dynamic>))
            .toList();
        _errorMessage = null;
      } else {
        _errorMessage = "Plan not found.";
      }
    } catch (e) {
      _errorMessage = "Failed to load plan details: $e";
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners(); // UIに変更を通知
    }
  }

  Future<void> toggleStepCompletion(int stepIndex) async {
    if (stepIndex < 0 || stepIndex >= _planSteps.length) return;

    _planSteps[stepIndex].isCompleted = !_planSteps[stepIndex].isCompleted;
    notifyListeners();

    try {
      await _repo.updatePlan(_documentId, _planSteps);
    } catch (e) {
      // If the update fails, revert the change in the UI
      _planSteps[stepIndex].isCompleted = !_planSteps[stepIndex].isCompleted;
      _errorMessage = "Failed to update plan. Please try again.";
      notifyListeners();
    }
  }
}