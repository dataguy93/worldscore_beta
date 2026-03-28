import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../controllers/session_controller.dart';
import '../services/player_score_upload_service.dart';
import '../widgets/worldscore_header.dart';

class PlayerRoundHistoryPage extends StatefulWidget {
  const PlayerRoundHistoryPage({
    required this.userId,
    required this.scoreService,
    this.sessionController,
    super.key,
  });

  final String userId;
  final PlayerScoreUploadService scoreService;
  final SessionController? sessionController;

  @override
  State<PlayerRoundHistoryPage> createState() => _PlayerRoundHistoryPageState();
}

class _PlayerRoundHistoryPageState extends State<PlayerRoundHistoryPage> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final roundsStream = widget.scoreService.streamUserScorecardHistory(widget.userId);

    return Scaffold(
      backgroundColor: const Color(0xFF031C14),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: WorldScoreHeader(
                subtitle: 'Round History',
                role: WorldScoreRole.player,
                onBack: () => Navigator.of(context).pop(),
                sessionController: widget.sessionController,
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: roundsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _StatusMessage(
                      icon: Icons.error_outline,
                      message: 'Unable to load your rounds right now.',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF3CE081)),
                    );
                  }

                  final roundDocs = snapshot.data?.docs ?? [];
                  if (roundDocs.isEmpty) {
                    return const _StatusMessage(
                      icon: Icons.history,
                      message: 'No rounds logged yet.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: roundDocs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final isExpanded = _expandedIndex == index;
                      return _RoundCard(
                        data: roundDocs[index].data(),
                        isExpanded: isExpanded,
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        onViewScorecard: () {
                          final imageUrl = roundDocs[index].data()['scorecardImageUrl'] as String?;
                          final courseName =
                              (roundDocs[index].data()['courseName'] as String?)?.trim().isNotEmpty == true
                                  ? (roundDocs[index].data()['courseName'] as String).trim()
                                  : 'Unknown course';
                          if (imageUrl != null) {
                            _showScorecardImage(context, imageUrl, courseName);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScorecardImage(BuildContext context, String imageUrl, String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF031C14),
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF3CE081),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF7EA699)),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3CE081),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image_outlined,
                                    color: Color(0xFF7EA699), size: 48),
                                SizedBox(height: 8),
                                Text(
                                  'Could not load scorecard image.',
                                  style: TextStyle(
                                      color: Color(0xFF7EA699), fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Round card with expandable results
// ---------------------------------------------------------------------------

class _RoundCard extends StatelessWidget {
  const _RoundCard({
    required this.data,
    required this.isExpanded,
    required this.onTap,
    required this.onViewScorecard,
  });

  final Map<String, dynamic> data;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onViewScorecard;

  @override
  Widget build(BuildContext context) {
    final courseName =
        (data['courseName'] as String?)?.trim().isNotEmpty == true
            ? (data['courseName'] as String).trim()
            : 'Unknown course';
    final totalScore = data['totalScore'];
    final uploadedAt = data['uploadedAt'];
    final imageUrl = data['scorecardImageUrl'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF072E21),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded ? const Color(0xFF3CE081) : const Color(0xFF165D43),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    courseName,
                    style: const TextStyle(
                      color: Color(0xFF3CE081),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (totalScore is num)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3D25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1E8F5C)),
                    ),
                    child: Text(
                      totalScore.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF7EA699),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Date',
              value: _formatUploadedAt(uploadedAt),
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              if (imageUrl != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onViewScorecard,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('View Scorecard Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3CE081),
                      side: const BorderSide(color: Color(0xFF1E8F5C)),
                      backgroundColor: const Color(0xFF0A3D25),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _RoundResultsTable(data: data),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatUploadedAt(Object? uploadedAt) {
    if (uploadedAt is! Timestamp) return '-';
    final date = uploadedAt.toDate();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Round results table (read-only hole-by-hole scores)
// ---------------------------------------------------------------------------

class _RoundResultsTable extends StatelessWidget {
  const _RoundResultsTable({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rawScores = data['scoresByHole'] as Map<String, dynamic>?;
    final rawPars = data['parsByHole'] as Map<String, dynamic>?;

    if (rawScores == null || rawScores.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No hole-by-hole data available.',
          style: TextStyle(color: Color(0xFF7EA699), fontSize: 13),
        ),
      );
    }

    final scores = <int, int?>{};
    final pars = <int, int?>{};
    for (var hole = 1; hole <= 18; hole++) {
      scores[hole] = _toInt(rawScores['$hole']);
      pars[hole] = rawPars != null ? _toInt(rawPars['$hole']) : null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _NineHoleResultsTable(
            label: 'Front 9',
            startHole: 1,
            endHole: 9,
            scores: scores,
            pars: pars,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _NineHoleResultsTable(
            label: 'Back 9',
            startHole: 10,
            endHole: 18,
            scores: scores,
            pars: pars,
          ),
        ),
      ],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }
}

// ---------------------------------------------------------------------------
// Nine-hole results table (read-only)
// ---------------------------------------------------------------------------

class _NineHoleResultsTable extends StatelessWidget {
  const _NineHoleResultsTable({
    required this.label,
    required this.startHole,
    required this.endHole,
    required this.scores,
    required this.pars,
  });

  final String label;
  final int startHole;
  final int endHole;
  final Map<int, int?> scores;
  final Map<int, int?> pars;

  @override
  Widget build(BuildContext context) {
    final hasPars = pars.values.any((v) => v != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Color(0xFFB8D4C8),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFF165D43), width: 1),
            verticalInside: BorderSide(color: Color(0xFF165D43), width: 1),
            top: BorderSide(color: Color(0xFF1E8F5C), width: 1.2),
            left: BorderSide(color: Color(0xFF1E8F5C), width: 1.2),
            right: BorderSide(color: Color(0xFF1E8F5C), width: 1.2),
            bottom: BorderSide(color: Color(0xFF1E8F5C), width: 1.2),
          ),
          columnWidths: {
            0: const FlexColumnWidth(1),
            if (hasPars) 1: const FlexColumnWidth(1),
            if (hasPars) 2: const FlexColumnWidth(1) else 1: const FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF052A1A)),
              children: [
                const _Cell(
                  child: Text('#', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7EA699), fontWeight: FontWeight.w800)),
                ),
                if (hasPars)
                  const _Cell(
                    child: Text('Par', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFD4A843), fontWeight: FontWeight.w800)),
                  ),
                const _Cell(
                  child: Text('Score', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF3CE081), fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            for (var hole = startHole; hole <= endHole; hole++)
              TableRow(
                children: [
                  _Cell(
                    color: const Color(0xFF0A3D25),
                    child: Text('$hole', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB8D4C8), fontWeight: FontWeight.w700)),
                  ),
                  if (hasPars)
                    _Cell(
                      child: Text(
                        pars[hole]?.toString() ?? '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFD4A843), fontWeight: FontWeight.w700),
                      ),
                    ),
                  _Cell(
                    child: Text(
                      scores[hole]?.toString() ?? '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _scoreColor(scores[hole], pars[hole]),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF052A1A)),
              children: [
                _Cell(
                  child: Text(
                    startHole == 1 ? 'OUT' : 'IN',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF3CE081), fontWeight: FontWeight.w800),
                  ),
                ),
                if (hasPars)
                  _Cell(
                    child: Text(
                      _sum(pars, startHole, endHole),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFD4A843), fontWeight: FontWeight.w800),
                    ),
                  ),
                _Cell(
                  child: Text(
                    _sum(scores, startHole, endHole),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF3CE081), fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static Color _scoreColor(int? score, int? par) {
    if (score == null || par == null) return const Color(0xFFB8D4C8);
    if (score < par) return const Color(0xFF3CE081);
    if (score > par) return const Color(0xFFFF7B7B);
    return const Color(0xFFB8D4C8);
  }

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

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _Cell extends StatelessWidget {
  const _Cell({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? const Color(0xFF072E21),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: const TextStyle(
          color: Color(0xFF7EA699),
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

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF7EA699), size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF7EA699), fontSize: 15),
          ),
        ],
      ),
    );
  }
}
