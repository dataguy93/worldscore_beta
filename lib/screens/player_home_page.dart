import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/session_controller.dart';
import '../services/player_score_upload_service.dart';
import 'player_performance_page.dart';
import 'player_round_history_page.dart';
import '../widgets/menu_card.dart';
import '../widgets/upload_widget.dart';

class PlayerSignInHomePage extends StatelessWidget {
  const PlayerSignInHomePage({
    required this.sessionController,
    super.key,
  });

  static const double _headerBarHeight = 64;
  static const double _actionCardHeight = 100.8;
  final SessionController sessionController;
  static final _scoreService = PlayerScoreUploadService();

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
        builder: (_) => PlayerRoundHistoryPage(
          userId: playerUid,
          scoreService: _scoreService,
        ),
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
    final displayFirstName = firstName.isEmpty ? 'Player' : firstName;
    final lastName = profile?.lastName.trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final playerUid = profile?.uid;
    final snapshotName = fullName.isNotEmpty
        ? fullName
        : profile?.username.trim().isNotEmpty == true
            ? profile!.username.trim()
            : 'Player';

    return Scaffold(
      backgroundColor: const Color(0xFF031C14),
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
                          colors: [Color(0xFF083A28), Color(0xFF0F5A3F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: const Color(0xFF1E8F5C)),
                      ),
                      child: const Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            'WORLDSCORE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'AI',
                            style: TextStyle(
                              color: Color(0xFF3CE081),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    tooltip: 'Open menu',
                    onSelected: (value) => _showMenuSelection(context, value),
                    color: const Color(0xFF083A28),
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
                      PopupMenuItem(
                        value: 'How It Works',
                        child: Text('How It Works', style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 'Help & Support',
                        child: Text('Help & Support', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    child: Container(
                      height: _headerBarHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF083A28),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1E8F5C)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: const Icon(
                        Icons.menu,
                        color: Color(0xFF9AC3B7),
                        size: 22,
                      ),
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
                      Text(
                        'Welcome back, $displayFirstName',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF7EA699),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _PlayerOverviewCard(
                        displayName: snapshotName,
                        userId: playerUid,
                        scoreService: _scoreService,
                      ),
                      const SizedBox(height: 20),
                      MenuCard(
                        label: 'Player Performance',
                        subtitle: 'View your scoring stats and trends.',
                        backgroundColor: const Color(0xFF093823),
                        borderColor: const Color(0xFF137A48),
                        titleColor: const Color(0xFF3CE081),
                        subtitleColor: const Color(0xFF7EA699),
                        icon: Icons.insights_rounded,
                        borderRadius: 24,
                        minHeight: _actionCardHeight,
                        padding: const EdgeInsets.all(18),
                        titleFontSize: 24,
                        onTap: playerUid == null || playerUid.isEmpty
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PlayerPerformancePage(
                                      userId: playerUid,
                                      scoreService: _scoreService,
                                    ),
                                  ),
                                ),
                      ),
                      const SizedBox(height: 14),
                      MenuCard(
                        label: 'Round History',
                        subtitle: 'Review your round history and submitted scorecards.',
                        backgroundColor: const Color(0xFF093823),
                        borderColor: const Color(0xFF137A48),
                        titleColor: const Color(0xFF3CE081),
                        subtitleColor: const Color(0xFF7EA699),
                        icon: Icons.history_rounded,
                        borderRadius: 24,
                        minHeight: _actionCardHeight,
                        padding: const EdgeInsets.all(18),
                        titleFontSize: 24,
                        onTap: () => _openRoundHistory(context, playerUid),
                      ),
                      const SizedBox(height: 14),
                      const PlayerUploadWidget(),
                      const SizedBox(height: 16),
                      ListenableBuilder(
                        listenable: sessionController,
                        builder: (context, _) {
                          return FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF093823),
                              foregroundColor: const Color(0xFF58EB9D),
                              disabledBackgroundColor: const Color(0xFF1F4734),
                              disabledForegroundColor: const Color(0xFF5E7D72),
                              side: const BorderSide(color: Color(0xFF137A48)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: sessionController.isLoading
                                ? null
                                : () => _signOut(context),
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                          );
                        },
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
    required this.scoreService,
  });

  final String displayName;
  final String? userId;
  final PlayerScoreUploadService scoreService;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF072E21),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF165D43)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Player Snapshot',
            style: TextStyle(
              color: Color(0xFF3CE081),
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
                    color: const Color(0xFF051F15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1A6B45)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: Color(0xFF5EA882), size: 28),
                      SizedBox(height: 8),
                      Text(
                        'Upload photo',
                        style: TextStyle(
                          color: Color(0xFF7EA699),
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
                    _ScorecardStatsRows(userId: userId, scoreService: scoreService),
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
  const _ScorecardStatsRows({required this.userId, required this.scoreService});

  final String? userId;
  final PlayerScoreUploadService scoreService;

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

    final scorecardsStream = scoreService.streamUserScorecards(userId!);

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
                bestRound == null || totalScore < bestRound ? totalScore : bestRound;
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
