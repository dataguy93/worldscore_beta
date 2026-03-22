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

  Route<void> _routeForPath(String? path) {
    final uri = Uri.tryParse(path ?? '/');

    if (uri != null) {
      if (uri.pathSegments.length == 3 &&
          uri.pathSegments.first == 'tournaments' &&
          uri.pathSegments[2] == 'register') {
        return MaterialPageRoute<void>(
          builder: (_) => TournamentRegistrationPage(
            sessionController: _sessionController,
            tournamentId: uri.pathSegments[1],
          ),
          settings: RouteSettings(name: uri.path),
        );
      }

      if (uri.path == '/register') {
        return MaterialPageRoute<void>(
          builder: (_) => TournamentRegistrationPage(
            sessionController: _sessionController,
            tournamentId: uri.queryParameters['tournamentId'],
          ),
          settings: settingsFrom(uri),
        );
      }
    }

    return MaterialPageRoute<void>(
      builder: (_) => _AuthGate(sessionController: _sessionController),
    );
  }

  RouteSettings settingsFrom(Uri uri) {
    final fullPath = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    return RouteSettings(name: fullPath);
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
          onGenerateInitialRoutes: (initialRoute) => [_routeForPath(initialRoute)],
          onGenerateRoute: (settings) => _routeForPath(settings.name),
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

    final pendingRoute = sessionController.consumePendingRouteAfterAuth();
    if (pendingRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(pendingRoute);
        }
      });
    }

    final role = sessionController.profile?.role.toLowerCase();
    final isDirector = role == 'director';
    final homePage = isDirector
        ? SignInHomePage(sessionController: sessionController)
        : PlayerSignInHomePage(sessionController: sessionController);

    return Scaffold(body: homePage);
  }
}
