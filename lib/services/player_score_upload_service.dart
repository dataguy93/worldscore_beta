import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlayerScoreUploadService {
  PlayerScoreUploadService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> uploadMeScore({
    required String playerName,
    required Map<int, int?> scoresByHole,
    required String courseName,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('No authenticated user found for score upload.');
    }

    final uploadedAt = FieldValue.serverTimestamp();
    final totalScore = scoresByHole.values.fold<int>(
      0,
      (total, score) => total + (score ?? 0),
    );
    final sanitizedScoresByHole = <String, int?>{
      for (final entry in scoresByHole.entries) '${entry.key}': entry.value,
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('scorecards')
        .add({
          'userId': userId,
          'playerName': playerName,
          'courseName': courseName,
          'scoresByHole': sanitizedScoresByHole,
          'totalScore': totalScore,
          'uploadedAt': uploadedAt,
          'source': 'ocr_upload_me_toggle',
        });
  }
}
