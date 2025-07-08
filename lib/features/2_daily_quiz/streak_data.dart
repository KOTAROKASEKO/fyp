import 'package:hive/hive.dart';

part 'streak_data.g.dart'; // IMPORTANT: This file must be regenerated

@HiveType(typeId: 0)
class StreakData extends HiveObject {
  @HiveField(0)
  final int currentStreak;

  @HiveField(1)
  final DateTime? lastStreakDate;

  @HiveField(2)
  final int totalPoints;

  StreakData({
    required this.currentStreak,
    this.lastStreakDate,
    required this.totalPoints, // Make it required in the constructor
  });

  // Factory constructor for a default/initial state
  factory StreakData.initial() {
    return StreakData(
      currentStreak: 0,
      lastStreakDate: null,
      totalPoints: 0, // Default to 0 points
    );
  }

  // Methods for Firestore serialization
  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'lastStreakDate': lastStreakDate?.toIso8601String(),
        'totalPoints': totalPoints, // Add to JSON
      };

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
        currentStreak: json['currentStreak'] ?? 0,
        lastStreakDate: json['lastStreakDate'] != null
            ? DateTime.parse(json['lastStreakDate'])
            : null,
        totalPoints: json['totalPoints'] ?? 0, // Parse from JSON
      );
}