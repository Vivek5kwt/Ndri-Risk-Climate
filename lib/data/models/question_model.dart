import '../../logic/risk_assessment/bloc/risk_assessment_state.dart';

class QuestionModel {
  final String variableNumber;
  final String questionText;
  final QuestionType? questionType;
  final String? category;

  QuestionModel({
    required this.variableNumber,
    required this.questionText,
    this.questionType,
    this.category,
  });
}
