import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/tier_config.dart';
import '../controllers/session_controller.dart';
import '../widgets/worldscore_header.dart';
import '../services/pro_score_upload_service.dart';
import 'account_page.dart';
import 'help_support_page.dart';
import 'how_it_works_page.dart';
import 'manage_plan_page.dart';
import 'pro_performance_page.dart';
import 'pro_round_history_page.dart';
import 'who_we_are_page.dart';
import '../widgets/menu_card.dart';
import '../widgets/mode_toggle.dart';
import '../widgets/upload_widget.dart';

class ProSignInHomePage extends StatelessWidget {
  const ProSignInHomePage({
    required this.sessionController,
    super.key,
  });

  static const double _headerBarHeight = 64;
  static const double _actionCardHeight = 100.8;
  final SessionController sessionController;
  static final _scoreService = ProScoreUploadService();

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'Account':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AccountPage(sessionController: sessionController),
          ),
        );
      case 'Manage Plan':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ManagePlanPage(sessionController: sessionController),
          ),
        );
      case 'Who We Are':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WhoWeArePage(
              role: WorldScoreRole.pro,
              sessionController: sessionController,
            ),
          ),
        );
      case 'How It Works':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HowItWorksPage()),
        );
      case 'Help & Support':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HelpSupportPage()),
        );
      case 'Settings':
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Settings coming soon'),
              duration: Duration(seconds: 2),
            ),
          );
    }
  }

  void _openRoundHistory(BuildContext context, String? proUid) {
    if (proUid == null || proUid.isEmpty) {
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
        builder: (_) => ProRoundHistoryPage(
          userId: proUid,
          scoreService: _scoreService,
          sessionController: sessionController,
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
    final displayFirstName = firstName.isEmpty ? 'PRO' : firstName;
    final lastName = profile?.lastName.trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final proUid = profile?.uid;
    final snapshotName = fullName.isNotEmpty
        ? fullName
        : profile?.username.trim().isNotEmpty == true
            ? profile!.username.trim()
            : 'PRO';

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
                    onSelected: (value) => _handleMenuSelection(context, value),
                    color: const Color(0xFF083A28),
                    position: PopupMenuPosition.under,
                    offset: const Offset(0, 8),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'Account',
                        child: Text('Account', style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 'Manage Plan',
                        child: Text('Manage Plan', style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 'Who We Are',
                        child: Text('Who We Are', style: TextStyle(color: Colors.white)),
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
              if (sessionController.tier.hasTournamentAccess) ...[
                const SizedBox(height: 14),
                Center(
                  child: ModeToggle(sessionController: sessionController),
                ),
              ],
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
                      _ProOverviewCard(
                        displayName: snapshotName,
                        userId: proUid,
                        scoreService: _scoreService,
                        handicap: profile?.handicap,
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
                        onTap: proUid == null || proUid.isEmpty
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProPerformancePage(
                                      userId: proUid,
                                      scoreService: _scoreService,
                                      sessionController: sessionController,
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
                        onTap: () => _openRoundHistory(context, proUid),
                      ),
                      const SizedBox(height: 14),
                      const ProUploadWidget(),
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

class _ProOverviewCard extends StatelessWidget {
  const _ProOverviewCard({
    required this.displayName,
    required this.userId,
    required this.scoreService,
    this.handicap,
  });

  final String displayName;
  final String? userId;
  final ProScoreUploadService scoreService;
  final double? handicap;

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
            'PRO Snapshot',
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
                    _ProInfoRow(label: 'Name', value: displayName),
                    const SizedBox(height: 8),
                    _ScorecardStatsRows(userId: userId, scoreService: scoreService),
                    const SizedBox(height: 8),
                    _ProInfoRow(label: 'Handicap', value: handicap?.toString() ?? '-'),
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
  final ProScoreUploadService scoreService;

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProInfoRow(label: 'Rounds this year', value: '0'),
          SizedBox(height: 8),
          _ProInfoRow(label: 'Average score', value: '0.0'),
          SizedBox(height: 8),
          _ProInfoRow(label: 'Best round', value: '-'),
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
            _ProInfoRow(label: 'Rounds this year', value: '$roundsThisYear'),
            const SizedBox(height: 8),
            _ProInfoRow(label: 'Average score', value: averageScore.toStringAsFixed(1)),
            const SizedBox(height: 8),
            _ProInfoRow(
              label: 'Best round',
              value: bestRound?.toString() ?? '-',
            ),
          ],
        );
      },
    );
  }
}

class _ProInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProInfoRow({required this.label, required this.value});

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
