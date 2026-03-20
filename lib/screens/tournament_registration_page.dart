import 'package:flutter/material.dart';

import '../models/tournament.dart';
import '../services/registration_service.dart';
import '../services/tournament_service.dart';

class TournamentRegistrationPage extends StatefulWidget {
  const TournamentRegistrationPage({
    super.key,
    this.slug,
    this.tournamentId,
  });

  final String? slug;
  final String? tournamentId;

  @override
  State<TournamentRegistrationPage> createState() => _TournamentRegistrationPageState();
}

class _TournamentRegistrationPageState extends State<TournamentRegistrationPage> {
  final TournamentService _tournamentService = TournamentService();
  final RegistrationService _registrationService = RegistrationService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  Tournament? _tournament;

  @override
  void initState() {
    super.initState();
    _loadTournament();
  }

  Future<void> _loadTournament() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournament = widget.slug != null
          ? await _tournamentService.findBySlug(widget.slug!)
          : widget.tournamentId != null
              ? await _tournamentService.findById(widget.tournamentId!)
              : null;

      if (!mounted) {
        return;
      }

      if (tournament == null) {
        setState(() {
          _error = 'Invalid or missing tournament link.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _tournament = tournament;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Unable to load tournament details right now.';
        _isLoading = false;
      });
    }
  }

  String? _validateTournamentAvailability(Tournament tournament) {
    final now = DateTime.now();
    if (!tournament.registrationOpen || tournament.status != TournamentStatus.open) {
      return 'Registration is currently closed.';
    }
    if (now.isAfter(tournament.registrationDeadline)) {
      return 'Registration deadline has passed.';
    }
    if (tournament.currentPlayerCount >= tournament.maxPlayers) {
      return 'This tournament is full.';
    }
    return null;
  }

  Future<void> _submitRegistration() async {
    final tournament = _tournament;
    if (tournament == null) {
      return;
    }

    final playerName = _nameController.text.trim();
    if (playerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    final availabilityError = _validateTournamentAvailability(tournament);
    if (availabilityError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(availabilityError)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _registrationService.registerForTournament(
        tournament: tournament,
        playerName: playerName,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful.')),
      );
      await _loadTournament();
    } on TournamentRegistrationException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournament = _tournament;
    final availabilityError = tournament == null ? null : _validateTournamentAvailability(tournament);

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Registration')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Text(_error!, style: const TextStyle(color: Colors.redAccent))
                    : tournament == null
                        ? const Text('Tournament not found.')
                        : Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tournament.name,
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Event Date: ${_dateLabel(tournament.eventDate)}'),
                                  Text('Location: ${tournament.location}'),
                                  Text(
                                    'Spots: ${tournament.currentPlayerCount}/${tournament.maxPlayers}',
                                  ),
                                  Text(
                                    'Registration Deadline: ${_dateLabel(tournament.registrationDeadline)}',
                                  ),
                                  const SizedBox(height: 14),
                                  if (availabilityError != null)
                                    Text(
                                      availabilityError,
                                      style: const TextStyle(color: Colors.redAccent),
                                    )
                                  else ...[
                                    TextField(
                                      controller: _nameController,
                                      decoration:
                                          const InputDecoration(labelText: 'Player name *'),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _emailController,
                                      decoration: const InputDecoration(labelText: 'Email'),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(labelText: 'Phone'),
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed: _isSubmitting ? null : _submitRegistration,
                                      child: Text(
                                        _isSubmitting ? 'Submitting...' : 'Register for Tournament',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
