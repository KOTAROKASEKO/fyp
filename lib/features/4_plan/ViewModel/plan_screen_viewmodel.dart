
import 'package:flutter/foundation.dart';
import 'package:fyp_proj/features/4_plan/model/thumbnail.dart';
import 'package:fyp_proj/features/4_plan/repository/repo.dart';

class PlanScreenViewModel extends ChangeNotifier{

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