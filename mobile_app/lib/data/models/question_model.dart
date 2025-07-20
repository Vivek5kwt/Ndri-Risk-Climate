class QuestionModel {
  final String variableNumber;
  final String questionText;
  final double finalValue;

  QuestionModel({
    required this.variableNumber,
    required this.questionText,
    required this.finalValue,
  });

  /// Accepted value for the question. If [finalValue] is negative,
  /// this returns `0`, otherwise it returns [finalValue].
  double get acceptedValue => finalValue < 0 ? 0 : finalValue;
}
