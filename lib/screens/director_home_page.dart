import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../widgets/footer_link.dart';
import '../widgets/menu_card.dart';
import 'player_home_page.dart';
import 'tournament_results_page.dart';

class SignInHomePage extends StatefulWidget {
  const SignInHomePage({super.key});

  @override
  State<SignInHomePage> createState() => _SignInHomePageState();
}

class _SignInHomePageState extends State<SignInHomePage> {
  static final Uri _ocrServiceUri = Uri.parse(
    'https://worldscore-985255509017.us-east1.run.app/ocr',
  );

  static const double _headerBarHeight = 64;
  bool _isUploadingTestImage = false;

  Future<Map<String, dynamic>> _fetchScorecardResults(
    Uint8List imageData,
    String fileName,
  ) async {
    final request = http.MultipartRequest('POST', _ocrServiceUri)
      ..headers['Accept'] = 'application/json'
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageData,
          filename: fileName,
        ),
      );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
      throw Exception(
        'OCR request failed (${streamedResponse.statusCode}): $responseBody',
      );
    }

    final decodedBody = jsonDecode(responseBody);
    if (decodedBody is Map<String, dynamic>) {
      return decodedBody;
    }

    if (decodedBody is Map) {
      return Map<String, dynamic>.from(decodedBody);
    }

    return {'result': decodedBody};
  }

  void _showOcrResults(Map<String, dynamic> results) {
    final scorecard = OcrScorecardResponse.fromJson(results);
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
                          const JsonEncoder.withIndent('  ').convert(results),
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

  Route<void> _buildSlideFromLeftRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1, 0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  Future<void> _handleUploadSelection() async {
    final didConfirmUpload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Preview scorecard upload'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
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
      final results = await _fetchScorecardResults(
        imageBytes.buffer.asUint8List(),
        fileName,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Test scorecard sent to OCR service and scores were pulled successfully.',
            ),
          ),
        );

      _showOcrResults(results);
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
                      const MenuCard(
                        label: 'Admin',
                        subtitle: 'Create, adjust and manage tournament paramaters.',
                      ),
                      const SizedBox(height: 16),
                      _ProfileSwitchCard(
                        selectedRole: 'Director',
                        onRoleChanged: (role) {
                          if (role == 'Player') {
                            Navigator.of(context).pushReplacement(
                              _buildSlideFromLeftRoute(const PlayerSignInHomePage()),
                            );
                          }
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

class OcrScorecardResponse {
  final String courseName;
  final List<String> warnings;
  final List<String> issues;
  final Map<int, int?> parByHole;
  final List<OcrPlayerScore> players;

  const OcrScorecardResponse({
    required this.courseName,
    required this.warnings,
    required this.issues,
    required this.parByHole,
    required this.players,
  });

  List<String> get topLevelMessages => [...warnings, ...issues];

  factory OcrScorecardResponse.fromJson(Map<String, dynamic> json) {
    final players = _parsePlayers(json);
    final parByHole = _parseParByHole(json, players);

    return OcrScorecardResponse(
      courseName: _firstString(
            json,
            const ['course_name', 'courseName', 'course', 'course_title'],
          ) ??
          'Unknown Course',
      warnings: _parseMessageList(json, 'warnings'),
      issues: _parseMessageList(json, 'issues') +
          _parseMessageList(json, 'top_level_issues'),
      parByHole: parByHole,
      players: players,
    );
  }

  static List<OcrPlayerScore> _parsePlayers(Map<String, dynamic> json) {
    final dynamic rawPlayers =
        json['players'] ?? json['player_scores'] ?? json['scores'];
    if (rawPlayers is List) {
      return rawPlayers
          .whereType<Map>()
          .map((player) =>
              OcrPlayerScore.fromJson(Map<String, dynamic>.from(player)))
          .toList();
    }
    return const [];
  }

  static Map<int, int?> _parseParByHole(
    Map<String, dynamic> json,
    List<OcrPlayerScore> players,
  ) {
    final Map<int, int?> output = {for (var hole = 1; hole <= 18; hole++) hole: null};
    final dynamic rawPars = json['par'] ?? json['pars'] ?? json['par_by_hole'];

    if (rawPars is Map) {
      for (final entry in rawPars.entries) {
        final hole = int.tryParse('${entry.key}');
        if (hole != null && hole >= 1 && hole <= 18) {
          output[hole] = _toInt(entry.value);
        }
      }
    } else if (rawPars is List) {
      for (var i = 0; i < rawPars.length && i < 18; i++) {
        output[i + 1] = _toInt(rawPars[i]);
      }
    }

    for (final player in players) {
      for (final holeEntry in player.holes.entries) {
        if (output[holeEntry.key] != null) {
          continue;
        }
        final inferredPar = holeEntry.value.par;
        if (inferredPar != null) {
          output[holeEntry.key] = inferredPar;
        }
      }
    }

    return output;
  }
}

class OcrPlayerScore {
  final String name;
  final Map<int, OcrHoleScore> holes;
  final int? front9Total;
  final int? back9Total;
  final int? grossTotal;

  const OcrPlayerScore({
    required this.name,
    required this.holes,
    required this.front9Total,
    required this.back9Total,
    required this.grossTotal,
  });

  factory OcrPlayerScore.fromJson(Map<String, dynamic> json) {
    final parsedHoles = <int, OcrHoleScore>{};
    final dynamic rawHoles = json['holes'];

    if (rawHoles is Map) {
      var fallbackHoleNumber = 1;
      for (final entry in rawHoles.entries) {
        final hole =
            _parseHoleNumber(entry.key) ?? _parseHoleNumber(entry.value) ?? fallbackHoleNumber;
        if (hole == null || hole < 1 || hole > 18) {
          continue;
        }
        if (entry.value is Map) {
          parsedHoles[hole] = OcrHoleScore.fromJson(
            Map<String, dynamic>.from(entry.value),
            fallbackHole: hole,
          );
        } else {
          parsedHoles[hole] = OcrHoleScore(score: _toInt(entry.value));
        }

        if (hole >= fallbackHoleNumber) {
          fallbackHoleNumber = hole + 1;
        }
      }
    } else if (rawHoles is List) {
      for (var index = 0; index < rawHoles.length; index++) {
        final item = rawHoles[index];
        if (item is Map) {
          final hole = _toInt(item['hole']) ??
              _toInt(item['hole_number']) ??
              _toInt(item['number']) ??
              _parseHoleNumber(item) ??
              (index + 1);
          if (hole < 1 || hole > 18) {
            continue;
          }
          parsedHoles[hole] = OcrHoleScore.fromJson(
            Map<String, dynamic>.from(item),
            fallbackHole: hole,
          );
          continue;
        }
        final hole = index + 1;
        if (hole < 1 || hole > 18) {
          continue;
        }
        parsedHoles[hole] = OcrHoleScore(score: _toInt(item));
      }
    } else if (rawHoles is String) {
      final values = rawHoles.split(RegExp(r'[\s,|;/]+')).where((value) => value.isNotEmpty);
      var hole = 1;
      for (final value in values) {
        if (hole > 18) {
          break;
        }
        parsedHoles[hole] = OcrHoleScore(score: _toInt(value));
        hole += 1;
      }
    }

    return OcrPlayerScore(
      name: (json['player'] ?? json['name'] ?? json['player_name'] ?? 'Unknown Player')
          .toString(),
      holes: parsedHoles,
      front9Total: _toInt(json['front_9_total'] ?? json['out'] ?? json['front9']),
      back9Total: _toInt(json['back_9_total'] ?? json['in'] ?? json['back9']),
      grossTotal: _toInt(json['gross_total'] ?? json['total']),
    );
  }
}

class OcrHoleScore {
  final int? score;
  final int? par;
  final String? confidenceLevel;
  final double? confidence;

  const OcrHoleScore({
    required this.score,
    this.par,
    this.confidenceLevel,
    this.confidence,
  });

  bool get isLowConfidence {
    final normalized = confidenceLevel?.toLowerCase();
    if (normalized != null &&
        (normalized == 'low' || normalized == 'weak' || normalized == 'uncertain')) {
      return true;
    }
    return (confidence ?? 1) < 0.6;
  }

  factory OcrHoleScore.fromJson(
    Map<String, dynamic> json, {
    int? fallbackHole,
  }) {
    final score = _toInt(
      json['score'] ??
          json['strokes'] ??
          json['value'] ??
          json['gross'] ??
          json['player_score'] ??
          json['ocr_score'],
    );

    int? inferredScore = score;
    if (inferredScore == null) {
      inferredScore = _inferScoreFromUnknownShape(json, fallbackHole: fallbackHole);
    }

    return OcrHoleScore(
      score: inferredScore,
      par: _toInt(json['par']),
      confidenceLevel: _toNullableString(
        json['confidence_level'] ?? json['confidenceLevel'],
      ),
      confidence: _toDouble(json['confidence'] ?? json['score_confidence']),
    );
  }
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

List<String> _parseMessageList(Map<String, dynamic> json, String key) {
  final dynamic raw = json[key];
  if (raw is List) {
    return raw
        .map((item) {
          if (item is String) {
            return item;
          }
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            return _toNullableString(map['message'] ?? map['text']) ??
                const JsonEncoder().convert(map);
          }
          return item.toString();
        })
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
  if (raw is String && raw.trim().isNotEmpty) {
    return [raw];
  }
  return const [];
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _toNullableString(json[key]);
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String? _toNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _toInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

int? _parseHoleNumber(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    return _toInt(map['hole']) ??
        _toInt(map['hole_number']) ??
        _toInt(map['number']) ??
        _parseHoleNumber(map['label']) ??
        _parseHoleNumber(map['key']);
  }

  final text = value.toString();
  final direct = int.tryParse(text);
  if (direct != null) {
    return direct;
  }

  final match = RegExp(r'(\d{1,2})').firstMatch(text);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

int? _inferScoreFromUnknownShape(
  Map<String, dynamic> json, {
  int? fallbackHole,
}) {
  final ignoredKeys = <String>{
    'hole',
    'hole_number',
    'number',
    'par',
    'confidence',
    'confidence_level',
    'confidenceLevel',
    'score_confidence',
    if (fallbackHole != null) '$fallbackHole',
  };

  for (final entry in json.entries) {
    if (ignoredKeys.contains(entry.key)) {
      continue;
    }
    final parsed = _toInt(entry.value);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

class _ProfileSwitchCard extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const _ProfileSwitchCard({
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF142234),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F3A56)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Switch Profile View',
            style: TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use this toggle if you have both player and director profiles.',
            style: TextStyle(
              color: Color(0xFF9FB3C8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: 'Player', label: Text('Player')),
              ButtonSegment<String>(value: 'Director', label: Text('Director')),
            ],
            selected: {selectedRole},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onRoleChanged(selection.first),
          ),
        ],
      ),
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
