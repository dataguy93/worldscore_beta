import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ocr_scorecard_response.dart';
import '../models/tournament.dart';
import '../models/tournament_registration.dart';
import '../services/ocr_service.dart';
import '../services/player_score_upload_service.dart';
import '../services/registration_service.dart';
import '../services/tournament_service.dart';
import 'menu_card.dart';

class DirectorUploadWidget extends StatelessWidget {
  const DirectorUploadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _UploadWidget(
      requiresUploadContext: true,
      subtitle: 'Scan and upload scorecards as players finish each day.',
      menuBackgroundColor: Color(0xFF093823),
      menuBorderColor: Color(0xFF137A48),
      menuTitleColor: Color(0xFF3CE081),
      menuSubtitleColor: Color(0xFF7EA699),
      menuIcon: Icons.upload_file_rounded,
      menuBorderRadius: 24,
      menuMinHeight: 100.8,
      menuTitleFontSize: 24,
      menuPadding: EdgeInsets.all(18),
    );
  }
}

class PlayerUploadWidget extends StatelessWidget {
  const PlayerUploadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _UploadWidget(
      requiresUploadContext: false,
      subtitle: 'Submit a new scorecard using AI OCR.',
    );
  }
}

class _UploadWidget extends StatefulWidget {
  const _UploadWidget({
    required this.requiresUploadContext,
    required this.subtitle,
    this.menuBackgroundColor = const Color(0xFF142234),
    this.menuBorderColor = const Color(0xFF1F3A56),
    this.menuTitleColor = const Color(0xFF4FC3F7),
    this.menuSubtitleColor = const Color(0xFF9FB3C8),
    this.menuIcon,
    this.menuBorderRadius = 12,
    this.menuPadding = const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    this.menuTitleFontSize = 18,
    this.menuMinHeight,
  });

  final bool requiresUploadContext;
  final String subtitle;
  final Color menuBackgroundColor;
  final Color menuBorderColor;
  final Color menuTitleColor;
  final Color menuSubtitleColor;
  final IconData? menuIcon;
  final double menuBorderRadius;
  final EdgeInsetsGeometry menuPadding;
  final double menuTitleFontSize;
  final double? menuMinHeight;

  @override
  State<_UploadWidget> createState() => _UploadWidgetState();
}

class _UploadWidgetState extends State<_UploadWidget> {
  final OcrService _ocrService = OcrService(useMockData: kDebugMode);
  final TournamentService _tournamentService = TournamentService();
  final RegistrationService _registrationService = RegistrationService();
  bool _isUploadingTestImage = false;

