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
      onGenerateRoute: (settings) {
        final routeName = settings.name ?? '';
        final uri = Uri.tryParse(routeName);
        if (uri != null) {
          if (uri.pathSegments.length == 3 &&
              uri.pathSegments[0] == 'tournaments' &&
              uri.pathSegments[2] == 'register') {
            return MaterialPageRoute<void>(
              builder: (_) => TournamentRegistrationPage(
                args: TournamentRegistrationPageArgs(
                  slug: uri.pathSegments[1],
                ),
              ),
            );
          }

          if (uri.path == '/register' || uri.path == 'register') {
            return MaterialPageRoute<void>(
              builder: (_) => TournamentRegistrationPage(
                args: TournamentRegistrationPageArgs(
                  tournamentId: uri.queryParameters['tournamentId'],
                  token: uri.queryParameters['token'],
                ),
              ),
            );
          }
        }

        if (settings.name == '/tournament-registration' &&
            settings.arguments is TournamentRegistrationPageArgs) {
          final args = settings.arguments! as TournamentRegistrationPageArgs;
          return MaterialPageRoute<void>(
            builder: (_) => TournamentRegistrationPage(args: args),
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => const LandingPage(),
        );
      },
      home: const LandingPage(),
    );
  }
}
