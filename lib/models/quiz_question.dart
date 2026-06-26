class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String fullVerse;
  final String reference;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.fullVerse,
    required this.reference,
  });
}
