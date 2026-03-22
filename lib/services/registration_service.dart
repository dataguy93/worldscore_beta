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

class TournamentRegistrationResult {
  const TournamentRegistrationResult({
    required this.registration,
    required this.assignedStatus,
  });

  final TournamentRegistration registration;
  final RegistrationStatus assignedStatus;
}

class RegistrationService {
  RegistrationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _registrations(String tournamentId) {
    return _firestore.collection('tournaments').doc(tournamentId).collection('registrations');
  }

  Stream<List<TournamentRegistration>> streamRegistrants(String tournamentId) {
    return _registrations(tournamentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TournamentRegistration.fromDoc).toList());
  }

  Future<TournamentRegistration?> getRegistrationForUser({
    required String tournamentId,
    required String userId,
  }) async {
    final snapshot = await _registrations(tournamentId).doc(userId).get();
    if (!snapshot.exists) {
      return null;
    }
    return TournamentRegistration.fromDoc(snapshot);
  }

  Future<TournamentRegistrationResult> registerForTournament({
    required Tournament tournament,
    required User user,
    required String playerName,
    required String playerEmail,
    String? phone,
    bool allowWaitlistWhenFull = true,
    String source = 'link',
  }) async {
    final tournamentRef = _firestore.collection('tournaments').doc(tournament.tournamentId);
    final registrationRef = _registrations(tournament.tournamentId).doc(user.uid);

    return _firestore.runTransaction((transaction) async {
      final tournamentSnapshot = await transaction.get(tournamentRef);
      if (!tournamentSnapshot.exists) {
        throw const TournamentRegistrationException('Tournament not found.');
      }

      final latestTournament = Tournament.fromDoc(tournamentSnapshot);
      final now = DateTime.now();
      final existingRegistration = await transaction.get(registrationRef);

      if (existingRegistration.exists) {
        final current = TournamentRegistration.fromDoc(existingRegistration);
        if (current.status == RegistrationStatus.registered ||
            current.status == RegistrationStatus.waitlisted) {
          throw const TournamentRegistrationException('You are already registered.');
        }
      }

      if (!latestTournament.registrationOpen || latestTournament.status != TournamentStatus.open) {
        throw const TournamentRegistrationException('Registration is closed.');
      }
      if (now.isAfter(latestTournament.registrationDeadline)) {
        throw const TournamentRegistrationException('Registration deadline has passed.');
      }

      final isFull = latestTournament.currentPlayerCount >= latestTournament.maxPlayers;
      if (isFull && !allowWaitlistWhenFull) {
        throw const TournamentRegistrationException('Tournament is full.');
      }

      final assignedStatus =
          isFull ? RegistrationStatus.waitlisted : RegistrationStatus.registered;
      final registration = TournamentRegistration(
        registrationId: user.uid,
        tournamentId: latestTournament.tournamentId,
        userId: user.uid,
        playerName: playerName,
        email: playerEmail,
        phone: phone,
        status: assignedStatus,
        createdAt: null,
        updatedAt: null,
        source: source,
      );

      transaction.set(registrationRef, registration.toMap(), SetOptions(merge: true));

      if (assignedStatus == RegistrationStatus.registered) {
        transaction.update(tournamentRef, {
          'currentPlayerCount': latestTournament.currentPlayerCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return TournamentRegistrationResult(
        registration: registration,
        assignedStatus: assignedStatus,
      );
    });
  }
}
