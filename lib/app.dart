import 'package:flutter/material.dart';

import 'controllers/session_controller.dart';
import 'screens/director_home_page.dart';
import 'screens/landing_page.dart';
import 'screens/player_home_page.dart';
import 'screens/tournament_registration_page.dart';

class WorldScoreAIApp extends StatefulWidget {
  const WorldScoreAIApp({super.key});

  @override
  State<WorldScoreAIApp> createState() => _WorldScoreAIAppState();
}

class _WorldScoreAIAppState extends State<WorldScoreAIApp> {
  late final SessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController = SessionController();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sessionController,
      builder: (context, _) {
        return MaterialApp(
          title: 'WorldScoreAI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A1628)),
            useMaterial3: true,
          ),
          home: _AuthGate(sessionController: _sessionController),
          onGenerateRoute: (settings) {
            final uri = Uri.tryParse(settings.name ?? '/');

            if (uri != null) {
              if (uri.pathSegments.length == 3 &&
                  uri.pathSegments.first == 'tournaments' &&
                  uri.pathSegments[2] == 'register') {
                return MaterialPageRoute<void>(
                  builder: (_) => TournamentRegistrationPage(slug: uri.pathSegments[1]),
                );
              }

              if (uri.path == '/register') {
                return MaterialPageRoute<void>(
                  builder: (_) => TournamentRegistrationPage(
                    tournamentId: uri.queryParameters['tournamentId'],
                  ),
                );
              }
            }

            return MaterialPageRoute<void>(
              builder: (_) => _AuthGate(sessionController: _sessionController),
            );
          },
        );
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.sessionController});

  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    if (!sessionController.isSignedIn) {
      return LandingPage(sessionController: sessionController);
    }

    final role = sessionController.profile?.role.toLowerCase();
    final isDirector = role == 'director';
    final homePage = isDirector
        ? const SignInHomePage()
        : PlayerSignInHomePage(sessionController: sessionController);

    return Scaffold(
      body: homePage,
      floatingActionButton: isDirector
          ? FloatingActionButton.extended(
              onPressed: () async {
                await sessionController.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
