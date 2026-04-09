import 'package:flutter/material.dart';

import '../controllers/session_controller.dart';
import '../screens/account_page.dart';
import '../screens/help_support_page.dart';
import '../screens/how_it_works_page.dart';
import '../screens/who_we_are_page.dart';

enum WorldScoreRole { director, player }

class WorldScoreHeader extends StatelessWidget {
  const WorldScoreHeader({
    super.key,
    required this.subtitle,
    required this.role,
    this.onBack,
    this.trailing,
    this.sessionController,
  });

  final String subtitle;
  final WorldScoreRole role;
  final VoidCallback? onBack;
  final Widget? trailing;
  final SessionController? sessionController;

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'Account':
        if (sessionController != null) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  AccountPage(sessionController: sessionController!),
            ),
          );
        }
      case 'Who We Are':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => WhoWeArePage(role: role)),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null) ...[
              _BackButton(onPressed: onBack!),
              const SizedBox(width: 10),
            ],
            const Expanded(
              child: Row(
                children: [
                  Text(
                    'WorldScore',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: Color(0xFF3CE081),
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              tooltip: 'Open menu',
              onSelected: (value) => _handleMenuSelection(context, value),
              color: const Color(0xFF083A28),
              position: PopupMenuPosition.under,
              offset: const Offset(0, 8),
              itemBuilder: (context) => [
                if (sessionController != null)
                  const PopupMenuItem(
                    value: 'Account',
                    child: Text('Account',
                        style: TextStyle(color: Colors.white)),
                  ),
                const PopupMenuItem(
                  value: 'Who We Are',
                  child: Text('Who We Are',
                      style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: 'Settings',
                  child: Text('Settings',
                      style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: 'How It Works',
                  child: Text('How It Works',
                      style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: 'Help & Support',
                  child: Text('Help & Support',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
              child: RolePill(role: role),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9AC3B7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class RolePill extends StatelessWidget {
  const RolePill({super.key, required this.role});

  final WorldScoreRole role;

  @override
  Widget build(BuildContext context) {
    final label = role == WorldScoreRole.director ? 'Director' : 'Player';
    final icon = role == WorldScoreRole.director
        ? Icons.rocket_launch_outlined
        : Icons.sports_golf_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF083F2A),
        border: Border.all(color: const Color(0xFF1D8E5B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4BE58F)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4BE58F),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Go back',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF083A28),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E8F5C)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF9AC3B7),
            size: 16,
          ),
        ),
      ),
    );
  }
}
