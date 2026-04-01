import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentDivision {
  const TournamentDivision({
    required this.divisionId,
    required this.tournamentId,
    required this.name,
    required this.minHandicap,
    required this.maxHandicap,
  });

  final String divisionId;
  final String tournamentId;
  final String name;
  final double minHandicap;
  final double maxHandicap;

  Map<String, dynamic> toMap() {
    return {
      'divisionId': divisionId,
      'tournamentId': tournamentId,
      'name': name,
      'minHandicap': minHandicap,
      'maxHandicap': maxHandicap,
    };
  }

  factory TournamentDivision.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return TournamentDivision(
      divisionId: (data['divisionId'] as String?) ?? doc.id,
      tournamentId: (data['tournamentId'] as String?) ?? '',
      name: (data['name'] as String?) ?? 'Unnamed Division',
      minHandicap: (data['minHandicap'] as num?)?.toDouble() ?? 0.0,
      maxHandicap: (data['maxHandicap'] as num?)?.toDouble() ?? 54.0,
    );
  }
}
