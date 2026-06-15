import 'tournament.dart';

/// The tournament + round a GM has chosen before uploading scorecard(s).
///
/// Shared by the single-card upload flow and the batch upload flow so both
/// describe "which tournament/round these scores belong to" the same way.
class UploadSelectionContext {
  const UploadSelectionContext({
    required this.tournament,
    required this.round,
  });

  final Tournament tournament;
  final int round;

  String get roundLabel => 'Round $round';
}
