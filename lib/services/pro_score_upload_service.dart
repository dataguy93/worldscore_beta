import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProScoreUploadService {
  ProScoreUploadService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<Set<int>> getUploadedRoundsForRegistration({
    required String tournamentId,
    required String registrationId,
    int maxRounds = 4,
  }) async {
    final roundSnapshots = await Future.wait(
      List.generate(
        maxRounds,
        (index) => _firestore
            .collection('tournaments')
            .doc(tournamentId)
            .collection('roundUploads')
            .doc('round_${index + 1}')
            .collection('registrations')
            .doc(registrationId)
            .get(),
      ),
    );

    final uploadedRounds = <int>{};
    for (var index = 0; index < roundSnapshots.length; index++) {
      if (roundSnapshots[index].exists) {
        uploadedRounds.add(index + 1);
      }
    }

    return uploadedRounds;
  }

  Future<void> uploadMeScore({
    required String proName,
    required Map<int, int?> scoresByHole,
    required Map<int, int?> parsByHole,
    required String courseName,
    String? coursePlaceId,
    Map<int, int?>? handicapByHole,
    String? tournamentId,
    int? round,
    String? registrationId,
    String? scorecardImageUrl,
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
    final sanitizedParsByHole = <String, int?>{
      for (final entry in parsByHole.entries) '${entry.key}': entry.value,
    };
    final sanitizedHandicapByHole = handicapByHole != null
        ? <String, int?>{
            for (final entry in handicapByHole.entries) '${entry.key}': entry.value,
          }
        : null;

    final scorecardPayload = {
      'userId': userId,
      'playerName': proName,
      'courseName': courseName,
      if (coursePlaceId != null) 'coursePlaceId': coursePlaceId,
      'scoresByHole': sanitizedScoresByHole,
      'parsByHole': sanitizedParsByHole,
      if (sanitizedHandicapByHole != null) 'handicapByHole': sanitizedHandicapByHole,
      'totalScore': totalScore,
      'uploadedAt': uploadedAt,
      'source': 'ocr_upload_me_toggle',
      if (tournamentId != null) 'tournamentId': tournamentId,
      if (round != null) 'round': round,
      if (registrationId != null) 'registrationId': registrationId,
      if (scorecardImageUrl != null) 'scorecardImageUrl': scorecardImageUrl,
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('scorecards')
        .add(scorecardPayload);

    if (tournamentId != null && round != null && registrationId != null) {
      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('roundUploads')
          .doc('round_$round')
          .collection('registrations')
          .doc(registrationId)
          .set({
            ...scorecardPayload,
            'roundLabel': 'Round $round',
          }, SetOptions(merge: true));
    }
  }

  Future<Set<String>> getUploadedRegistrationIdsForRound({
    required String tournamentId,
    required int round,
  }) async {
    final snapshot = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('roundUploads')
        .doc('round_$round')
        .collection('registrations')
        .get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  Future<void> uploadRegistrationScore({
    required String tournamentId,
    required int round,
    required String registrationId,
    required String registrationUserId,
    required String registrationProName,
    required String detectedProName,
    required Map<int, int?> scoresByHole,
    required Map<int, int?> parByHole,
    required String courseName,
    String? coursePlaceId,
    Map<int, int?>? handicapByHole,
    String? scorecardImageUrl,
  }) async {
    final uploadedAt = FieldValue.serverTimestamp();
    final totalScore = scoresByHole.values.fold<int>(
      0,
      (total, score) => total + (score ?? 0),
    );
    final sanitizedScoresByHole = <String, int?>{
      for (final entry in scoresByHole.entries) '${entry.key}': entry.value,
    };
    final sanitizedParsByHole = <String, int?>{
      for (final entry in parByHole.entries) '${entry.key}': entry.value,
    };
    final sanitizedHandicapByHole = handicapByHole != null
        ? <String, int?>{
            for (final entry in handicapByHole.entries) '${entry.key}': entry.value,
          }
        : null;

    final scorecardPayload = {
      'userId': registrationUserId,
      'playerName': registrationProName,
      'ocrDetectedPlayerName': detectedProName,
      'courseName': courseName,
      if (coursePlaceId != null) 'coursePlaceId': coursePlaceId,
      'scoresByHole': sanitizedScoresByHole,
      'parsByHole': sanitizedParsByHole,
      if (sanitizedHandicapByHole != null) 'handicapByHole': sanitizedHandicapByHole,
      'totalScore': totalScore,
      'uploadedAt': uploadedAt,
      'source': 'ocr_upload_director_assignment',
      'tournamentId': tournamentId,
      'round': round,
      'registrationId': registrationId,
      if (scorecardImageUrl != null) 'scorecardImageUrl': scorecardImageUrl,
    };

    await _firestore
        .collection('users')
        .doc(registrationUserId)
        .collection('scorecards')
        .add(scorecardPayload);

    await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('roundUploads')
        .doc('round_$round')
        .collection('registrations')
        .doc(registrationId)
        .set({
      ...scorecardPayload,
      'roundLabel': 'Round $round',
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserScorecards(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('scorecards')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserScorecardHistory(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('scorecards')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  /// Deletes a previously uploaded round (scorecard) from the PRO's profile.
  Future<void> deleteUserScorecard({
    required String userId,
    required String scorecardId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('scorecards')
        .doc(scorecardId)
        .delete();
  }
}
