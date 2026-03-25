import 'package:cloud_firestore/cloud_firestore.dart';

enum RegistrationStatus { registered, waitlisted, canceled }

class TournamentRegistration {
  const TournamentRegistration({
    required this.registrationId,
    required this.tournamentId,
    required this.userId,
    required this.playerName,
    required this.email,
    required this.phone,
    required this.handicap,
    required this.status,
    required this.createdAt,
  });

  final String registrationId;
  final String tournamentId;
  final String userId;
  final String playerName;
  final String? email;
  final String? phone;
  final double? handicap;
  final RegistrationStatus status;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'registrationId': registrationId,
      'tournamentId': tournamentId,
      'userId': userId,
      'playerName': playerName,
      'email': email,
      'phone': phone,
      'handicap': handicap,
      'status': status.name,
      'createdAt':
          createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }

  factory TournamentRegistration.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAtTimestamp = data['createdAt'] as Timestamp?;

    return TournamentRegistration(
      registrationId: (data['registrationId'] as String?) ?? doc.id,
      tournamentId: (data['tournamentId'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      playerName: (data['playerName'] as String?) ?? 'Unknown Player',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      handicap: (data['handicap'] as num?)?.toDouble(),
      status: RegistrationStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => RegistrationStatus.registered,
      ),
      createdAt: createdAtTimestamp?.toDate(),
    );
  }
}
