class Flashcard {
  final String question;
  final String answer;

  const Flashcard({
    required this.question,
    required this.answer,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
  };
}
