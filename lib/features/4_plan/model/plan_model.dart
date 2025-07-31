import 'package:cloud_firestore/cloud_firestore.dart';

class TravelStep {
  final String time;
  final String placeName;
  final String activityDescription;
  final String placeId;
  final GeoPoint location; // 座標をGeoPointとして保持
  bool isCompleted; // To track completion status

  TravelStep({
    required this.time,
    required this.placeName,
    required this.activityDescription,
    required this.placeId,
    required this.location,
    this.isCompleted = false, // Default to not completed
  });

  // FirestoreのMapからTravelStepオブジェクトを生成するファクトリコンストラクタ
  factory TravelStep.fromMap(Map<String, dynamic> map) {
    // Firestoreから受け取るgeometryはMap<String, dynamic>型
    final geo = map['geometry'] as Map<String, dynamic>?;
    
    return TravelStep(
      time: map['time'] ?? 'N/A',
      placeName: map['place_name'] ?? 'Unknown Place',
      activityDescription: map['activity_description'] ?? 'No description.',
      // place_idも必ず取得する
      placeId: map['place_id'] ?? '', 
      // MapからGeoPointに変換。データがない場合はデフォルト値（東京駅）を設定
      location: (geo != null && geo['lat'] != null && geo['lng'] != null)
          ? GeoPoint(geo['lat'], geo['lng'])
          : const GeoPoint(35.681236, 139.767125),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
  
  // Method to convert TravelStep to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'place_name': placeName,
      'activity_description': activityDescription,
      'place_id': placeId,
      'geometry': {
        'lat': location.latitude,
        'lng': location.longitude,
      },
      'isCompleted': isCompleted,
    };
  }
}