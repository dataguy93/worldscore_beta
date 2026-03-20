import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/authenticated_home_screen.dart';
import 'screens/landing_page.dart';
import 'screens/tournament_registration_page.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';

class WorldScoreAIApp extends StatelessWidget {
  const WorldScoreAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorldScoreAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A1628)),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
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
          builder: (_) => const LandingPage(),
        );
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LandingPage();
        }

        return FutureBuilder(
          future: UserService().getUserData(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final appUser = userSnapshot.data;
            if (appUser == null) {
              return const LandingPage();
            }

            return AuthenticatedHomeScreen(user: appUser);
          },
        );
      },
    );
  }
}
