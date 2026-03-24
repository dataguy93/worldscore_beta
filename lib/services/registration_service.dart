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
        status: RegistrationStatus.registered,
        createdAt: null,
      );

      transaction.set(registrationRef, registration.toMap());
      transaction.update(tournamentRef, {
        'currentPlayerCount': latestTournament.currentPlayerCount + 1,
      });
    });
  }

  Future<void> manuallyRegisterPlayer({
    required Tournament tournament,
    required String playerName,
    String? email,
    String? phone,
  }) async {
    final tournamentRef = _firestore.collection('tournaments').doc(tournament.tournamentId);
    final registrationRef = _registrations(tournament.tournamentId).doc();

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
        registrationId: registrationRef.id,
        tournamentId: latestTournament.tournamentId,
        userId: 'manual:${registrationRef.id}',
        playerName: playerName,
        email: email,
        phone: phone,
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
