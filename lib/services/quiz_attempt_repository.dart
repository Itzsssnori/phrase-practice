import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_attempt.dart';
import '../models/result.dart';

/// Abstract contract for recording and querying completed quiz session attempts.
abstract interface class QuizAttemptRepository {
  /// Saves a finished quiz attempt to the user's private subcollection:
  /// `users/{uid}/quizAttempts/{autoId}`
  Future<RepoResult<String>> saveAttempt(String uid, QuizAttempt attempt);

  /// Loads recent quiz attempts for [uid], ordered by `takenAt` descending.
  Future<RepoResult<List<QuizAttempt>>> getRecentAttempts(String uid, {int limit = 5});
}

/// Cloud Firestore implementation of [QuizAttemptRepository].
class FirestoreQuizAttemptRepository implements QuizAttemptRepository {
  final FirebaseFirestore? _customFirestore;

  FirestoreQuizAttemptRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RepoResult<String>> saveAttempt(String uid, QuizAttempt attempt) async {
    try {
      final db = _firestore;
      if (db == null) {
        return RepoResult.error(
          'Firestore is not available in this environment.',
          'firestore-unavailable',
        );
      }

      final docRef = db
          .collection('users')
          .doc(uid)
          .collection('quizAttempts')
          .doc();

      // Write ONLY these fields matching security rules:
      // targetLanguageCode, categoryId (null for all categories), score, total,
      // takenAt (server timestamp), answers (list of maps with phraseId and wasCorrect).
      final payload = <String, dynamic>{
        'targetLanguageCode': attempt.targetLanguageCode,
        'categoryId': attempt.categoryId,
        'score': attempt.score,
        'total': attempt.total,
        'takenAt': FieldValue.serverTimestamp(),
        'answers': attempt.answers.map((a) => a.toMap()).toList(),
      };

      await docRef.set(payload);
      return RepoResult.success(docRef.id);
    } catch (e) {
      return RepoResult.error(
        'Could not save quiz attempt: $e',
        'save-attempt-failed',
      );
    }
  }

  @override
  Future<RepoResult<List<QuizAttempt>>> getRecentAttempts(String uid, {int limit = 5}) async {
    try {
      final db = _firestore;
      if (db == null) {
        return RepoResult.error(
          'Firestore is not available in this environment.',
          'firestore-unavailable',
        );
      }

      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('quizAttempts')
          .orderBy('takenAt', descending: true)
          .limit(limit)
          .get();

      final attempts = snapshot.docs.map((doc) {
        return QuizAttempt.fromMap(doc.id, doc.data());
      }).toList();

      return RepoResult.success(attempts);
    } catch (e) {
      return RepoResult.error(
        'Could not load recent quizzes: $e',
        'load-attempts-failed',
      );
    }
  }
}
