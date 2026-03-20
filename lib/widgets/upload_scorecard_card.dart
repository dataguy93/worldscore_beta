import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ocr_scorecard_response.dart';
import '../models/tournament.dart';
import '../models/tournament_registration.dart';
import '../services/ocr_service.dart';
import '../services/registration_service.dart';
import '../services/tournament_service.dart';
import 'menu_card.dart';

enum UploadWidgetRole {
  director,
  player,
}

class UploadScorecardCard extends StatefulWidget {
  const UploadScorecardCard({
    required this.role,
    super.key,
  });

  final UploadWidgetRole role;

  @override
  State<UploadScorecardCard> createState() => _UploadScorecardCardState();
}

class _UploadScorecardCardState extends State<UploadScorecardCard> {
  final OcrService _ocrService = OcrService(useMockData: kDebugMode);
  final TournamentService _tournamentService = TournamentService();
  final RegistrationService _registrationService = RegistrationService();
  bool _isUploadingTestImage = false;

  bool get _requiresTournamentSelection => widget.role == UploadWidgetRole.director;

  Future<void> _handleUploadSelection() async {
    final uploadContext = _requiresTournamentSelection
        ? await _showUploadContextDialog()
        : const _UploadSelectionContext();
    if (uploadContext == null) {
      return;
    }

    final didConfirmUpload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Preview scorecard upload'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_requiresTournamentSelection) ...[
                Text('Tournament: ${uploadContext.tournament!.name}'),
                Text('Round: ${uploadContext.roundLabel}'),
                Text('Player: ${uploadContext.registration!.playerName}'),
                const SizedBox(height: 12),
              ],
              const Text(
                'In production, this will come from the camera. For now, this test image will be uploaded.',
              ),
              const SizedBox(height: 12),
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: Image(
                  image: AssetImage('assets/scorecard.jpeg'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm Upload'),
            ),
          ],
        );
      },
    );

    if (didConfirmUpload != true || _isUploadingTestImage) {
      return;
    }

    setState(() {
      _isUploadingTestImage = true;
    });

    try {
      final imageBytes = await rootBundle.load('assets/scorecard.jpeg');
      final fileName =
          'test_scorecard_${DateTime.now().millisecondsSinceEpoch}.jpeg';
      final scorecard = await _ocrService.fetchScorecardResults(
        imageBytes.buffer.asUint8List(),
        fileName,
      );

      if (!mounted) {
        return;
      }

      final snackBarMessage = _requiresTournamentSelection
          ? 'Uploaded ${uploadContext.tournament!.name} (${uploadContext.roundLabel}) for ${uploadContext.registration!.playerName}.'
          : 'Scorecard uploaded successfully.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(snackBarMessage),
          ),
        );

      _showOcrResults(scorecard);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Upload failed: $error')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingTestImage = false;
        });
      }
    }
  }

  Future<_UploadSelectionContext?> _showUploadContextDialog() {
    final tournamentsStream = _tournamentService.streamTournaments();
    Tournament? selectedTournament;
    TournamentRegistration? selectedRegistration;
    int? selectedRound;

    return showDialog<_UploadSelectionContext>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return StreamBuilder<List<Tournament>>(
              stream: tournamentsStream,
              builder: (context, tournamentSnapshot) {
                final tournaments = tournamentSnapshot.data ?? const <Tournament>[];

                if (selectedTournament != null &&
                    !tournaments.any(
                      (tournament) =>
                          tournament.tournamentId == selectedTournament!.tournamentId,
                    )) {
                  selectedTournament = null;
                  selectedRegistration = null;
                }

                final registrationStream = selectedTournament == null
                    ? null
                    : _registrationService
                        .streamRegistrants(selectedTournament!.tournamentId);

                return AlertDialog(
                  title: const Text('Select scorecard upload details'),
                  content: SizedBox(
                    width: 480,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Before uploading, choose the tournament, round, and registered player.',
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
                                  child: Text(
                                    tournament.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: tournaments.isEmpty
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedTournament = value;
                                    selectedRegistration = null;
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
                            (index) => DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text('Round ${index + 1}'),
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedRound = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<TournamentRegistration>>(
                          stream: registrationStream,
                          builder: (context, registrationSnapshot) {
                            final registrations =
                                registrationSnapshot.data ?? const <TournamentRegistration>[];

                            if (selectedRegistration != null &&
                                !registrations.any(
                                  (registration) =>
                                      registration.registrationId ==
                                      selectedRegistration!.registrationId,
                                )) {
                              selectedRegistration = null;
                            }

                            return DropdownButtonFormField<TournamentRegistration>(
                              decoration: const InputDecoration(
                                labelText: 'Registered player',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedRegistration,
                              isExpanded: true,
                              items: registrations
                                  .map(
                                    (registration) =>
                                        DropdownMenuItem<TournamentRegistration>(
                                      value: registration,
                                      child: Text(
                                        registration.playerName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (selectedTournament == null ||
                                      registrations.isEmpty)
                                  ? null
                                  : (value) {
                                      setDialogState(() {
                                        selectedRegistration = value;
                                      });
                                    },
                            );
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
                      onPressed: selectedTournament != null &&
                              selectedRound != null &&
                              selectedRegistration != null
                          ? () => Navigator.of(dialogContext).pop(
                                _UploadSelectionContext(
                                  tournament: selectedTournament,
                                  round: selectedRound,
                                  registration: selectedRegistration,
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

  void _showOcrResults(OcrScorecardResponse scorecard) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('OCR score extraction complete'),
          content: SizedBox(
            width: 1000,
            child: SingleChildScrollView(
              child: OcrScorecardView(scorecard: scorecard),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                showDialog<void>(
                  context: dialogContext,
                  builder: (jsonDialogContext) {
                    return AlertDialog(
                      title: const Text('Raw OCR JSON'),
                      content: SingleChildScrollView(
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ')
                              .convert(scorecard.toJson()),
                        ),
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.of(jsonDialogContext).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('View Raw JSON'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MenuCard(
          label: 'Upload',
          subtitle: 'Scan and upload scorecards as players finish each day.',
          onTap: _isUploadingTestImage ? null : _handleUploadSelection,
        ),
        if (_isUploadingTestImage) ...[
          const SizedBox(height: 8),
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ],
    );
  }
}

class _UploadSelectionContext {
  const _UploadSelectionContext({
    this.tournament,
    this.round,
    this.registration,
  });

  final Tournament? tournament;
  final int? round;
  final TournamentRegistration? registration;

  String get roundLabel => 'Round $round';
}

class OcrScorecardView extends StatefulWidget {
  const OcrScorecardView({super.key, required this.scorecard});

  final OcrScorecardResponse scorecard;

  @override
  State<OcrScorecardView> createState() => _OcrScorecardViewState();
}

class _OcrScorecardViewState extends State<OcrScorecardView> {
  final Map<_EditedHoleKey, int?> _editedScores = {};

  int? _scoreForPlayerHole(OcrPlayerScore player, int hole) {
    return _editedScores[_EditedHoleKey(playerName: player.name, hole: hole)] ??
        player.holes[hole]?.score;
  }

  Future<void> _editScore({
    required BuildContext context,
    required OcrPlayerScore player,
    required int hole,
  }) async {
    final currentScore = _scoreForPlayerHole(player, hole);
    final controller = TextEditingController(text: currentScore?.toString() ?? '');
    final updatedScore = await showDialog<int?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit ${player.name} - Hole $hole'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Score',
              hintText: 'Enter strokes',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                Navigator.of(dialogContext).pop(parsed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || updatedScore == currentScore) {
      return;
    }

    setState(() {
      _editedScores[_EditedHoleKey(playerName: player.name, hole: hole)] =
          updatedScore;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.scorecard.courseName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.scorecard.topLevelMessages.isNotEmpty) ...[
          _ScorecardWarningsCard(messages: widget.scorecard.topLevelMessages),
          const SizedBox(height: 12),
        ],
        _ScorecardTable(
          scorecard: widget.scorecard,
          scoreForPlayerHole: _scoreForPlayerHole,
          onScoreTap: (player, hole) => _editScore(
            context: context,
            player: player,
            hole: hole,
          ),
        ),
      ],
    );
  }
}

class _EditedHoleKey {
  const _EditedHoleKey({required this.playerName, required this.hole});

  final String playerName;
  final int hole;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _EditedHoleKey &&
        other.playerName == playerName &&
        other.hole == hole;
  }

  @override
  int get hashCode => Object.hash(playerName, hole);
}

class _ScorecardWarningsCard extends StatelessWidget {
  const _ScorecardWarningsCard({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7E0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFF9A6700)),
                SizedBox(width: 8),
                Text(
                  'OCR Warnings / Issues',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A6700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final message in messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $message'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScorecardTable extends StatelessWidget {
  const _ScorecardTable({
    required this.scorecard,
    required this.scoreForPlayerHole,
    required this.onScoreTap,
  });

  final OcrScorecardResponse scorecard;
  final int? Function(OcrPlayerScore player, int hole) scoreForPlayerHole;
  final Future<void> Function(OcrPlayerScore player, int hole) onScoreTap;

  @override
  Widget build(BuildContext context) {
    final headers = [
      'Player',
      for (var hole = 1; hole <= 9; hole++) '$hole',
      'OUT',
      for (var hole = 10; hole <= 18; hole++) '$hole',
      'IN',
      'TOTAL',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: {
          0: const FixedColumnWidth(130),
          for (var col = 1; col < headers.length; col++)
            col: const FixedColumnWidth(50),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFEAF3FF)),
            children: [
              for (final header in headers)
                _TableCell(
                  child: Text(
                    header,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF7FAFC)),
            children: [
              const _TableCell(
                child: Text(
                  'Par',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              for (var hole = 1; hole <= 18; hole++)
                _TableCell(
                  child: Text(
                    scorecard.holes[hole]?.par?.toString() ?? '-',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              _TableCell(
                child: Text(
                  scorecard.parOut?.toString() ?? '-',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _TableCell(
                child: Text(
                  scorecard.parIn?.toString() ?? '-',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _TableCell(
                child: Text(
                  scorecard.parTotal?.toString() ?? '-',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          for (final player in scorecard.players)
            TableRow(
              children: [
                _TableCell(
                  child: Text(
                    player.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                for (var hole = 1; hole <= 18; hole++)
                  _TableCell(
                    child: InkWell(
                      onTap: () => onScoreTap(player, hole),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _displayScore(scoreForPlayerHole(player, hole)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                _TableCell(
                  child: Text(
                    _displayScore(_sumForRange(player, 1, 9)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _TableCell(
                  child: Text(
                    _displayScore(_sumForRange(player, 10, 18)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _TableCell(
                  child: Text(
                    _displayScore(_sumForRange(player, 1, 18)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  int? _sumForRange(OcrPlayerScore player, int start, int end) {
    var hasAny = false;
    var sum = 0;

    for (var hole = start; hole <= end; hole++) {
      final score = scoreForPlayerHole(player, hole);
      if (score == null) {
        continue;
      }
      hasAny = true;
      sum += score;
    }

    return hasAny ? sum : null;
  }

  String _displayScore(int? value) => value?.toString() ?? '-';
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: child,
    );
  }
}
