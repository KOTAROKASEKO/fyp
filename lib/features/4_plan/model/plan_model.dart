// Create a new file, e.g., 'lib/features/4_plan/model/travel_step.dart'

class TravelStep {
  final String time;
  final String placeName;
  final String activityDescription;

  TravelStep({
    required this.time,
    required this.placeName,
    required this.activityDescription, 
  });

  // A factory constructor to create an instance from a Firestore Map
  factory TravelStep.fromMap(Map<String, dynamic> map) {
    return TravelStep(
      time: map['time'] as String,
      placeName: map['place_name'] as String,
      activityDescription: map['activity_description'] as String, 
          );
  }
}

