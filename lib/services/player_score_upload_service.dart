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

  Future<void> uploadTournamentRegistrationScore({
    required String tournamentId,
    required int round,
    required String playerName,
    required Map<int, int?> scoresByHole,
    required String courseName,
  }) async {
    final registrationQuery = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('registrations')
        .where('playerName', isEqualTo: playerName)
        .where('status', isEqualTo: 'registered')
        .limit(2)
        .get();

    if (registrationQuery.docs.isEmpty) {
      throw StateError('No registered player found for "$playerName" in this tournament.');
    }

    if (registrationQuery.docs.length > 1) {
      throw StateError(
        'Multiple registrations were found for "$playerName". Use a unique player name.',
      );
    }

    final registrationDoc = registrationQuery.docs.first;
    final registrationData = registrationDoc.data();
    final registrationId =
        (registrationData['registrationId'] as String?)?.trim().isNotEmpty == true
            ? (registrationData['registrationId'] as String).trim()
            : registrationDoc.id;
    final playerUserId = (registrationData['userId'] as String?)?.trim() ?? '';
    if (playerUserId.isEmpty) {
      throw StateError('The selected registration does not include a player user ID.');
    }

    final uploadedAt = FieldValue.serverTimestamp();
    final totalScore = scoresByHole.values.fold<int>(
      0,
      (total, score) => total + (score ?? 0),
    );
    final sanitizedScoresByHole = <String, int?>{
      for (final entry in scoresByHole.entries) '${entry.key}': entry.value,
    };
    final payload = {
      'userId': playerUserId,
      'playerName': playerName,
      'courseName': courseName,
      'scoresByHole': sanitizedScoresByHole,
      'totalScore': totalScore,
      'uploadedAt': uploadedAt,
      'source': 'ocr_upload_director_toggle',
      'tournamentId': tournamentId,
      'registrationId': registrationId,
      'round': round,
    };

    await _firestore.collection('users').doc(playerUserId).collection('scorecards').add(payload);
    await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('registrations')
        .doc(registrationId)
        .collection('roundScores')
        .doc('round_$round')
        .set(payload, SetOptions(merge: true));
  }
}
