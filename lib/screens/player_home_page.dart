import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/session_controller.dart';
import '../models/ocr_scorecard_response.dart';
import '../services/ocr_service.dart';
import '../widgets/footer_link.dart';
import '../widgets/menu_card.dart';

class PlayerSignInHomePage extends StatefulWidget {
  const PlayerSignInHomePage({
    required this.sessionController,
    super.key,
  });

  static const double _headerBarHeight = 64;
  final SessionController sessionController;

  @override
  State<PlayerSignInHomePage> createState() => _PlayerSignInHomePageState();
}

class _PlayerSignInHomePageState extends State<PlayerSignInHomePage> {
  final OcrService _ocrService = OcrService(useMockData: kDebugMode);
  bool _isUploadingTestImage = false;

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

  void _showOcrResults(OcrScorecardResponse scorecard) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('OCR score extraction complete'),
          content: SizedBox(
            width: 1000,
            child: SingleChildScrollView(
              child: _PlayerOcrScorecardView(scorecard: scorecard),
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
    final didConfirmUpload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Preview scorecard upload'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'In production, this will come from the camera. For now, this test image will be uploaded.',
              ),
              SizedBox(height: 12),
              ClipRRect(
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

      final displayName = widget.sessionController.profile?.displayName.trim();
      final playerName =
          (displayName == null || displayName.isEmpty) ? 'Player' : displayName;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Uploaded scorecard for $playerName.'),
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

  @override
  Widget build(BuildContext context) {
    final displayName = widget.sessionController.profile?.displayName.trim();
    final snapshotName =
        (displayName == null || displayName.isEmpty) ? 'Player' : displayName;

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
                      height: PlayerSignInHomePage._headerBarHeight,
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
                      height: PlayerSignInHomePage._headerBarHeight,
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
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFB8C7D6),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _PlayerOverviewCard(displayName: snapshotName),
                      const SizedBox(height: 20),
                      const MenuCard(
                        label: 'Leaderboard',
                        subtitle: 'See current and former tournament standings.',
                      ),
                      const SizedBox(height: 14),
                      const MenuCard(
                        label: 'Round History',
                        subtitle: 'Review your round history and submitted scorecards.',
                      ),
                      const SizedBox(height: 14),
                      MenuCard(
                        label: 'Upload',
                        subtitle: 'Submit a new scorecard using AI OCR.',
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

class _PlayerOverviewCard extends StatelessWidget {
  const _PlayerOverviewCard({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF142234),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F3A56)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Player Snapshot',
            style: TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 112,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A4D70)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: Color(0xFF7FA6C9), size: 28),
                      SizedBox(height: 8),
                      Text(
                        'Upload photo',
                        style: TextStyle(
                          color: Color(0xFF9FB3C8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PlayerInfoRow(label: 'Name', value: displayName),
                    const SizedBox(height: 8),
                    const _PlayerInfoRow(label: 'Rounds this year', value: '15'),
                    const SizedBox(height: 8),
                    const _PlayerInfoRow(label: 'Average score', value: '86.1'),
                    const SizedBox(height: 8),
                    const _PlayerInfoRow(label: 'Handicap', value: '12.6'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _PlayerInfoRow({required this.label, required this.value});

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

class _PlayerOcrScorecardView extends StatefulWidget {
  const _PlayerOcrScorecardView({required this.scorecard});

  final OcrScorecardResponse scorecard;

  @override
  State<_PlayerOcrScorecardView> createState() => _PlayerOcrScorecardViewState();
}

class _PlayerOcrScorecardViewState extends State<_PlayerOcrScorecardView> {
  final Map<_PlayerEditedHoleKey, int?> _editedScores = {};

  int? _scoreForPlayerHole(OcrPlayerScore player, int hole) {
    return _editedScores[_PlayerEditedHoleKey(playerName: player.name, hole: hole)] ??
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
      _editedScores[_PlayerEditedHoleKey(playerName: player.name, hole: hole)] = updatedScore;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scorecard = widget.scorecard;
    final players = scorecard.players;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (scorecard.courseName != null && scorecard.courseName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Course: ${scorecard.courseName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        if (scorecard.roundDate != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('Date: ${scorecard.roundDate}'),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Player')),
              for (var hole = 1; hole <= 18; hole++) DataColumn(label: Text('H$hole')),
              const DataColumn(label: Text('Total')),
            ],
            rows: players
                .map(
                  (player) => DataRow(
                    cells: [
                      DataCell(Text(player.name)),
                      for (var hole = 1; hole <= 18; hole++)
                        DataCell(
                          InkWell(
                            onTap: () => _editScore(
                              context: context,
                              player: player,
                              hole: hole,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                _scoreForPlayerHole(player, hole)?.toString() ?? '-',
                                style: const TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      DataCell(
                        Text(
                          List<int>.generate(18, (index) => index + 1)
                              .map((hole) => _scoreForPlayerHole(player, hole))
                              .whereType<int>()
                              .fold<int>(0, (sum, score) => sum + score)
                              .toString(),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PlayerEditedHoleKey {
  const _PlayerEditedHoleKey({required this.playerName, required this.hole});

  final String playerName;
  final int hole;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PlayerEditedHoleKey &&
        other.playerName == playerName &&
        other.hole == hole;
  }

  @override
  int get hashCode => Object.hash(playerName, hole);
}
