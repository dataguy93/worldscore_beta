import 'dart:convert';
import 'dart:collection';
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
    final playerName = _extractPlayerName(results);
    final holeScores = _extractHoleScores(results);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101F31),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'OCR score extraction complete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 780,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 170,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF142234),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1F3A56)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Player',
                        style: TextStyle(
                          color: Color(0xFF9FB3C8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        playerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (holeScores.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Holes parsed',
                          style: TextStyle(
                            color: Color(0xFF9FB3C8),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${holeScores.length}',
                          style: const TextStyle(
                            color: Color(0xFF4FC3F7),
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF142234),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1F3A56)),
                    ),
                    child: holeScores.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'No hole-by-hole scores were detected from OCR yet. Please try uploading a clearer scorecard.',
                              style: TextStyle(
                                color: Color(0xFFB8C7D6),
                                height: 1.35,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: const Color(0xFF294B6D),
                              ),
                              child: DataTable(
                                headingTextStyle: const TextStyle(
                                  color: Color(0xFFB8C7D6),
                                  fontWeight: FontWeight.w600,
                                ),
                                dataTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFF0F1E2E),
                                ),
                                dataRowColor: WidgetStateProperty.all(
                                  const Color(0xFF162A3F),
                                ),
                                columns: [
                                  const DataColumn(
                                    label: Text('Type'),
                                  ),
                                  ...holeScores.map(
                                    (entry) => DataColumn(
                                      label: Text('H${entry.hole}'),
                                    ),
                                  ),
                                ],
                                rows: [
                                  DataRow(
                                    cells: [
                                      const DataCell(Text('Par')),
                                      ...holeScores
                                          .map((entry) => DataCell(Text('${entry.par}'))),
                                    ],
                                  ),
                                  DataRow(
                                    cells: [
                                      const DataCell(Text('Score')),
                                      ...holeScores
                                          .map((entry) => DataCell(Text('${entry.score}'))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _extractPlayerName(Map<String, dynamic> results) {
    final candidate = results['playerName'] ??
        results['player_name'] ??
        results['name'] ??
        results['golfer_name'];
    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate;
    }

    final player = results['player'];
    if (player is Map) {
      final map = Map<String, dynamic>.from(player);
      final nestedCandidate = map['name'] ?? map['playerName'] ?? map['player_name'];
      if (nestedCandidate is String && nestedCandidate.trim().isNotEmpty) {
        return nestedCandidate;
      }
    }

    return 'Unknown player';
  }

  List<_HoleScoreEntry> _extractHoleScores(Map<String, dynamic> results) {
    final entriesByHole = LinkedHashMap<int, _HoleScoreEntry>();
    for (final entry in _collectHoleEntries(results)) {
      entriesByHole[entry.hole] = entry;
    }

    final entries = entriesByHole.values.toList(growable: false)
      ..sort((a, b) => a.hole.compareTo(b.hole));
    return entries;
  }

  Iterable<_HoleScoreEntry> _collectHoleEntries(dynamic source) sync* {
    final directEntry = _parseHoleEntry(source);
    if (directEntry != null) {
      yield directEntry;
    }

    if (source is List) {
      for (final item in source) {
        yield* _collectHoleEntries(item);
      }
    }

    if (source is Map) {
      final map = Map<String, dynamic>.from(source);
      for (final entry in map.entries) {
        if (entry.value is Map) {
          final valueMap = Map<String, dynamic>.from(entry.value as Map);
          valueMap.putIfAbsent('hole', () => entry.key);
          yield* _collectHoleEntries(valueMap);
        } else {
          yield* _collectHoleEntries(entry.value);
        }
      }
    }
  }

  _HoleScoreEntry? _parseHoleEntry(dynamic rawEntry) {
    if (rawEntry is! Map) {
      return null;
    }

    final entry = Map<String, dynamic>.from(rawEntry);
    final hole = _parseInt(entry['hole'] ?? entry['hole_number'] ?? entry['number']);
    final par = _parseInt(entry['par']);
    final score = _parseInt(entry['score'] ?? entry['strokes']);

    if (hole == null || par == null || score == null) {
      return null;
    }

    return _HoleScoreEntry(hole: hole, par: par, score: score);
  }

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
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

class _HoleScoreEntry {
  final int hole;
  final int par;
  final int score;

  const _HoleScoreEntry({
    required this.hole,
    required this.par,
    required this.score,
  });
}
