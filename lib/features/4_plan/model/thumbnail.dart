
import 'package:cloud_firestore/cloud_firestore.dart';

class TravelThumbnail {
  String city;
  DateTime createdAt;
  String documentId;
  String status;

  TravelThumbnail({
    required this.city,
    required this.createdAt,
    required this.documentId,
    required this.status,
  });

  factory TravelThumbnail.fromMap(Map<String, dynamic> data, String documentId) {
    return TravelThumbnail(
      city: data['city'] ?? 'Unknown City',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      documentId: documentId,
      status: data['status'] ?? 'unknown',
    );
  }
}