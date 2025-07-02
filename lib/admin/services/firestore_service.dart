import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/survey_submission.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<SurveySubmission>> getAllSurveySubmissions() {
    return _db
        .collection('surveySubmissions')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SurveySubmission.fromFirestore(
          doc.data(),
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> deleteSubmission(String docId) async {
    await _db.collection('surveySubmissions').doc(docId).delete();
  }
}
