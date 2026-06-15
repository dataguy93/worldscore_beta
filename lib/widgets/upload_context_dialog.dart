import 'package:flutter/material.dart';

import '../models/tournament.dart';
import '../models/upload_selection_context.dart';
import '../services/tournament_service.dart';

/// Prompts the GM to choose which tournament and round a scorecard upload
/// belongs to. Returns the chosen [UploadSelectionContext], or null if the GM
/// cancels. Shared by both the single-card and batch upload flows so the
/// selection UX stays identical.
Future<UploadSelectionContext?> showUploadContextDialog(
  BuildContext context, {
  required String gmUserId,
  TournamentService? tournamentService,
}) {
  final service = tournamentService ?? TournamentService();
  final tournamentsStream = gmUserId.trim().isEmpty
      ? Stream.value(const <Tournament>[])
      : service.streamGmTournaments(gmUserId);
  Tournament? selectedTournament;
  int? selectedRound;

  return showDialog<UploadSelectionContext>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return StreamBuilder<List<Tournament>>(
            stream: tournamentsStream,
            builder: (context, tournamentSnapshot) {
              final tournaments = tournamentSnapshot.data ?? const <Tournament>[];

              if (selectedTournament != null) {
                final matchingIndex = tournaments.indexWhere(
                  (tournament) =>
                      tournament.tournamentId == selectedTournament!.tournamentId,
                );

                if (matchingIndex == -1) {
                  selectedTournament = null;
                } else {
                  selectedTournament = tournaments[matchingIndex];
                }
              }

              return AlertDialog(
                title: const Text('Select scorecard upload details'),
                content: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Before uploading, choose the tournament and round.',
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Tournament>(
                        decoration: const InputDecoration(
                          labelText: 'Tournament',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedTournament,
                        isExpanded: true,
                        items: tournaments
                            .map(
                              (tournament) => DropdownMenuItem<Tournament>(
                                value: tournament,
                                child: Text(tournament.name, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: tournaments.isEmpty
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedTournament = value;
                                  selectedRound = null;
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Round',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedRound,
                        items: List.generate(
                          4,
                          (index) => index + 1,
                        )
                            .map(
                              (round) => DropdownMenuItem<int>(
                                value: round,
                                child: Text('Round $round'),
                              ),
                            )
                            .toList(),
                        onChanged: selectedTournament == null
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedRound = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: selectedTournament != null && selectedRound != null
                        ? () => Navigator.of(dialogContext).pop(
                              UploadSelectionContext(
                                tournament: selectedTournament!,
                                round: selectedRound!,
                              ),
                            )
                        : null,
                    child: const Text('Continue'),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}
