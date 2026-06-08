import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentStatus { draft, open, closed, completed }

class Tournament {
  const Tournament({
    required this.tournamentId,
    required this.name,
    required this.gmUserId,
    required this.createdAt,
    required this.eventDate,
    required this.location,
    required this.registrationOpen,
    required this.registrationDeadline,
    required this.maxPros,
    required this.currentProCount,
    required this.publicRegistrationSlug,
    required this.inviteOnly,
    required this.status,
    required this.numberOfRounds,
  });

  final String tournamentId;
  final String name;
  final String gmUserId;
  final DateTime? createdAt;
  final DateTime eventDate;
  final String location;
  final bool registrationOpen;
  final DateTime registrationDeadline;
  final int maxPros;
  final int currentProCount;
  final String publicRegistrationSlug;
  final bool inviteOnly;
  final TournamentStatus status;
  final int numberOfRounds;

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'name': name,
      'directorUserId': gmUserId,
      'createdAt':
          createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location,
      'registrationOpen': registrationOpen,
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'maxPlayers': maxPros,
      'currentPlayerCount': currentProCount,
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
      gmUserId: (data['directorUserId'] as String?) ?? '',
      createdAt: createdAtTimestamp?.toDate(),
      eventDate: eventDateTimestamp?.toDate() ?? DateTime.now(),
      location: (data['location'] as String?) ?? '',
      registrationOpen: (data['registrationOpen'] as bool?) ?? false,
      registrationDeadline:
          registrationDeadlineTimestamp?.toDate() ?? DateTime.now(),
      maxPros: (data['maxPlayers'] as int?) ?? 0,
      currentProCount: (data['currentPlayerCount'] as int?) ?? 0,
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
