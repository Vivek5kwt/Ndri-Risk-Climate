import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../config/card_option.dart';
import '../../../data/repositories/question_repository.dart';
import 'risk_assessment_event.dart';
import 'risk_assessment_state.dart';

class RiskAssessmentBloc extends Bloc<RiskAssessmentEvent, RiskAssessmentState> {
  RiskAssessmentBloc() : super(const RiskAssessmentState()) {
    /* ───── Load questions once ───── */
    on<LoadQuestionsEvent>((event, emit) {
      final qs = QuestionRepository.getQuestions();
      emit(RiskAssessmentLoaded(questions: qs));
    });

    on<SaveBasicInfoEvent>((event, emit) {
      final updatedAnswers = Map<String, String>.from(state.answers)
        ..['1'] = event.name.trim();

      emit(
        RiskAssessmentLoaded(
          questions: state.questions.isNotEmpty
              ? state.questions
              : QuestionRepository.getQuestions(),
          answers: updatedAnswers,
          name: event.name.trim(),
          gender: event.gender,
          stateName: event.stateName,
          district: event.district,
          block: event.block.trim(),
          village: event.village.trim(),
          option: state.option,
          submitted: state.submitted,
        ),
      );
    });

    /* ───── User toggles assessment type card ───── */
    on<SetAssessmentTypeEvent>((event, emit) {
      emit(
        RiskAssessmentLoaded(
          questions: state.questions,
          answers: state.answers,
          name: state.name,
          gender: state.gender,
          stateName: state.stateName,
          district: state.district,
          block: state.block,
          village: state.village,
          option: event.type,
          submitted: state.submitted,
        ),
      );
    });

    /* ───── Save/overwrite a single answer ───── */
    on<SaveAnswerEvent>((event, emit) {
      final updatedAnswers = Map<String, String>.from(state.answers)
        ..[event.questionNumber.toString()] = event.answer;

      emit(
        RiskAssessmentLoaded(
          questions: state.questions,
          answers: updatedAnswers,
          name: state.name,
          gender: event.questionNumber == 2 ? event.answer : state.gender,
          stateName: state.stateName,
          district: state.district,
          block: state.block,
          village: state.village,
          option: state.option,
          submitted: state.submitted,
        ),
      );
    });

    /* ───── Submit all answers to Firestore ───── */
    on<SubmitAnswersEvent>((event, emit) async {
      try {
        final String? token = await FirebaseMessaging.instance.getToken();
        if (token == null) {
          emit(
            RiskAssessmentLoaded(
              questions: state.questions,
              answers: state.answers,
              name: state.name,
              gender: state.gender,
              stateName: state.stateName,
              district: state.district,
              block: state.block,
              village: state.village,
              option: state.option,
              submitted: true,
            ),
          );
          return;
        }

        /* If there’s a previous submission, merge with it */
        final docRef = FirebaseFirestore.instance
            .collection('surveySubmissions')
            .doc(token);
        final snap = await docRef.get();
        Map<String, dynamic> accumulated = {};
        if (snap.exists &&
            snap.data() != null &&
            snap.data()!.containsKey('answers')) {
          accumulated =
          Map<String, dynamic>.from(snap.data()!['answers'] as Map);
        }

        final type = state.option == CardOption.exposure
            ? 'exposure'
            : 'vulnerability';

        /* Merge current answers into the correct section */
        accumulated[type] = {
          ...?accumulated[type],
          ...state.answers.map((k, v) => MapEntry(k.toString(), v)),
        };

        /* Build full Firestore payload */
        final payload = {
          'name': state.name,
          'gender': state.gender,
          'state': state.stateName,
          'district': state.district,
          'block': state.block,
          'village': state.village,
          'deviceToken': token,
          'timestamp': FieldValue.serverTimestamp(),
          'answers': accumulated,
        };

        await docRef.set(payload, SetOptions(merge: true));
      } catch (_) {
      }

      emit(
        RiskAssessmentLoaded(
          questions: state.questions,
          answers: state.answers,
          name: state.name,
          gender: state.gender,
          stateName: state.stateName,
          district: state.district,
          block: state.block,
          village: state.village,
          option: state.option,
          submitted: true,
        ),
      );
    });
  }
}
