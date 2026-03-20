import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'director_home_page.dart';
import 'player_home_page.dart';

class AuthenticatedHomeScreen extends StatelessWidget {
  const AuthenticatedHomeScreen({
    super.key,
    required this.user,
  });

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final isDirector = user.preferredRole == 'director';

    return Scaffold(
      appBar: AppBar(
        title: const Text('WorldScoreAI Home'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.displayName.isEmpty ? 'Welcome' : 'Welcome, ${user.displayName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(user.email),
            const SizedBox(height: 20),
            Text('Role: ${isDirector ? 'Director' : 'Player'}'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => isDirector
                          ? const SignInHomePage()
                          : const PlayerSignInHomePage(),
                    ),
                  );
                },
                child: Text(
                  isDirector ? 'Open Director Home Page' : 'Open Player Home Page',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
