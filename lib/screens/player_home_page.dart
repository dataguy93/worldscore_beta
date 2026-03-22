import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/session_controller.dart';
import '../widgets/footer_link.dart';
import 'player_round_history_page.dart';
import '../widgets/menu_card.dart';
import '../widgets/upload_widget.dart';

class PlayerSignInHomePage extends StatelessWidget {
  const PlayerSignInHomePage({
    required this.sessionController,
    super.key,
  });

  static const double _headerBarHeight = 64;
  final SessionController sessionController;

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

  void _openRoundHistory(BuildContext context, String? playerUid) {
    if (playerUid == null || playerUid.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to open round history right now.'),
          ),
        );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerRoundHistoryPage(userId: playerUid),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await sessionController.signOut();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              sessionController.errorMessage ??
                  'Unable to sign out right now. Please try again.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = sessionController.profile;
    final firstName = profile?.firstName.trim() ?? '';
    final lastName = profile?.lastName.trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final playerUid = profile?.uid;
    final snapshotName = fullName.isNotEmpty
        ? fullName
        : profile?.username.trim().isNotEmpty == true
            ? profile!.username.trim()
            : 'Player';

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
                        displayName: snapshotName,
                        userId: playerUid,
                      ),
                      const SizedBox(height: 20),
                      const MenuCard(
                        label: 'Leaderboard',
                        subtitle: 'See current and former tournament standings.',
                      ),
                      const SizedBox(height: 14),
                      MenuCard(
                        label: 'Round History',
                        subtitle: 'Review your round history and submitted scorecards.',
                        onTap: () => _openRoundHistory(context, playerUid),
                      ),
                      const SizedBox(height: 14),
                      const PlayerUploadWidget(),
                      const SizedBox(height: 16),
                      ListenableBuilder(
                        listenable: sessionController,
                        builder: (context, _) {
                          return FilledButton.icon(
                            onPressed: sessionController.isLoading
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
  const _PlayerOverviewCard({
    required this.displayName,
    required this.userId,
  });

  final String displayName;
  final String? userId;

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
                    _ScorecardStatsRows(userId: userId),
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

class _ScorecardStatsRows extends StatelessWidget {
  const _ScorecardStatsRows({required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlayerInfoRow(label: 'Rounds this year', value: '0'),
          SizedBox(height: 8),
          _PlayerInfoRow(label: 'Average score', value: '0.0'),
          SizedBox(height: 8),
          _PlayerInfoRow(label: 'Best round', value: '-'),
        ],
      );
    }

    final scorecardsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('scorecards')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: scorecardsStream,
      builder: (context, snapshot) {
        final now = DateTime.now();
        final docs = snapshot.data?.docs;
        var roundsThisYear = 0;
        var totalScoreSum = 0.0;
        var totalScoreCount = 0;
        num? bestRound;

        for (final doc in docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
          final data = doc.data();
          final uploadedAt = data['uploadedAt'];
          if (uploadedAt is Timestamp && uploadedAt.toDate().year == now.year) {
            roundsThisYear++;
          }

          final totalScore = data['totalScore'];
          if (totalScore is num) {
            totalScoreSum += totalScore.toDouble();
            totalScoreCount++;
            bestRound =
                bestRound == null || totalScore < bestRound! ? totalScore : bestRound;
          }
        }

        final averageScore = totalScoreCount == 0 ? 0.0 : totalScoreSum / totalScoreCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlayerInfoRow(label: 'Rounds this year', value: '$roundsThisYear'),
            const SizedBox(height: 8),
            _PlayerInfoRow(label: 'Average score', value: averageScore.toStringAsFixed(1)),
            const SizedBox(height: 8),
            _PlayerInfoRow(
              label: 'Best round',
              value: bestRound?.toString() ?? '-',
            ),
          ],
        );
      },
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
