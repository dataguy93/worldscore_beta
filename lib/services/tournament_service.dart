import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tournament.dart';
import '../models/tournament_registration.dart';

class RegistrationBlockedException implements Exception {
  const RegistrationBlockedException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class TournamentService {
  TournamentService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _firestore.collection('tournaments');

  // Top-level registrations keeps querying simple for both:
  // - all registrations in one tournament
  // - all registrations for one user across tournaments.
  // We use deterministic doc IDs: {tournamentId}_{userId} to enforce no duplicates.
  CollectionReference<Map<String, dynamic>> get _registrations =>
      _firestore.collection('registrations');

  String generatePublicSlug(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final random = _randomToken(length: 6);
    return '${normalized.isEmpty ? 'tournament' : normalized}-$random';
  }

  Future<void> createTournament(Tournament tournament) async {
    await _tournaments.doc(tournament.tournamentId).set(tournament.toMap());
  }

  Stream<List<Tournament>> watchDirectorTournaments(String directorUserId) {
    final query = directorUserId == 'anonymous-director'
        ? _tournaments.orderBy('eventDate')
        : _tournaments
            .where('directorUserId', isEqualTo: directorUserId)
            .orderBy('eventDate');
    return query.snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Tournament.fromDoc(doc)).toList(),
        );
  }

  Future<Tournament?> getTournamentBySlug(String slug) async {
    final query = await _tournaments
        .where('publicRegistrationSlug', isEqualTo: slug)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      return null;
    }
    return Tournament.fromDoc(query.docs.first);
  }

  Future<Tournament?> getTournamentById(String tournamentId) async {
    final doc = await _tournaments.doc(tournamentId).get();
    if (!doc.exists) {
      return null;
    }
    return Tournament.fromDoc(doc);
  }

  Future<Tournament?> getTournamentFromRouteArgs({
    String? tournamentId,
    String? slug,
    String? token,
  }) async {
    if (slug != null && slug.isNotEmpty) {
      return getTournamentBySlug(slug);
    }
    if (tournamentId != null && tournamentId.isNotEmpty) {
      return getTournamentById(tournamentId);
    }
    if (token != null && token.isNotEmpty) {
      final query = await _tournaments
          .where('publicRegistrationSlug', isEqualTo: token)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return Tournament.fromDoc(query.docs.first);
      }
    }
    return null;
  }

  Future<void> registerCurrentUser({
    required Tournament tournament,
    required String playerName,
    String? email,
    String? phone,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const RegistrationBlockedException(
        'unauthenticated',
        'Please sign in before registering.',
      );
    }

    final registrationId = '${tournament.tournamentId}_${currentUser.uid}';
    await _firestore.runTransaction((transaction) async {
      final tournamentRef = _tournaments.doc(tournament.tournamentId);
      final registrationRef = _registrations.doc(registrationId);

      final tournamentSnap = await transaction.get(tournamentRef);
      if (!tournamentSnap.exists) {
        throw const RegistrationBlockedException(
          'invalid_tournament',
          'Tournament was not found.',
        );
      }

      final latestTournament = Tournament.fromDoc(tournamentSnap);
      _ensureRegistrationAllowed(latestTournament);

      final existingRegistration = await transaction.get(registrationRef);
      if (existingRegistration.exists) {
        throw const RegistrationBlockedException(
          'already_registered',
          'You are already registered for this tournament.',
        );
      }

      final registration = TournamentRegistration(
        registrationId: registrationId,
        tournamentId: latestTournament.tournamentId,
        userId: currentUser.uid,
        playerName: playerName,
        email: email,
        phone: phone,
        status: RegistrationStatus.registered,
        createdAt: DateTime.now(),
      );

      transaction.set(registrationRef, registration.toMap());
      transaction.update(tournamentRef, {
        'currentPlayerCount': latestTournament.currentPlayerCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<TournamentRegistration>> watchRegistrationsForTournament(
    String tournamentId,
  ) {
    return _registrations
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TournamentRegistration.fromDoc(doc)).toList());
  }

  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) {
      return existing;
    }
    return _auth.signInAnonymously().then((cred) => cred.user!);
  }

  void _ensureRegistrationAllowed(Tournament tournament) {
    // NOTE: This app-side check provides UX messaging. Critical enforcement should
    // also exist in Firestore Security Rules / backend to prevent bypass.
    if (!tournament.registrationOpen || tournament.status != TournamentStatus.open) {
      throw const RegistrationBlockedException(
        'registration_closed',
        'Registration is currently closed.',
      );
    }
    if (DateTime.now().isAfter(tournament.registrationDeadline)) {
      throw const RegistrationBlockedException(
        'registration_expired',
        'Registration deadline has passed.',
      );
    }
    if (tournament.currentPlayerCount >= tournament.maxPlayers) {
      throw const RegistrationBlockedException(
        'tournament_full',
        'Tournament is already full.',
      );
    }
  }

  String _randomToken({int length = 6}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
