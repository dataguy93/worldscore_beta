import 'package:cloud_firestore/cloud_firestore.dart';

enum RegistrationStatus { registered, waitlisted, canceled }

class TournamentRegistration {
  const TournamentRegistration({
    required this.registrationId,
    required this.tournamentId,
    required this.userId,
    required this.playerName,
    required this.status,
    required this.createdAt,
    this.email,
    this.phone,
  });

  final String registrationId;
  final String tournamentId;
  final String userId;
  final String playerName;
  final String? email;
  final String? phone;
  final RegistrationStatus status;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'registrationId': registrationId,
      'tournamentId': tournamentId,
      'userId': userId,
      'playerName': playerName,
      'email': email,
      'phone': phone,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TournamentRegistration.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return TournamentRegistration(
      registrationId: doc.id,
      tournamentId: (data['tournamentId'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      playerName: (data['playerName'] as String?) ?? 'Unknown Player',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      status: _statusFromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static RegistrationStatus _statusFromString(String? value) {
    return RegistrationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => RegistrationStatus.registered,
    );
  }
}
