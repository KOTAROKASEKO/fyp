// lib/models/quiz_model.dart

class Quiz {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final List<int> answerDistribution; // NEW: To store vote counts for each option

  Quiz({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.answerDistribution, // NEW: Add to constructor
  });

  factory Quiz.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Quiz(
      id: documentId,
      question: data['question'] ?? 'No question',
      options: List<String>.from(data['options'] ?? []),
      correctAnswerIndex: data['correctAnswerIndex'] ?? 0,
      explanation: data['explanation'] ?? 'No explanation available.',
      // NEW: Parse from Firestore, defaulting to an empty list if not present
      answerDistribution: List<int>.from(data['answerDistribution'] ?? List.generate(data['options']?.length ?? 0, (_) => 0)),
    );
  }

  // Calculate the total number of votes.
  int get totalVotes => answerDistribution.fold(0, (sum, item) => sum + item);
}