import 'package:hive/hive.dart';

part 'quiz_generation_model.g.dart'; // This line will be generated

@HiveType(typeId: 2) // Assign a unique typeId
class GeneratedQuiz extends HiveObject {
  @HiveField(0)
  final String question;

  @HiveField(1)
  final List<String> options;

  @HiveField(2)
  final int correctOptionIndex;

  @HiveField(3)
  final String explanation;

  GeneratedQuiz({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  // The fromJson factory remains unchanged
  factory GeneratedQuiz.fromJson(Map<String, dynamic> json) {
    return GeneratedQuiz(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List<dynamic>),
      correctOptionIndex: json['correct_option_index'] as int,
      explanation: json['explanation'] as String,
    );
  }
}