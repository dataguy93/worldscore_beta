import 'package:cloud_firestore/cloud_firestore.dart';

class Tournament {
  const Tournament({
    required this.tournamentId,
    required this.name,
    required this.directorUserId,
    required this.createdAt,
    required this.eventDate,
    required this.clubOrCourseName,
    required this.country,
    required this.state,
    required this.city,
    required this.registrationOpen,
    required this.registrationDeadline,
    required this.numberOfRounds,
    required this.maxPlayers,
    required this.currentPlayerCount,
    this.publicRegistrationSlug,
    this.registrationToken,
    this.inviteOnly = false,
  }) : assert(numberOfRounds >= 1 && numberOfRounds <= 4),
       assert((publicRegistrationSlug != null && registrationToken == null) ||
           (publicRegistrationSlug == null && registrationToken != null));

  final String tournamentId;
  final String name;
  final String directorUserId;
  final DateTime? createdAt;
  final DateTime eventDate;
  final String clubOrCourseName;
  final String country;
  final String state;
  final String city;
  final bool registrationOpen;
  final DateTime registrationDeadline;
  final int numberOfRounds;
  final int maxPlayers;
  final int currentPlayerCount;
  final String? publicRegistrationSlug;
  final String? registrationToken;
  final bool inviteOnly;

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'name': name,
      'directorUserId': directorUserId,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'eventDate': Timestamp.fromDate(eventDate),
      'clubOrCourseName': clubOrCourseName,
      'location': {
        'country': country,
        'state': state,
        'city': city,
      },
      'registrationOpen': registrationOpen,
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'numberOfRounds': numberOfRounds,
      'maxPlayers': maxPlayers,
      'currentPlayerCount': currentPlayerCount,
      'publicRegistrationSlug': publicRegistrationSlug,
      'registrationToken': registrationToken,
      'inviteOnly': inviteOnly,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Tournament.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final location = Map<String, dynamic>.from(data['location'] ?? const {});

    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    final eventDateTimestamp = data['eventDate'] as Timestamp?;
    final registrationDeadlineTimestamp =
        data['registrationDeadline'] as Timestamp?;

    return Tournament(
      tournamentId: (data['tournamentId'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? 'Untitled Tournament',
      directorUserId: (data['directorUserId'] as String?) ?? '',
      createdAt: createdAtTimestamp?.toDate(),
      eventDate: eventDateTimestamp?.toDate() ?? DateTime.now(),
      clubOrCourseName: (data['clubOrCourseName'] as String?) ?? '',
      country: (location['country'] as String?) ?? '',
      state: (location['state'] as String?) ?? '',
      city: (location['city'] as String?) ?? '',
      registrationOpen: (data['registrationOpen'] as bool?) ?? false,
      registrationDeadline:
          registrationDeadlineTimestamp?.toDate() ?? DateTime.now(),
      numberOfRounds: (data['numberOfRounds'] as int?)?.clamp(1, 4) ?? 1,
      maxPlayers: (data['maxPlayers'] as int?) ?? 0,
      currentPlayerCount: (data['currentPlayerCount'] as int?) ?? 0,
      publicRegistrationSlug: data['publicRegistrationSlug'] as String?,
      registrationToken: data['registrationToken'] as String?,
      inviteOnly: (data['inviteOnly'] as bool?) ?? false,
    );
  }

  Tournament copyWith({
    String? tournamentId,
    String? name,
    String? directorUserId,
    DateTime? createdAt,
    DateTime? eventDate,
    String? clubOrCourseName,
    String? country,
    String? state,
    String? city,
    bool? registrationOpen,
    DateTime? registrationDeadline,
    int? numberOfRounds,
    int? maxPlayers,
    int? currentPlayerCount,
    String? publicRegistrationSlug,
    String? registrationToken,
    bool? inviteOnly,
  }) {
    return Tournament(
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      directorUserId: directorUserId ?? this.directorUserId,
      createdAt: createdAt ?? this.createdAt,
      eventDate: eventDate ?? this.eventDate,
      clubOrCourseName: clubOrCourseName ?? this.clubOrCourseName,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      registrationOpen: registrationOpen ?? this.registrationOpen,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      numberOfRounds: numberOfRounds ?? this.numberOfRounds,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      currentPlayerCount: currentPlayerCount ?? this.currentPlayerCount,
      publicRegistrationSlug: publicRegistrationSlug ?? this.publicRegistrationSlug,
      registrationToken: registrationToken ?? this.registrationToken,
      inviteOnly: inviteOnly ?? this.inviteOnly,
    );
  }
}