  void _showOcrResults(
    OcrScorecardResponse scorecard, {
    _UploadSelectionContext? uploadContext,
  }) {
    final scorecardViewKey = GlobalKey<_OcrScorecardViewState>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            decoration: BoxDecoration(
              color: const Color(0xFF05162F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF1B3C69)),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: OcrScorecardView(
                      key: scorecardViewKey,
                      scorecard: scorecard,
                      uploadContext: uploadContext,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        showDialog<void>(
                          context: dialogContext,
                          builder: (jsonDialogContext) {
                            return AlertDialog(
                              title: const Text('Raw OCR JSON'),
                              content: SingleChildScrollView(
                                child: SelectableText(
                                  const JsonEncoder.withIndent('  ').convert(scorecard.toJson()),
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
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final didUpload =
                            await scorecardViewKey.currentState?.confirmSelectedPlayer();
                        if (didUpload == true && dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      child: const Text('Confirm Picture'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleUploadSelection({
    required bool requiresUploadContext,
  }) async {
    final uploadContext = requiresUploadContext ? await _showUploadContextDialog() : null;
    if (requiresUploadContext && uploadContext == null) {
      return;
    }

    final didConfirmUpload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Preview scorecard upload'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tournament: ${uploadContext?.tournament.name ?? 'Your active tournament'}',
              ),
              Text('Round: ${uploadContext?.roundLabel ?? 'Current round'}'),
              Text('Player: ${uploadContext?.registration.playerName ?? 'You'}'),
              const SizedBox(height: 12),
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              uploadContext == null
                  ? 'Scorecard image confirmed. Review results before saving.'
                  : 'Image confirmed for ${uploadContext.tournament.name} (${uploadContext.roundLabel}) - ${uploadContext.registration.playerName}. Review results before saving.',
            ),
          ),
        );

      _showOcrResults(
        scorecard,
        uploadContext: uploadContext,
      );
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

                if (selectedTournament != null) {
                  final matchingIndex = tournaments.indexWhere(
                    (tournament) =>
                        tournament.tournamentId == selectedTournament!.tournamentId,
                  );

                  if (matchingIndex == -1) {
                    selectedTournament = null;
                    selectedRegistration = null;
                  } else {
                    selectedTournament = tournaments[matchingIndex];
                  }
                }

                final registrationStream = selectedTournament == null
                    ? null
                    : _registrationService.streamRegistrants(selectedTournament!.tournamentId);

                return AlertDialog(
                  title: const Text('Select scorecard upload details'),
                  content: SizedBox(
                    width: 480,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Before uploading, choose the tournament, registered player, and round.',
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
                                    selectedRegistration = null;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<TournamentRegistration>>(
                          stream: registrationStream,
                          builder: (context, registrationSnapshot) {
                            final registrations =
                                registrationSnapshot.data ?? const <TournamentRegistration>[];

                            if (selectedRegistration != null) {
                              final matchingIndex = registrations.indexWhere(
                                (registration) =>
                                    registration.registrationId ==
                                    selectedRegistration!.registrationId,
                              );

                              selectedRegistration =
                                  matchingIndex == -1 ? null : registrations[matchingIndex];
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
                                    (registration) => DropdownMenuItem<TournamentRegistration>(
                                      value: registration,
                                      child: Text(
                                        registration.playerName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (selectedTournament == null || registrations.isEmpty)
                                  ? null
                                  : (value) {
                                      setDialogState(() {
                                        selectedRegistration = value;
                                      });
                                    },
                            );
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
                                  tournament: selectedTournament!,
                                  round: selectedRound!,
                                  registration: selectedRegistration!,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MenuCard(
          label: 'Upload',
          subtitle: widget.subtitle,
          backgroundColor: widget.menuBackgroundColor,
          borderColor: widget.menuBorderColor,
          titleColor: widget.menuTitleColor,
          subtitleColor: widget.menuSubtitleColor,
          icon: widget.menuIcon,
          borderRadius: widget.menuBorderRadius,
          minHeight: widget.menuMinHeight,
          padding: widget.menuPadding,
          titleFontSize: widget.menuTitleFontSize,
          onTap: _isUploadingTestImage
              ? null
              : () => _handleUploadSelection(
                    requiresUploadContext: widget.requiresUploadContext,
                  ),
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
    required this.tournament,
    required this.round,
    required this.registration,
  });

  final Tournament tournament;
  final int round;
  final TournamentRegistration registration;

  String get roundLabel => 'Round $round';
}

class OcrScorecardView extends StatefulWidget {
  final OcrScorecardResponse scorecard;
  final _UploadSelectionContext? uploadContext;

  const OcrScorecardView({
    super.key,
    required this.scorecard,
    this.uploadContext,
  });

  @override
  State<OcrScorecardView> createState() => _OcrScorecardViewState();
}

class _OcrScorecardViewState extends State<OcrScorecardView> {
  final Map<_EditedHoleKey, int?> _editedScores = {};
  final PlayerScoreUploadService _playerScoreUploadService = PlayerScoreUploadService();
  String? _selectedMePlayerName;
  late String _courseName;

  @override
  void initState() {
    super.initState();
    _courseName = widget.scorecard.courseName;
  }

  int? _scoreForPlayerHole(OcrPlayerScore player, int hole) {
    return _editedScores[_EditedHoleKey(playerName: player.name, hole: hole)] ??
        player.holes[hole]?.score;
  }

  void _toggleMePlayer(String playerName) {
    setState(() {
      _selectedMePlayerName = _selectedMePlayerName == playerName ? null : playerName;
    });
  }

  Future<bool> confirmSelectedPlayer() async {
    final selectedPlayerName = _selectedMePlayerName;
    if (selectedPlayerName == null) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Select the player marked as Me before confirming.')),
        );
      return false;
    }

    final selectedPlayer = widget.scorecard.players.firstWhere(
      (player) => player.name == selectedPlayerName,
      orElse: () => throw StateError('Selected player not found in scorecard.'),
    );

    final scoresByHole = <int, int?>{
      for (var hole = 1; hole <= 18; hole++) hole: _scoreForPlayerHole(selectedPlayer, hole),
    };

    try {
      await _playerScoreUploadService.uploadMeScore(
        playerName: selectedPlayer.name,
        scoresByHole: scoresByHole,
        courseName: _courseName,
        tournamentId: widget.uploadContext?.tournament.tournamentId,
        round: widget.uploadContext?.round,
        registrationId: widget.uploadContext?.registration.registrationId,
      );
      if (!mounted) {
        return false;
      }
      final uploadContext = widget.uploadContext;
      final successMessage = uploadContext == null
          ? 'Saved ${selectedPlayer.name} score to your profile.'
          : 'Saved ${selectedPlayer.name} ${uploadContext.roundLabel} score for ${uploadContext.tournament.name}.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not save score: $error')),
        );
      return false;
    }
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
      _editedScores[_EditedHoleKey(playerName: player.name, hole: hole)] = updatedScore;
    });
  }

  Future<void> _editCourseName() async {
    final controller = TextEditingController(text: _courseName);
    final updatedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update course name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Course name',
              hintText: 'Enter course name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || updatedName == null || updatedName.isEmpty || updatedName == _courseName) {
      return;
    }

    setState(() {
      _courseName = updatedName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071937),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1B3C69)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Rounds',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD7E4F7),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF05162F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2D7C2F), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'COURSE',
                        style: TextStyle(
                          color: Color(0xFF72D981),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _editCourseName,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        foregroundColor: const Color(0xFF58C2FF),
                        side: const BorderSide(color: Color(0xFF2A78B8)),
                        backgroundColor: const Color(0xFF12325A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _courseName.toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFD7E4F7),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ScorecardTable(
            scorecard: widget.scorecard,
            scoreForPlayerHole: _scoreForPlayerHole,
            selectedMePlayerName: _selectedMePlayerName,
            onMePlayerToggled: _toggleMePlayer,
            onScoreTap: (player, hole) => _editScore(
              context: context,
              player: player,
              hole: hole,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditedHoleKey {
  final String playerName;
  final int hole;

  const _EditedHoleKey({required this.playerName, required this.hole});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _EditedHoleKey && other.playerName == playerName && other.hole == hole;
  }

  @override
  int get hashCode => Object.hash(playerName, hole);
}

class _ScorecardTable extends StatelessWidget {
  final OcrScorecardResponse scorecard;
  final int? Function(OcrPlayerScore player, int hole) scoreForPlayerHole;
  final String? selectedMePlayerName;
  final ValueChanged<String> onMePlayerToggled;
  final Future<void> Function(OcrPlayerScore player, int hole) onScoreTap;

  const _ScorecardTable({
    required this.scorecard,
    required this.scoreForPlayerHole,
    required this.selectedMePlayerName,
    required this.onMePlayerToggled,
    required this.onScoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final headers = [
      'HOLE',
      for (var hole = 1; hole <= 9; hole++) '$hole',
      'OUT',
      for (var hole = 10; hole <= 18; hole++) '$hole',
      'IN',
      'TOTAL',
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFF244A7A), width: 1),
            verticalInside: BorderSide(color: Color(0xFF244A7A), width: 1),
            top: BorderSide(color: Color(0xFF2D5A91), width: 1.2),
            left: BorderSide(color: Color(0xFF2D5A91), width: 1.2),
            right: BorderSide(color: Color(0xFF2D5A91), width: 1.2),
            bottom: BorderSide(color: Color(0xFF2D5A91), width: 1.2),
          ),
          columnWidths: {
            0: const FixedColumnWidth(128),
            for (var col = 1; col < headers.length; col++) col: const FixedColumnWidth(49),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF081A35)),
              children: [
                for (final header in headers)
                  _TableCell(
                    color: header == 'OUT' || header == 'IN' || header == 'TOTAL'
                        ? const Color(0xFF0D2A1A)
                        : null,
                    child: Text(
                      header,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: header == 'OUT' || header == 'IN' || header == 'TOTAL'
                            ? const Color(0xFF67CC70)
                            : const Color(0xFF8FAECC),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF0A1D3C)),
              children: [
                const _TableCell(
                  child: Text(
                    'Par',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFFCC2D)),
                  ),
                ),
                for (var hole = 1; hole <= 9; hole++)
                  _TableCell(
                    child: Text(
                      _display(scorecard.parByHole[hole]),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFCC2D),
                      ),
                    ),
                  ),
                _TableCell(
                  color: const Color(0xFF0D2A1A),
                  child: Text(
                    _sum(scorecard.parByHole, 1, 9),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFFCC2D)),
                  ),
                ),
                for (var hole = 10; hole <= 18; hole++)
                  _TableCell(
                    child: Text(
                      _display(scorecard.parByHole[hole]),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFCC2D),
                      ),
                    ),
                  ),
                _TableCell(
                  color: const Color(0xFF0D2A1A),
                  child: Text(
                    _sum(scorecard.parByHole, 10, 18),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFFCC2D)),
                  ),
                ),
                _TableCell(
                  color: const Color(0xFF0D2A1A),
                  child: Text(
                    _sum(scorecard.parByHole, 1, 18),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFFCC2D)),
                  ),
                ),
              ],
            ),
            for (final player in scorecard.players) _playerRow(player),
          ],
        ),
      ),
    );
  }

  TableRow _playerRow(OcrPlayerScore player) {
    int? holeScore(int hole) => scoreForPlayerHole(player, hole);
    final isMePlayer = selectedMePlayerName == player.name;
    return TableRow(
      children: [
        _TableCell(
          color: const Color(0xFF0B1E3E),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  player.name.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF57C9FF),
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              FilterChip(
                label: Text(
                  isMePlayer ? '✓ ME' : 'Me?',
                  style: TextStyle(
                    color: isMePlayer ? const Color(0xFF8CEB8C) : const Color(0xFF89A2C0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: isMePlayer,
                onSelected: (_) => onMePlayerToggled(player.name),
                visualDensity: VisualDensity.compact,
                selectedColor: const Color(0xFF1A5F1D),
                backgroundColor: const Color(0xFF112B4E),
                side: BorderSide(
                  color: isMePlayer ? const Color(0xFF38A93B) : const Color(0xFF42678F),
                ),
              ),
            ],
          ),
        ),
        for (var hole = 1; hole <= 9; hole++)
          _holeCell(
            player: player,
            holeNumber: hole,
            holeScore: player.holes[hole],
            displayScore: holeScore(hole),
          ),
        _TableCell(
          color: const Color(0xFF0D2A1A),
          child: Text(
            _sumPlayerScores(player, 1, 9),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF67CC70), fontWeight: FontWeight.w800),
          ),
        ),
        for (var hole = 10; hole <= 18; hole++)
          _holeCell(
            player: player,
            holeNumber: hole,
            holeScore: player.holes[hole],
            displayScore: holeScore(hole),
          ),
        _TableCell(
          color: const Color(0xFF0D2A1A),
          child: Text(
            _sumPlayerScores(player, 10, 18),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF67CC70), fontWeight: FontWeight.w800),
          ),
        ),
        _TableCell(
          color: const Color(0xFF0D2A1A),
          child: Text(
            _sumPlayerScores(player, 1, 18),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF67CC70), fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _holeScoreContent({
    required OcrHoleScore? hole,
    required int? displayScore,
  }) {
    if (displayScore == null) {
      return const Text('-', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6E8CAE)));
    }

    if (hole?.isLowConfidence != true) {
      return Text(
        '$displayScore',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFD6E1F1), fontWeight: FontWeight.w700),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$displayScore',
          style: const TextStyle(
            color: Color(0xFFFFCF66),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.warning_amber_rounded,
          size: 14,
          color: Color(0xFFFFCF66),
        ),
      ],
    );
  }

  _TableCell _holeCell({
    required OcrPlayerScore player,
    required int holeNumber,
    required OcrHoleScore? holeScore,
    required int? displayScore,
  }) {
    return _TableCell(
      color: holeScore?.isLowConfidence == true
          ? const Color(0xFF4B3612)
          : const Color(0xFF102447),
      child: InkWell(
        onTap: () => onScoreTap(player, holeNumber),
        child: _holeScoreContent(hole: holeScore, displayScore: displayScore),
      ),
    );
  }

  String _sumPlayerScores(OcrPlayerScore player, int start, int end) {
    var hasValue = false;
    var total = 0;
    for (var hole = start; hole <= end; hole++) {
      final value = scoreForPlayerHole(player, hole);
      if (value != null) {
        hasValue = true;
        total += value;
      }
    }
    return hasValue ? '$total' : '-';
  }

  static String _display(int? value) => value?.toString() ?? '-';

  static String _sum(Map<int, int?> values, int start, int end) {
    var hasValue = false;
    var total = 0;
    for (var hole = start; hole <= end; hole++) {
      final value = values[hole];
      if (value != null) {
        hasValue = true;
        total += value;
      }
    }
    return hasValue ? '$total' : '-';
  }
}

class _TableCell extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _TableCell({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? const Color(0xFF102447),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: Alignment.center,
      child: child,
    );
  }
}
