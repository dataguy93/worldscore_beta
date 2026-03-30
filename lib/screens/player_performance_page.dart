import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controllers/session_controller.dart';
import '../services/player_score_upload_service.dart';
import '../widgets/worldscore_header.dart';

class PlayerPerformancePage extends StatelessWidget {
  const PlayerPerformancePage({
    required this.userId,
    required this.scoreService,
    this.sessionController,
    super.key,
  });

  final String userId;
  final PlayerScoreUploadService scoreService;
  final SessionController? sessionController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031C14),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: scoreService.streamUserScorecards(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF47E590),
                  strokeWidth: 2,
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final stats = _computeStats(docs);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorldScoreHeader(
                    subtitle: 'Player Performance',
                    role: WorldScoreRole.player,
                    onBack: () => Navigator.of(context).pop(),
                    sessionController: sessionController,
                  ),
                  const SizedBox(height: 20),

                  // Rounds summary
                  _SummaryBanner(
                    roundsPlayed: stats.roundsPlayed,
                    roundsWithHoleData: stats.roundsWithHoleData,
                  ),
                  const SizedBox(height: 16),

                  // Main metrics grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.25,
                    children: [
                      _MetricCard(
                        borderColor: const Color(0xFF137A48),
                        background: const Color(0xFF093823),
                        icon: Icons.scoreboard_rounded,
                        iconColor: const Color(0xFF3EE483),
                        value: stats.averageTotalScore,
                        label: 'Avg Score',
                        sublabel: 'per round',
                      ),
                      _MetricCard(
                        borderColor: const Color(0xFF12598A),
                        background: const Color(0xFF082538),
                        icon: Icons.emoji_events_rounded,
                        iconColor: const Color(0xFF62A9FF),
                        value: stats.bestRound,
                        label: 'Best Round',
                        sublabel: 'lowest score',
                      ),
                      _MetricCard(
                        borderColor: const Color(0xFF7C5E1A),
                        background: const Color(0xFF25220D),
                        icon: Icons.trending_down_rounded,
                        iconColor: const Color(0xFFF7C132),
                        value: stats.worstRound,
                        label: 'Worst Round',
                        sublabel: 'highest score',
                      ),
                      _MetricCard(
                        borderColor: const Color(0xFF4B3287),
                        background: const Color(0xFF1C1E35),
                        icon: Icons.golf_course_rounded,
                        iconColor: const Color(0xFFAA80FF),
                        value: '${stats.distinctCourses}',
                        label: 'Courses',
                        sublabel: 'played',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Scoring by par type
                  _SectionCard(
                    title: 'Average Score by Par',
                    subtitle: 'How you perform on each hole type',
                    child: Column(
                      children: [
                        _ParTypeRow(
                          label: 'Par 3s',
                          par: 3,
                          average: stats.avgPar3,
                          icon: Icons.flag_rounded,
                          color: const Color(0xFF47E590),
                          scores: stats.par3Scores,
                        ),
                        const SizedBox(height: 10),
                        _ParTypeRow(
                          label: 'Par 4s',
                          par: 4,
                          average: stats.avgPar4,
                          icon: Icons.flag_rounded,
                          color: const Color(0xFF44A8FF),
                          scores: stats.par4Scores,
                        ),
                        const SizedBox(height: 10),
                        _ParTypeRow(
                          label: 'Par 5s',
                          par: 5,
                          average: stats.avgPar5,
                          icon: Icons.flag_rounded,
                          color: const Color(0xFFFFA64D),
                          scores: stats.par5Scores,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scoring distribution
                  _SectionCard(
                    title: 'Scoring Distribution',
                    subtitle: 'Average per round across all rounds',
                    child: Column(
                      children: [
                        _DistributionRow(
                          label: 'Birdies or Better',
                          value: stats.avgBirdiesPerRound,
                          color: const Color(0xFF47E590),
                        ),
                        const SizedBox(height: 8),
                        _DistributionRow(
                          label: 'Pars',
                          value: stats.avgParsPerRound,
                          color: const Color(0xFF44A8FF),
                        ),
                        const SizedBox(height: 8),
                        _DistributionRow(
                          label: 'Bogeys',
                          value: stats.avgBogeysPerRound,
                          color: const Color(0xFFFFA64D),
                        ),
                        const SizedBox(height: 8),
                        _DistributionRow(
                          label: 'Double Bogey+',
                          value: stats.avgDoublePlusPerRound,
                          color: const Color(0xFFFF6161),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _PlayerStats _computeStats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return _PlayerStats.empty();

    var totalScoreSum = 0.0;
    var totalScoreCount = 0;
    num? bestRound;
    num? worstRound;
    final courseNames = <String>{};

    // For par-based analysis
    var par3ScoreSum = 0.0;
    var par3Count = 0;
    var par4ScoreSum = 0.0;
    var par4Count = 0;
    var par5ScoreSum = 0.0;
    var par5Count = 0;

    // Score distributions per par type (score -> count)
    final par3Scores = <int, int>{};
    final par4Scores = <int, int>{};
    final par5Scores = <int, int>{};


    var totalBirdies = 0;
    var totalPars = 0;
    var totalBogeys = 0;
    var totalDoublePlus = 0;
    var roundsWithHoleData = 0;

    for (final doc in docs) {
      final data = doc.data();
      final courseName = (data['courseName'] as String?)?.trim();
      if (courseName != null && courseName.isNotEmpty) {
        courseNames.add(courseName.toLowerCase());
      }
      final totalScore = data['totalScore'];
      if (totalScore is num) {
        totalScoreSum += totalScore.toDouble();
        totalScoreCount++;
        bestRound =
            bestRound == null || totalScore < bestRound ? totalScore : bestRound;
        worstRound = worstRound == null || totalScore > worstRound
            ? totalScore
            : worstRound;
      }

      // Hole-by-hole analysis
      final scoresByHole = data['scoresByHole'];
      final parsByHole = data['parsByHole'];
      if (scoresByHole is! Map || parsByHole is! Map) continue;

      var hasAnyHoleData = false;
      var roundBirdies = 0;
      var roundPars = 0;
      var roundBogeys = 0;
      var roundDoublePlus = 0;

      for (var hole = 1; hole <= 18; hole++) {
        final scoreVal = scoresByHole['$hole'];
        final parVal = parsByHole['$hole'];
        if (scoreVal == null || parVal == null) continue;

        final score =
            scoreVal is int ? scoreVal : int.tryParse('$scoreVal');
        final par = parVal is int ? parVal : int.tryParse('$parVal');
        if (score == null || par == null) continue;

        hasAnyHoleData = true;

        // Par-type averages
        if (par == 3) {
          par3ScoreSum += score;
          par3Count++;
          par3Scores[score] = (par3Scores[score] ?? 0) + 1;
        } else if (par == 4) {
          par4ScoreSum += score;
          par4Count++;
          par4Scores[score] = (par4Scores[score] ?? 0) + 1;
        } else if (par == 5) {
          par5ScoreSum += score;
          par5Count++;
          par5Scores[score] = (par5Scores[score] ?? 0) + 1;
        }

        // Scoring distribution
        final diff = score - par;
        if (diff <= -1) {
          roundBirdies++;
        } else if (diff == 0) {
          roundPars++;
        } else if (diff == 1) {
          roundBogeys++;
        } else {
          roundDoublePlus++;
        }
      }

      if (hasAnyHoleData) {
        roundsWithHoleData++;
        totalBirdies += roundBirdies;
        totalPars += roundPars;
        totalBogeys += roundBogeys;
        totalDoublePlus += roundDoublePlus;
      }
    }

    final avgTotal =
        totalScoreCount == 0 ? '--' : (totalScoreSum / totalScoreCount).toStringAsFixed(1);

    return _PlayerStats(
      roundsPlayed: totalScoreCount,
      roundsWithHoleData: roundsWithHoleData,
      distinctCourses: courseNames.length,
      averageTotalScore: avgTotal,
      bestRound: bestRound?.toString() ?? '--',
      worstRound: worstRound?.toString() ?? '--',
      avgPar3: par3Count == 0 ? '--' : (par3ScoreSum / par3Count).toStringAsFixed(2),
      avgPar4: par4Count == 0 ? '--' : (par4ScoreSum / par4Count).toStringAsFixed(2),
      avgPar5: par5Count == 0 ? '--' : (par5ScoreSum / par5Count).toStringAsFixed(2),
      par3Scores: par3Scores,
      par4Scores: par4Scores,
      par5Scores: par5Scores,
      avgBirdiesPerRound: roundsWithHoleData == 0
          ? '--'
          : (totalBirdies / roundsWithHoleData).toStringAsFixed(1),
      avgParsPerRound: roundsWithHoleData == 0
          ? '--'
          : (totalPars / roundsWithHoleData).toStringAsFixed(1),
      avgBogeysPerRound: roundsWithHoleData == 0
          ? '--'
          : (totalBogeys / roundsWithHoleData).toStringAsFixed(1),
      avgDoublePlusPerRound: roundsWithHoleData == 0
          ? '--'
          : (totalDoublePlus / roundsWithHoleData).toStringAsFixed(1),
    );
  }
}

class _PlayerStats {
  const _PlayerStats({
    required this.roundsPlayed,
    required this.roundsWithHoleData,
    required this.distinctCourses,
    required this.averageTotalScore,
    required this.bestRound,
    required this.worstRound,
    required this.avgPar3,
    required this.avgPar4,
    required this.avgPar5,
    required this.par3Scores,
    required this.par4Scores,
    required this.par5Scores,
    required this.avgBirdiesPerRound,
    required this.avgParsPerRound,
    required this.avgBogeysPerRound,
    required this.avgDoublePlusPerRound,
  });

  factory _PlayerStats.empty() => const _PlayerStats(
        roundsPlayed: 0,
        roundsWithHoleData: 0,
        distinctCourses: 0,
        averageTotalScore: '--',
        bestRound: '--',
        worstRound: '--',
        avgPar3: '--',
        avgPar4: '--',
        avgPar5: '--',
        par3Scores: {},
        par4Scores: {},
        par5Scores: {},
        avgBirdiesPerRound: '--',
        avgParsPerRound: '--',
        avgBogeysPerRound: '--',
        avgDoublePlusPerRound: '--',
      );

  final int roundsPlayed;
  final int roundsWithHoleData;
  final int distinctCourses;
  final String averageTotalScore;
  final String bestRound;
  final String worstRound;
  final String avgPar3;
  final String avgPar4;
  final String avgPar5;
  final Map<int, int> par3Scores;
  final Map<int, int> par4Scores;
  final Map<int, int> par5Scores;
  final String avgBirdiesPerRound;
  final String avgParsPerRound;
  final String avgBogeysPerRound;
  final String avgDoublePlusPerRound;
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.roundsPlayed,
    required this.roundsWithHoleData,
  });

  final int roundsPlayed;
  final int roundsWithHoleData;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF032A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0F5D39)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, color: Color(0xFF47E590), size: 20),
          const SizedBox(width: 10),
          Text(
            '$roundsPlayed round${roundsPlayed == 1 ? '' : 's'} uploaded',
            style: const TextStyle(
              color: Color(0xFFE6F1EC),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (roundsWithHoleData < roundsPlayed) ...[
            const Text(
              '  ·  ',
              style: TextStyle(color: Color(0xFF6F9183), fontSize: 14),
            ),
            Text(
              '$roundsWithHoleData with hole data',
              style: const TextStyle(
                color: Color(0xFF6F9183),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.borderColor,
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.sublabel,
  });

  final Color borderColor;
  final Color background;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFD7E5DE),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sublabel,
                  style: const TextStyle(
                    color: Color(0xFF80998F),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF032A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F5D39)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE6F1EC),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6F9183),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ParTypeRow extends StatelessWidget {
  const _ParTypeRow({
    required this.label,
    required this.par,
    required this.average,
    required this.icon,
    required this.color,
    required this.scores,
  });

  final String label;
  final int par;
  final String average;
  final IconData icon;
  final Color color;
  final Map<int, int> scores;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: scores.isEmpty
          ? null
          : () => _showPieChart(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF072E21),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF165D43)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD7E5DE),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              average,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (scores.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.6), size: 20),
            ],
          ],
        ),
      ),
    );
  }

  /// Merges all scores at double bogey or worse into a single bucket
  /// keyed by (par + 2). Returns sorted entries.
  List<MapEntry<int, int>> _groupedEntries() {
    final grouped = <int, int>{};
    final doubleBogeyScore = par + 2;
    for (final e in scores.entries) {
      if (e.key >= doubleBogeyScore) {
        grouped[doubleBogeyScore] =
            (grouped[doubleBogeyScore] ?? 0) + e.value;
      } else {
        grouped[e.key] = (grouped[e.key] ?? 0) + e.value;
      }
    }
    return grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  String _scoreLabel(int score) {
    final diff = score - par;
    switch (diff) {
      case <= -3:
        return 'Albatross';
      case -2:
        return 'Eagle';
      case -1:
        return 'Birdie';
      case 0:
        return 'Par';
      case 1:
        return 'Bogey';
      default:
        return 'Double +';
    }
  }

  static const _sliceColors = [
    Color(0xFF2ECC71), // eagle or better
    Color(0xFF47E590), // birdie
    Color(0xFF44A8FF), // par
    Color(0xFFFFA64D), // bogey
    Color(0xFFFF6161), // double+
  ];

  Color _colorForDiff(int diff) {
    if (diff <= -2) return _sliceColors[0];
    if (diff == -1) return _sliceColors[1];
    if (diff == 0) return _sliceColors[2];
    if (diff == 1) return _sliceColors[3];
    return _sliceColors[4];
  }

  void _showPieChart(BuildContext context) {
    final sortedEntries = _groupedEntries();
    final total = scores.values.fold<int>(0, (s, v) => s + v);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF032A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF6F9183),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$label Score Breakdown',
                style: const TextStyle(
                  color: Color(0xFFE6F1EC),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$total holes  ·  Avg $average',
                style: const TextStyle(
                  color: Color(0xFF6F9183),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: sortedEntries.map((e) {
                      final pct = (e.value / total * 100);
                      return PieChartSectionData(
                        value: e.value.toDouble(),
                        color: _colorForDiff(e.key - par),
                        radius: 50,
                        title: '${pct.round()}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...sortedEntries.map((e) {
                final pct = (e.value / total * 100).toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _colorForDiff(e.key - par),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _scoreLabel(e.key),
                          style: const TextStyle(
                            color: Color(0xFFD7E5DE),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${e.value}  ($pct%)',
                        style: const TextStyle(
                          color: Color(0xFF6F9183),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Parse the value for the bar width, default to 0 if '--'
    final numValue = double.tryParse(value) ?? 0;
    // Max width fraction based on 18 holes
    final fraction = numValue / 18;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD7E5DE),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value / round',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                color: const Color(0xFF0A3D28),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
