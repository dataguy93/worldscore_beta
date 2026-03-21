import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PlayerScoreUploadService {
  PlayerScoreUploadService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  Future<void> uploadMeScore({
    required String playerName,
    required Map<int, int?> scoresByHole,
    required String courseName,
    required List<int> scorecardImageBytes,
    required String originalFileName,
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
    final storagePath = 'users/$userId/scorecards/${DateTime.now().millisecondsSinceEpoch}_$originalFileName';
    final storageRef = _storage.ref().child(storagePath);
    await storageRef.putData(Uint8List.fromList(scorecardImageBytes));
    final scorecardImageUrl = await storageRef.getDownloadURL();

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
          'source': 'ocr_upload_confirm',
          'scorecardImagePath': storagePath,
          'scorecardImageUrl': scorecardImageUrl,
        });
  }
}
