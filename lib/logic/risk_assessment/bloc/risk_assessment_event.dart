import 'package:equatable/equatable.dart';
import '../../../config/card_option.dart';

abstract class RiskAssessmentEvent extends Equatable {
  const RiskAssessmentEvent();
  @override
  List<Object?> get props => [];
}

class LoadQuestionsEvent extends RiskAssessmentEvent {}

class SaveBasicInfoEvent extends RiskAssessmentEvent {
  final String name;
  final String gender;
  final String stateName;
  final String district;
  final String block;
  final String village;

  const SaveBasicInfoEvent({
    required this.name,
    required this.gender,
    required this.stateName,
    required this.district,
    required this.block,
    required this.village,
  });

  @override
  List<Object?> get props =>
      [name, gender, stateName, district, block, village];
}

class SetAssessmentTypeEvent extends RiskAssessmentEvent {
  final CardOption type;
  const SetAssessmentTypeEvent(this.type);

  @override
  List<Object?> get props => [type];
}

class SaveAnswerEvent extends RiskAssessmentEvent {
  final String  questionNumber;
  final String answer;
  const SaveAnswerEvent(this.questionNumber, this.answer);

  @override
  List<Object?> get props => [questionNumber, answer];
}

class SubmitAnswersEvent extends RiskAssessmentEvent {}
