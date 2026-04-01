import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tournament.dart';
import '../models/tournament_division.dart';

class TournamentService {
  TournamentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _firestore.collection('tournaments');

  Future<Tournament> createTournament({
    required String name,
    required String directorUserId,
    required DateTime eventDate,
    required String location,
    required DateTime registrationDeadline,
    required int maxPlayers,
    bool inviteOnly = false,
    int numberOfRounds = 4,
  }) async {
    if (directorUserId.trim().isEmpty) {
      throw ArgumentError('directorUserId is required to create a tournament.');
    }

    final docRef = _tournaments.doc();
    final slug = await _generateUniqueSlug(name);

    final tournament = Tournament(
      tournamentId: docRef.id,
      name: name,
      directorUserId: directorUserId,
      createdAt: null,
      eventDate: eventDate,
      location: location,
      registrationOpen: true,
      registrationDeadline: registrationDeadline,
      maxPlayers: maxPlayers,
      currentPlayerCount: 0,
      publicRegistrationSlug: slug,
      inviteOnly: inviteOnly,
      numberOfRounds: numberOfRounds,
      status: TournamentStatus.open,
    );

    await docRef.set(tournament.toMap());
    return tournament;
  }

  Future<void> updateTournament(Tournament tournament) async {
    await _tournaments.doc(tournament.tournamentId).update(tournament.toMap());
  }

  Stream<List<Tournament>> streamTournaments() {
    return _tournaments.orderBy('eventDate').snapshots().map(
          (snapshot) => snapshot.docs.map(Tournament.fromDoc).toList(),
        );
  }

  Stream<List<Tournament>> streamDirectorTournaments(String directorUserId) {
    if (directorUserId.trim().isEmpty) {
      return Stream.value(const []);
    }

    return _tournaments
        .where('directorUserId', isEqualTo: directorUserId)
        .snapshots()
        .map((snapshot) {
      final tournaments = snapshot.docs.map(Tournament.fromDoc).toList();
      tournaments.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      return tournaments;
    });
  }

  Future<Tournament?> findBySlug(String slug) async {
    final snapshot =
        await _tournaments.where('publicRegistrationSlug', isEqualTo: slug).limit(1).get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return Tournament.fromDoc(snapshot.docs.first);
  }

  Future<Tournament?> findById(String tournamentId) async {
    final doc = await _tournaments.doc(tournamentId).get();
    if (!doc.exists) {
      return null;
    }
    return Tournament.fromDoc(doc);
  }

  String buildPublicRegistrationLink(String slug) {
    // Deep-link friendly pattern: /tournaments/{slug}/register
    return 'https://worldscore.ai/tournaments/$slug/register';
  }

  Future<String> _generateUniqueSlug(String name) async {
    final base = _slugify(name);
    final random = Random();

    for (var i = 0; i < 8; i++) {
      final suffix = random.nextInt(0xFFFFF).toRadixString(36).padLeft(4, '0');
      final candidate = '$base-$suffix';
      final exists = await _tournaments
          .where('publicRegistrationSlug', isEqualTo: candidate)
          .limit(1)
          .get();
      if (exists.docs.isEmpty) {
        return candidate;
      }
    }

    final fallback = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return '$base-$fallback';
  }

  // ── Division management ──────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _divisions(String tournamentId) {
    return _tournaments.doc(tournamentId).collection('divisions');
  }

  Stream<List<TournamentDivision>> streamDivisions(String tournamentId) {
    return _divisions(tournamentId)
        .orderBy('minHandicap')
        .snapshots()
        .map((snap) => snap.docs.map(TournamentDivision.fromDoc).toList());
  }

  Future<void> addDivision({
    required String tournamentId,
    required String name,
    required double minHandicap,
    required double maxHandicap,
  }) async {
    final ref = _divisions(tournamentId).doc();
    final division = TournamentDivision(
      divisionId: ref.id,
      tournamentId: tournamentId,
      name: name,
      minHandicap: minHandicap,
      maxHandicap: maxHandicap,
    );
    await ref.set(division.toMap());
  }

  Future<void> updateDivision(TournamentDivision division) async {
    await _divisions(division.tournamentId)
        .doc(division.divisionId)
        .update(division.toMap());
  }

  Future<void> deleteDivision({
    required String tournamentId,
    required String divisionId,
  }) async {
    await _divisions(tournamentId).doc(divisionId).delete();
  }

  String _slugify(String value) {
    final lower = value.toLowerCase().trim();
    final slug = lower
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'tournament' : slug;
  }
}
