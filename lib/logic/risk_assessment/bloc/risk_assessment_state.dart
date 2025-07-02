import 'package:equatable/equatable.dart';
import '../../../config/card_option.dart';
import '../../../data/models/question_model.dart';

class RiskAssessmentState extends Equatable {
  final List<QuestionModel> questions;
  final Map<String, String> answers;
  final bool submitted;

  final String name;
  final String gender;
  final String stateName;
  final String district;
  final String block;
  final String village;

  final CardOption? option;

  const RiskAssessmentState({
    this.questions = const [],
    this.answers = const {},
    this.submitted = false,
    this.name = '',
    this.gender = '',
    this.stateName = '',
    this.district = '',
    this.block = '',
    this.village = '',
    this.option,
  });

  RiskAssessmentState copyWith({
    List<QuestionModel>? questions,
    Map<String, String>? answers,
    bool? submitted,
    String? name,
    String? gender,
    String? stateName,
    String? district,
    String? block,
    String? village,
    CardOption? option,
  }) =>
      RiskAssessmentState(
        questions: questions ?? this.questions,
        answers: answers ?? this.answers,
        submitted: submitted ?? this.submitted,
        name: name ?? this.name,
        gender: gender ?? this.gender,
        stateName: stateName ?? this.stateName,
        district: district ?? this.district,
        block: block ?? this.block,
        village: village ?? this.village,
        option: option ?? this.option,
      );

  @override
  List<Object?> get props =>
      [
        questions,
        answers,
        submitted,
        name,
        gender,
        stateName,
        district,
        block,
        village,
        option,
      ];
}

class RiskAssessmentLoaded extends RiskAssessmentState {
  const RiskAssessmentLoaded({
    required List<QuestionModel> questions,
    Map<String, String> answers = const {},
    bool submitted = false,
    String name = '',
    String gender = '',
    String stateName = '',
    String district = '',
    String block = '',
    String village = '',
    CardOption? option,
  }) : super(
    questions: questions,
    answers: answers,
    submitted: submitted,
    name: name,
    gender: gender,
    stateName: stateName,
    district: district,
    block: block,
    village: village,
    option: option,
  );
}

enum QuestionType { general, vulnerability, exposure }
