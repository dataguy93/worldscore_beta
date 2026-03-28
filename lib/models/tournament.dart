import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentStatus { draft, open, closed, completed }

class Tournament {
  const Tournament({
    required this.tournamentId,
    required this.name,
    required this.directorUserId,
    required this.createdAt,
    required this.eventDate,
    required this.location,
    required this.registrationOpen,
    required this.registrationDeadline,
    required this.maxPlayers,
    required this.currentPlayerCount,
    required this.publicRegistrationSlug,
    required this.inviteOnly,
    required this.status,
    required this.numberOfRounds,
  });

  final String tournamentId;
  final String name;
  final String directorUserId;
  final DateTime? createdAt;
  final DateTime eventDate;
  final String location;
  final bool registrationOpen;
  final DateTime registrationDeadline;
  final int maxPlayers;
  final int currentPlayerCount;
  final String publicRegistrationSlug;
  final bool inviteOnly;
  final TournamentStatus status;
  final int numberOfRounds;

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'name': name,
      'directorUserId': directorUserId,
      'createdAt':
          createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location,
      'registrationOpen': registrationOpen,
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'maxPlayers': maxPlayers,
      'currentPlayerCount': currentPlayerCount,
      'publicRegistrationSlug': publicRegistrationSlug,
      'inviteOnly': inviteOnly,
      'status': status.name,
      'numberOfRounds': numberOfRounds,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Tournament.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    final eventDateTimestamp = data['eventDate'] as Timestamp?;
    final registrationDeadlineTimestamp = data['registrationDeadline'] as Timestamp?;

    return Tournament(
      tournamentId: (data['tournamentId'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? 'Untitled Tournament',
      directorUserId: (data['directorUserId'] as String?) ?? '',
      createdAt: createdAtTimestamp?.toDate(),
      eventDate: eventDateTimestamp?.toDate() ?? DateTime.now(),
      location: (data['location'] as String?) ?? '',
      registrationOpen: (data['registrationOpen'] as bool?) ?? false,
      registrationDeadline:
          registrationDeadlineTimestamp?.toDate() ?? DateTime.now(),
      maxPlayers: (data['maxPlayers'] as int?) ?? 0,
      currentPlayerCount: (data['currentPlayerCount'] as int?) ?? 0,
      publicRegistrationSlug: (data['publicRegistrationSlug'] as String?) ?? '',
      inviteOnly: (data['inviteOnly'] as bool?) ?? false,
      numberOfRounds: (data['numberOfRounds'] as int?) ?? 4,
      status: TournamentStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => TournamentStatus.draft,
      ),
    );
  }
}
