import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tournament.dart';
import '../models/tournament_registration.dart';

class TournamentRegistrationException implements Exception {
  const TournamentRegistrationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RegistrationService {
  RegistrationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _registrations(String tournamentId) {
    // Scoped subcollection keeps director and player queries localized to each tournament.
    return _firestore.collection('tournaments').doc(tournamentId).collection('registrations');
  }

  Stream<List<TournamentRegistration>> streamRegistrants(String tournamentId) {
    return _registrations(tournamentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TournamentRegistration.fromDoc).toList());
  }

  Future<List<TournamentRegistration>> fetchRegistrants(String tournamentId) async {
    final snapshot = await _registrations(tournamentId).orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(TournamentRegistration.fromDoc).toList();
  }

  Stream<int> streamRegisteredCount(String tournamentId) {
    return _registrations(tournamentId).snapshots().map(
          (snapshot) => snapshot.docs.where((doc) {
            final status = doc.data()['status'] as String?;
            return status == RegistrationStatus.registered.name;
          }).length,
        );
  }

  Stream<int> streamRoundSubmissionCount({
    required String tournamentId,
    required int round,
  }) {
    return _roundSubmissions(tournamentId: tournamentId, round: round)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<double?> streamRoundAverageTotalScore({
    required String tournamentId,
    required int round,
  }) {
    return _roundSubmissions(tournamentId: tournamentId, round: round)
        .snapshots()
        .map((snapshot) {
      var totalScoreSum = 0.0;
      var totalScoreCount = 0;

      for (final doc in snapshot.docs) {
        final totalScore = doc.data()['totalScore'];
        if (totalScore is num) {
          totalScoreSum += totalScore.toDouble();
          totalScoreCount++;
        }
      }

      if (totalScoreCount == 0) {
        return null;
      }
      return totalScoreSum / totalScoreCount;
    });
  }

  CollectionReference<Map<String, dynamic>> _roundSubmissions({
    required String tournamentId,
    required int round,
  }) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('roundUploads')
        .doc('round_$round')
        .collection('registrations');
  }

  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) {
      return existing;
    }

    final credential = await _auth.signInAnonymously();
    if (credential.user == null) {
      throw const TournamentRegistrationException('Unable to authenticate user.');
    }
    return credential.user!;
  }

  Future<void> registerForTournament({
    required Tournament tournament,
    required String playerName,
    String? email,
    String? phone,
  }) async {
    final user = await ensureSignedIn();
    final tournamentRef = _firestore.collection('tournaments').doc(tournament.tournamentId);
    final registrationRef = _registrations(tournament.tournamentId).doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final tournamentSnapshot = await transaction.get(tournamentRef);
      if (!tournamentSnapshot.exists) {
        throw const TournamentRegistrationException('Tournament not found.');
      }

      final latestTournament = Tournament.fromDoc(tournamentSnapshot);
      final now = DateTime.now();

      // App-side safeguards. These same checks should be mirrored in Firestore security rules
      // or a trusted backend endpoint for production-grade tamper resistance.
      if (!latestTournament.registrationOpen || latestTournament.status != TournamentStatus.open) {
        throw const TournamentRegistrationException('Registration is closed.');
      }
      if (now.isAfter(latestTournament.registrationDeadline)) {
        throw const TournamentRegistrationException('Registration deadline has passed.');
      }
      if (latestTournament.currentPlayerCount >= latestTournament.maxPlayers) {
        throw const TournamentRegistrationException('Tournament is full.');
      }

      final existingRegistration = await transaction.get(registrationRef);
      if (existingRegistration.exists) {
        throw const TournamentRegistrationException('You are already registered.');
      }

      final registration = TournamentRegistration(
        registrationId: user.uid,
        tournamentId: latestTournament.tournamentId,
        userId: user.uid,
        playerName: playerName,
        email: email,
        phone: phone,
        handicap: null,
        status: RegistrationStatus.registered,
        createdAt: null,
      );

      transaction.set(registrationRef, registration.toMap());
      transaction.update(tournamentRef, {
        'currentPlayerCount': latestTournament.currentPlayerCount + 1,
      });
    });
  }

  Future<void> addManualRegistrant({
    required Tournament tournament,
    required String playerName,
    required double handicap,
    String? email,
    String? phone,
  }) async {
    final tournamentRef = _firestore.collection('tournaments').doc(tournament.tournamentId);
    final registrationRef = _registrations(tournament.tournamentId).doc();
    final generatedRegistrationId = registrationRef.id;

    await _firestore.runTransaction((transaction) async {
      final tournamentSnapshot = await transaction.get(tournamentRef);
      if (!tournamentSnapshot.exists) {
        throw const TournamentRegistrationException('Tournament not found.');
      }

      final latestTournament = Tournament.fromDoc(tournamentSnapshot);
      if (latestTournament.currentPlayerCount >= latestTournament.maxPlayers) {
        throw const TournamentRegistrationException('Tournament is full.');
      }

      final registration = TournamentRegistration(
        registrationId: generatedRegistrationId,
        tournamentId: latestTournament.tournamentId,
        userId: 'manual-$generatedRegistrationId',
        playerName: playerName,
        email: email,
        phone: phone,
        handicap: handicap,
        status: RegistrationStatus.registered,
        createdAt: null,
      );

      transaction.set(registrationRef, registration.toMap());
      transaction.update(tournamentRef, {
        'currentPlayerCount': latestTournament.currentPlayerCount + 1,
      });
    });
  }
}
