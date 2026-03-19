import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/branding_widgets.dart';
import '../widgets/footer_link.dart';
import 'director_home_page.dart';
import 'player_home_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  void _showSignInDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'Director';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF7F8F4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFD9E5C3)),
              ),
              title: const Text('Sign In'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'Player',
                            label: Text('Player'),
                          ),
                          ButtonSegment<String>(
                            value: 'Director',
                            label: Text('Director'),
                          ),
                        ],
                        selected: {selectedRole},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setState(() => selectedRole = selection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Please enter both email and password.'),
                          ),
                        );
                      return;
                    }

                    Navigator.of(dialogContext).pop();

                    if (selectedRole == 'Director') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SignInHomePage(),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PlayerSignInHomePage(),
                        ),
                      );
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/scorecard.jpeg',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF171D0F).withValues(alpha: 0.35),
                  const Color(0xFF0D140A).withValues(alpha: 0.76),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 620),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _LandingBrand(),
                          const SizedBox(height: 30),
                          const Text(
                            'WorldScore AI.\nGolf scoring instantly.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 46,
                              fontWeight: FontWeight.w700,
                              height: 1.18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Built for golfers, clubs, and tournaments. Capture, verify, and track every round with confidence.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Sign In',
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.16),
                                  textColor: Colors.white,
                                  borderColor:
                                      Colors.white.withValues(alpha: 0.32),
                                  onPressed: () => _showSignInDialog(context),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Create Account',
                                  backgroundColor: const Color(0xFF89C253),
                                  textColor: const Color(0xFF132907),
                                  borderColor: const Color(0xFFA8D475),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              FooterLink(label: 'How It Works', onTap: () {}),
                              FooterLink(label: 'Help & Support', onTap: () {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingBrand extends StatelessWidget {
  const _LandingBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            const Icon(
              Icons.public,
              size: 56,
              color: Colors.white,
            ),
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF89C253),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 13,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        const Text(
          'WorldScore AI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
