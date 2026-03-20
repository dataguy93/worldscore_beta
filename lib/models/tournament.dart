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
    this.inviteOnly = false,
    this.status = TournamentStatus.draft,
    this.roundCount = 1,
    this.roundFormats = const <String>[],
    this.eventType = 'Singles',
  });

  final String tournamentId;
  final String name;
  final String directorUserId;
  final DateTime createdAt;
  final DateTime eventDate;
  final String location;
  final bool registrationOpen;
  final DateTime registrationDeadline;
  final int maxPlayers;
  final int currentPlayerCount;
  final String publicRegistrationSlug;
  final bool inviteOnly;
  final TournamentStatus status;

  // Existing tournament config fields retained for backward compatibility.
  final int roundCount;
  final List<String> roundFormats;
  final String eventType;

  bool get deadlinePassed => DateTime.now().isAfter(registrationDeadline);

  bool get isFull => currentPlayerCount >= maxPlayers;

  String get statusLabel => status.name;

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'name': name,
      'directorUserId': directorUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location,
      'registrationOpen': registrationOpen,
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'maxPlayers': maxPlayers,
      'currentPlayerCount': currentPlayerCount,
      'publicRegistrationSlug': publicRegistrationSlug,
      'inviteOnly': inviteOnly,
      'status': status.name,
      'roundCount': roundCount,
      'roundFormats': roundFormats,
      'eventType': eventType,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Tournament.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final eventDate = (data['eventDate'] as Timestamp?)?.toDate() ??
        (data['startDate'] as Timestamp?)?.toDate();
    final registrationDeadline =
        (data['registrationDeadline'] as Timestamp?)?.toDate() ?? eventDate;
    final maxPlayers = (data['maxPlayers'] as int?) ?? 0;

    return Tournament(
      tournamentId: doc.id,
      name: (data['name'] as String?) ?? 'Untitled Tournament',
      directorUserId: (data['directorUserId'] as String?) ?? 'unknown-director',
      createdAt: createdAt ?? DateTime.now(),
      eventDate: eventDate ?? DateTime.now(),
      location: (data['location'] as String?) ??
          _legacyLocationFromParts(
            city: data['city'] as String?,
            state: data['state'] as String?,
            country: data['country'] as String?,
            clubOrCourse: data['clubOrCourse'] as String?,
          ),
      registrationOpen: (data['registrationOpen'] as bool?) ?? false,
      registrationDeadline: registrationDeadline ?? DateTime.now(),
      maxPlayers: maxPlayers,
      currentPlayerCount: (data['currentPlayerCount'] as int?) ??
          ((data['registeredPlayers'] as List<dynamic>?)?.length ?? 0),
      publicRegistrationSlug: (data['publicRegistrationSlug'] as String?) ?? doc.id,
      inviteOnly: (data['inviteOnly'] as bool?) ?? false,
      status: _statusFromString(data['status'] as String?),
      roundCount: (data['roundCount'] as int?) ?? 1,
      roundFormats: List<String>.from(data['roundFormats'] ?? const <String>[]),
      eventType: (data['eventType'] as String?) ?? 'Singles',
    );
  }

  static TournamentStatus _statusFromString(String? value) {
    return TournamentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TournamentStatus.draft,
    );
  }

  static String _legacyLocationFromParts({
    String? city,
    String? state,
    String? country,
    String? clubOrCourse,
  }) {
    final parts = <String>[
      if ((clubOrCourse ?? '').trim().isNotEmpty) clubOrCourse!.trim(),
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((state ?? '').trim().isNotEmpty) state!.trim(),
      if ((country ?? '').trim().isNotEmpty) country!.trim(),
    ];
    if (parts.isEmpty) {
      return 'TBD';
    }
    return parts.join(', ');
  }
}
