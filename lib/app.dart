import 'package:flutter/material.dart';

import 'screens/landing_page.dart';
import 'screens/tournament_registration_page.dart';

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
      initialRoute: '/',
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
