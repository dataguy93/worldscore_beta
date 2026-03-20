import 'package:flutter/material.dart';

import '../models/tournament.dart';
import '../services/tournament_service.dart';

class TournamentRegistrationPageArgs {
  const TournamentRegistrationPageArgs({
    this.slug,
    this.tournamentId,
    this.token,
  });

  final String? slug;
  final String? tournamentId;
  final String? token;
}

class TournamentRegistrationPage extends StatefulWidget {
  const TournamentRegistrationPage({
    super.key,
    required this.args,
    TournamentService? tournamentService,
  }) : _tournamentService = tournamentService;

  final TournamentRegistrationPageArgs args;
  final TournamentService? _tournamentService;

  @override
  State<TournamentRegistrationPage> createState() =>
      _TournamentRegistrationPageState();
}

class _TournamentRegistrationPageState extends State<TournamentRegistrationPage> {
  late final TournamentService _tournamentService;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<Tournament?>? _tournamentFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tournamentService = widget._tournamentService ?? TournamentService();
    _tournamentFuture = _tournamentService.getTournamentFromRouteArgs(
      slug: widget.args.slug,
      tournamentId: widget.args.tournamentId,
      token: widget.args.token,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register(Tournament tournament) async {
    final playerName = _nameController.text.trim();
    if (playerName.isEmpty) {
      _showSnack('Please enter your name to register.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _tournamentService.ensureSignedIn();
      await _tournamentService.registerCurrentUser(
        tournament: tournament,
        playerName: playerName,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      _showSnack('Registration complete. See you at the tournament!');
      setState(() {
        _tournamentFuture = _tournamentService.getTournamentById(tournament.tournamentId);
      });
    } on RegistrationBlockedException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Registration failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Registration')),
      body: FutureBuilder<Tournament?>(
        future: _tournamentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load this registration link.'));
          }

          final tournament = snapshot.data;
          if (tournament == null) {
            return const Center(child: Text('Invalid registration link.'));
          }

          final closedReason = _closedReason(tournament);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tournament.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Location: ${tournament.location}'),
                      Text('Event date: ${_displayDate(tournament.eventDate)}'),
                      Text(
                        'Registration deadline: ${_displayDate(tournament.registrationDeadline)}',
                      ),
                      Text(
                        'Spots: ${tournament.currentPlayerCount}/${tournament.maxPlayers}',
                      ),
                      if (closedReason != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          closedReason,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Player details'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Player name *'),
                      ),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email (optional)'),
                      ),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone (optional)'),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: (closedReason == null && !_isSubmitting)
                            ? () => _register(tournament)
                            : null,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Register'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _closedReason(Tournament tournament) {
    if (!tournament.registrationOpen || tournament.status != TournamentStatus.open) {
      return 'Registration is currently closed.';
    }
    if (DateTime.now().isAfter(tournament.registrationDeadline)) {
      return 'Registration deadline has passed.';
    }
    if (tournament.currentPlayerCount >= tournament.maxPlayers) {
      return 'Tournament has reached max players.';
    }
    return null;
  }

  String _displayDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
