import 'package:cloud_firestore/cloud_firestore.dart';

class TravelStep {
  final String time;
  final String placeName;
  final String activityDescription;
  final String placeId;
  final GeoPoint location;
  final String? photoReference; // To store the photo reference from Google Places API
  bool isCompleted;

  TravelStep({
    required this.time,
    required this.placeName,
    required this.activityDescription,
    required this.placeId,
    required this.location,
    this.photoReference,
    this.isCompleted = false,
  });

  factory TravelStep.fromMap(Map<String, dynamic> map) {
    final geo = map['geometry'] as Map<String, dynamic>?;
    
    return TravelStep(
      time: map['time'] ?? 'N/A',
      placeName: map['place_name'] ?? 'Unknown Place',
      activityDescription: map['activity_description'] ?? 'No description.',
      placeId: map['place_id'] ?? '',
      photoReference: map['photo_reference'], // Get the photo reference
      location: (geo != null && geo['lat'] != null && geo['lng'] != null)
          ? GeoPoint(geo['lat'], geo['lng'])
          : const GeoPoint(35.681236, 139.767125),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'place_name': placeName,
      'activity_description': activityDescription,
      'place_id': placeId,
      'photo_reference': photoReference, // Add photo reference to map
      'geometry': {
        'lat': location.latitude,
        'lng': location.longitude,
      },
      'isCompleted': isCompleted,
    };
  }
}