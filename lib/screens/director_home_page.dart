import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/session_controller.dart';
import '../models/ocr_scorecard_response.dart';
import '../models/tournament.dart';
import '../models/tournament_registration.dart';
import '../services/ocr_service.dart';
import '../services/registration_service.dart';
import '../services/tournament_service.dart';
import '../widgets/footer_link.dart';
import '../widgets/menu_card.dart';
import 'tournament_results_page.dart';
import 'admin_tournament_page.dart';

class SignInHomePage extends StatefulWidget {
  const SignInHomePage({
    required this.sessionController,
    super.key,
  });

  final SessionController sessionController;

  @override
  State<SignInHomePage> createState() => _SignInHomePageState();
}

class _SignInHomePageState extends State<SignInHomePage> {
  static const double _headerBarHeight = 64;
  final OcrService _ocrService = OcrService(useMockData: kDebugMode);
  final TournamentService _tournamentService = TournamentService();
  final RegistrationService _registrationService = RegistrationService();
  bool _isUploadingTestImage = false;

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
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showMenuSelection(BuildContext context, String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$value selected'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await widget.sessionController.signOut();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.sessionController.errorMessage ??
                  'Unable to sign out right now. Please try again.',
            ),
          ),
        );
    }
  }

  Future<void> _handleUploadSelection() async {
    final uploadContext = await _showUploadContextDialog();
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
            children: [
              Text(
                'Tournament: ${uploadContext.tournament.name}',
              ),
              Text('Round: ${uploadContext.roundLabel}'),
              Text('Player: ${uploadContext.registration.playerName}'),
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
              'Uploaded ${uploadContext.tournament.name} (${uploadContext.roundLabel}) for ${uploadContext.registration.playerName}.',
            ),
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
                      (tournament) => tournament.tournamentId == selectedTournament!.tournamentId,
                    )) {
                  selectedTournament = null;
                  selectedRegistration = null;
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: _headerBarHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A2E44), Color(0xFF223F5E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: const Color(0xFF355C84)),
                      ),
                      child: const Text(
                        'WORLDSCORE AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    tooltip: 'Open menu',
                    onSelected: (value) => _showMenuSelection(context, value),
                    color: const Color(0xFF142234),
                    position: PopupMenuPosition.under,
                    offset: const Offset(0, 8),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'Account',
                        child: Text('Account', style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 'Who We Are',
                        child: Text('Who We Are', style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 'FAQ',
                        child: Text('FAQ', style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 'Settings',
                        child: Text('Settings', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    child: Container(
                      height: _headerBarHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF294B6D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: const Icon(Icons.menu, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome back, Director',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFB8C7D6),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _DirectorOverviewCard(),
                      const SizedBox(height: 20),
                      MenuCard(
                        label: 'Leaderboard',
                        subtitle: 'View current and former tournament leaderboards.',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TournamentResultsPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      const MenuCard(
                        label: 'Round History',
                        subtitle: 'Review uploaded scorecards and round history.',
                      ),
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 14),
                      MenuCard(
                        label: 'Admin',
                        subtitle: 'Create, adjust and manage tournament parameters.',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminTournamentPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ListenableBuilder(
                        listenable: widget.sessionController,
                        builder: (context, _) {
                          return FilledButton.icon(
                            onPressed: widget.sessionController.isLoading
                                ? null
                                : () => _signOut(context),
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FooterLink(label: 'How It Works', onTap: () {}),
                          FooterLink(label: 'Help & Support', onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  const OcrScorecardView({super.key, required this.scorecard});

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
      _editedScores[_EditedHoleKey(playerName: player.name, hole: hole)] = updatedScore;
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

class _ScorecardWarningsCard extends StatelessWidget {
  final List<String> messages;

  const _ScorecardWarningsCard({required this.messages});

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
  final OcrScorecardResponse scorecard;
  final int? Function(OcrPlayerScore player, int hole) scoreForPlayerHole;
  final Future<void> Function(OcrPlayerScore player, int hole) onScoreTap;

  const _ScorecardTable({
    required this.scorecard,
    required this.scoreForPlayerHole,
    required this.onScoreTap,
  });

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
          for (var col = 1; col < headers.length; col++) col: const FixedColumnWidth(50),
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
                  'PAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (var hole = 1; hole <= 9; hole++)
                _TableCell(
                  child: Text(
                    _display(scorecard.parByHole[hole]),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              _TableCell(
                child: Text(
                  _sum(scorecard.parByHole, 1, 9),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              for (var hole = 10; hole <= 18; hole++)
                _TableCell(
                  child: Text(
                    _display(scorecard.parByHole[hole]),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              _TableCell(
                child: Text(
                  _sum(scorecard.parByHole, 10, 18),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              _TableCell(
                child: Text(
                  _sum(scorecard.parByHole, 1, 18),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          for (final player in scorecard.players) _playerRow(player),
        ],
      ),
    );
  }

  TableRow _playerRow(OcrPlayerScore player) {
    int? holeScore(int hole) => scoreForPlayerHole(player, hole);
    return TableRow(
      children: [
        _TableCell(
          child: Text(
            player.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        for (var hole = 1; hole <= 9; hole++)
          _holeCell(
            player: player,
            holeNumber: hole,
            holeScore: player.holes[hole],
            displayScore: holeScore(hole),
          ),
        _TableCell(child: Text(_sumPlayerScores(player, 1, 9), textAlign: TextAlign.center)),
        for (var hole = 10; hole <= 18; hole++)
          _holeCell(
            player: player,
            holeNumber: hole,
            holeScore: player.holes[hole],
            displayScore: holeScore(hole),
          ),
        _TableCell(child: Text(_sumPlayerScores(player, 10, 18), textAlign: TextAlign.center)),
        _TableCell(child: Text(_sumPlayerScores(player, 1, 18), textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _holeScoreContent({
    required OcrHoleScore? hole,
    required int? displayScore,
  }) {
    if (displayScore == null) {
      return const Text('-', textAlign: TextAlign.center);
    }

    if (hole?.isLowConfidence != true) {
      return Text('$displayScore', textAlign: TextAlign.center);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$displayScore',
          style: const TextStyle(
            color: Color(0xFF9A6700),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.warning_amber_rounded,
          size: 14,
          color: Color(0xFF9A6700),
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
      color: holeScore?.isLowConfidence == true ? const Color(0xFFFFF4DB) : null,
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
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _DirectorOverviewCard extends StatelessWidget {
  const _DirectorOverviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF142234),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F3A56)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Director Overview',
            style: TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 14),
          _DirectorInfoRow(label: 'Name', value: 'Dalton Stout'),
          SizedBox(height: 8),
          _DirectorInfoRow(label: 'Club', value: 'Club Campestre el Rodeo'),
          SizedBox(height: 8),
          _DirectorInfoRow(label: 'Association', value: 'Federación Colombiana de Golf'),
        ],
      ),
    );
  }
}

class _DirectorInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DirectorInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: const TextStyle(
          color: Color(0xFF9FB3C8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
