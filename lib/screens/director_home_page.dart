import 'package:flutter/material.dart';

import '../controllers/session_controller.dart';
import '../widgets/footer_link.dart';
import '../widgets/upload_widget.dart';
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
  static const double _directorActionCardHeight = 100.8;

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

  @override
  Widget build(BuildContext context) {
    final profile = widget.sessionController.profile;
    final firstName = profile?.firstName.trim() ?? '';
    final displayFirstName = firstName.isEmpty ? 'Director' : firstName;
    final fullNameParts = [
      profile?.firstName.trim() ?? '',
      profile?.lastName.trim() ?? '',
    ].where((part) => part.isNotEmpty).toList();
    final displayFullName = fullNameParts.isEmpty
        ? (profile?.fullName ?? '')
        : fullNameParts.join(' ');
    final displayClubName = (profile?.clubName ?? '').trim();
    final displayAssociation = (profile?.association ?? '').trim();

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
                      _DirectorOverviewCard(
                        directorName: displayFullName,
                        clubName: displayClubName,
                        association: displayAssociation,
                      ),
                      const SizedBox(height: 20),
                      MenuCard(
                        label: 'Leaderboard',
                        subtitle: 'View current and former tournament leaderboards.',
                        backgroundColor: const Color(0xFF093823),
                        borderColor: const Color(0xFF137A48),
                        titleColor: const Color(0xFF3CE081),
                        subtitleColor: const Color(0xFF7EA699),
                        icon: Icons.leaderboard_rounded,
                        borderRadius: 24,
                        minHeight: _directorActionCardHeight,
                        padding: const EdgeInsets.all(18),
                        titleFontSize: 24,
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
                        backgroundColor: Color(0xFF093823),
                        borderColor: Color(0xFF137A48),
                        titleColor: Color(0xFF3CE081),
                        subtitleColor: Color(0xFF7EA699),
                        icon: Icons.history_rounded,
                        borderRadius: 24,
                        minHeight: _directorActionCardHeight,
                        padding: EdgeInsets.all(18),
                        titleFontSize: 24,
                      ),
                      const SizedBox(height: 14),
                      const DirectorUploadWidget(),
                      const SizedBox(height: 14),
                      MenuCard(
                        label: 'Admin',
                        subtitle: 'Create, adjust and manage tournament parameters.',
                        backgroundColor: const Color(0xFF093823),
                        borderColor: const Color(0xFF137A48),
                        titleColor: const Color(0xFF3CE081),
                        subtitleColor: const Color(0xFF7EA699),
                        icon: Icons.admin_panel_settings_outlined,
                        borderRadius: 24,
                        minHeight: _directorActionCardHeight,
                        padding: const EdgeInsets.all(18),
                        titleFontSize: 24,
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

class _DirectorOverviewCard extends StatelessWidget {
  const _DirectorOverviewCard({
    required this.directorName,
    required this.clubName,
    required this.association,
  });

  final String directorName;
  final String clubName;
  final String association;

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
            'Director Overview',
            style: TextStyle(
              color: Color(0xFF3CE081),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _DirectorInfoRow(label: 'Name', value: directorName),
          const SizedBox(height: 8),
          _DirectorInfoRow(label: 'Club', value: clubName),
          const SizedBox(height: 8),
          _DirectorInfoRow(label: 'Association', value: association),
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
