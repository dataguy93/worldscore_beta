import 'package:cloud_firestore/cloud_firestore.dart';

enum RegistrationStatus { registered, waitlisted, cancelled }

class TournamentRegistration {
  const TournamentRegistration({
    required this.registrationId,
    required this.tournamentId,
    required this.userId,
    required this.playerName,
    required this.email,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.source,
  });

  final String registrationId;
  final String tournamentId;
  final String userId;
  final String playerName;
  final String? email;
  final String? phone;
  final RegistrationStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? source;

  Map<String, dynamic> toMap() {
    return {
      'registrationId': registrationId,
      'tournamentId': tournamentId,
      'userId': userId,
      'playerName': playerName,
      'email': email,
      'phone': phone,
      'status': status.name,
      'source': source,
      'createdAt':
          createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TournamentRegistration.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    final updatedAtTimestamp = data['updatedAt'] as Timestamp?;
    final statusValue = (data['status'] as String?) ?? RegistrationStatus.registered.name;

    return TournamentRegistration(
      registrationId: (data['registrationId'] as String?) ?? doc.id,
      tournamentId: (data['tournamentId'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      playerName: (data['playerName'] as String?) ?? 'Unknown Player',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      status: _statusFromString(statusValue),
      source: data['source'] as String?,
      createdAt: createdAtTimestamp?.toDate(),
      updatedAt: updatedAtTimestamp?.toDate(),
    );
  }

  static RegistrationStatus _statusFromString(String value) {
    if (value == 'canceled') {
      return RegistrationStatus.cancelled;
    }

    return RegistrationStatus.values.firstWhere(
      (entry) => entry.name == value,
      orElse: () => RegistrationStatus.registered,
    );
  }
}
