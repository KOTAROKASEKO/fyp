// lib/models/quiz_model.dart

class Quiz {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation; // NEW: Add explanation field

  Quiz({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation, // NEW: Add to constructor
  });

  factory Quiz.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Quiz(
      id: documentId,
      question: data['question'] ?? 'No question',
      options: List<String>.from(data['options'] ?? []),
      correctAnswerIndex: data['correctAnswerIndex'] ?? 0,
      explanation: data['explanation'] ?? 'No explanation available.', // NEW: Parse from Firestore
    );
  }
}