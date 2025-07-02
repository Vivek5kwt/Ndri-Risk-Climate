import 'package:cloud_firestore/cloud_firestore.dart';

class SurveySubmission {
  final String id;
  final String deviceToken;
  final String gender;
  final String name;

  final String village;
  final String block;
  final String district;
  final String state;

  final DateTime timestamp;
  final Map<String, dynamic> answers;

  SurveySubmission({
    required this.id,
    required this.deviceToken,
    required this.gender,
    required this.name,
    required this.village,
    required this.block,
    required this.district,
    required this.state,
    required this.timestamp,
    required this.answers,
  });

  factory SurveySubmission.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return SurveySubmission(
      id: documentId,
      deviceToken: data['deviceToken'] ?? '',
      gender: data['gender'] ?? '',
      name: data['name'] ?? '',
      village: data['village'] ?? '',
      block: data['block'] ?? '',
      district: data['district'] ?? '',
      state: data['state'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
    );
  }
}
