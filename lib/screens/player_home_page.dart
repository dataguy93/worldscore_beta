import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/session_controller.dart';
import '../widgets/footer_link.dart';
import '../widgets/menu_card.dart';
import 'director_home_page.dart';

class PlayerSignInHomePage extends StatelessWidget {
  const PlayerSignInHomePage({super.key, required this.sessionController});

  final SessionController sessionController;

  static const double _headerBarHeight = 64;

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
                      _PlayerOverviewCard(
                        displayName: sessionController.profile?.displayName,
                      ),
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
                      const MenuCard(
                        label: 'Upload',
                        subtitle: 'Submit a new scorecard using AI OCR.',
                      ),
                      const SizedBox(height: 16),
                      _ProfileSwitchCard(
                        selectedRole: 'Player',
                        onRoleChanged: (role) {
                          if (role == 'Director') {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const SignInHomePage()),
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

class _PlayerOverviewCard extends StatelessWidget {
  const _PlayerOverviewCard({required this.displayName});

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : ((user?.displayName?.trim().isNotEmpty ?? false)
              ? user!.displayName!.trim()
              : 'Player');

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
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _userRoundsStream(user?.uid),
                  builder: (context, snapshot) {
                    final stats = _roundStatsFromSnapshot(snapshot.data);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PlayerInfoRow(label: 'Name', value: name),
                        const SizedBox(height: 8),
                        _PlayerInfoRow(
                          label: 'Rounds this year',
                          value: stats.roundCount.toString(),
                        ),
                        const SizedBox(height: 8),
                        _PlayerInfoRow(
                          label: 'Average score',
                          value: stats.averageScore == null
                              ? 'N/A'
                              : stats.averageScore!.toStringAsFixed(1),
                        ),
                        const SizedBox(height: 8),
                        const _PlayerInfoRow(label: 'Handicap', value: ''),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _userRoundsStream(String? uid) {
    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collectionGroup('rounds')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  _RoundStats _roundStatsFromSnapshot(QuerySnapshot<Map<String, dynamic>>? snapshot) {
    if (snapshot == null || snapshot.docs.isEmpty) {
      return const _RoundStats(roundCount: 0, averageScore: null);
    }

    final now = DateTime.now();
    int roundsThisYear = 0;
    int scoreSum = 0;
    int scoreCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final roundDate = _extractRoundDate(data);
      final isThisYear = roundDate == null || roundDate.year == now.year;
      if (!isThisYear) {
        continue;
      }

      roundsThisYear += 1;

      final score = _extractTotalScore(data);
      if (score != null) {
        scoreSum += score;
        scoreCount += 1;
      }
    }

    if (roundsThisYear == 0) {
      return const _RoundStats(roundCount: 0, averageScore: null);
    }

    final average = scoreCount == 0 ? null : scoreSum / scoreCount;
    return _RoundStats(roundCount: roundsThisYear, averageScore: average);
  }

  DateTime? _extractRoundDate(Map<String, dynamic> data) {
    final dynamic rawDate =
        data['uploadedAt'] ?? data['createdAt'] ?? data['roundDate'] ?? data['date'];
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    }
    if (rawDate is DateTime) {
      return rawDate;
    }
    if (rawDate is String) {
      return DateTime.tryParse(rawDate);
    }
    return null;
  }

  int? _extractTotalScore(Map<String, dynamic> data) {
    final dynamic rawScore =
        data['totalScore'] ?? data['score'] ?? data['grossScore'] ?? data['total'];
    if (rawScore is int) {
      return rawScore;
    }
    if (rawScore is double) {
      return rawScore.round();
    }
    if (rawScore is String) {
      return int.tryParse(rawScore);
    }
    return null;
  }
}

class _RoundStats {
  const _RoundStats({required this.roundCount, required this.averageScore});

  final int roundCount;
  final double? averageScore;
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
