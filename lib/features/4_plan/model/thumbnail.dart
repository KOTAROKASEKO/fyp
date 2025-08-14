
import 'package:cloud_firestore/cloud_firestore.dart';

class TravelThumbnail {
  String city;
  DateTime createdAt;
  String documentId;
  String status;
  String? thumbnailPhotoReference;

  TravelThumbnail({
    required this.city,
    required this.createdAt,
    required this.documentId,
    required this.status,
    this.thumbnailPhotoReference,
  });

  factory TravelThumbnail.fromMap(Map<String, dynamic> data, String documentId) {
    return TravelThumbnail(
      city: data['city'] ?? 'Unknown City',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      documentId: documentId,
      status: data['status'] ?? 'unknown',
      thumbnailPhotoReference: data['thumbnail_photo_reference'],
    );
  }
}