import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/session_controller.dart';
import '../models/tournament.dart';
import '../models/tournament_registration.dart';
import '../services/registration_service.dart';
import '../services/tournament_service.dart';
import 'auth/sign_in_page.dart';
import 'auth/sign_up_page.dart';

class TournamentRegistrationPage extends StatefulWidget {
  const TournamentRegistrationPage({
    required this.sessionController,
    super.key,
    this.slug,
    this.tournamentId,
  });

  final SessionController sessionController;
  final String? slug;
  final String? tournamentId;

  @override
  State<TournamentRegistrationPage> createState() => _TournamentRegistrationPageState();
}

class _TournamentRegistrationPageState extends State<TournamentRegistrationPage> {
  final TournamentService _tournamentService = TournamentService();
  final RegistrationService _registrationService = RegistrationService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  Tournament? _tournament;
  TournamentRegistration? _existingRegistration;

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

      final userId = FirebaseAuth.instance.currentUser?.uid;
      final existing = userId == null
          ? null
          : await _registrationService.getRegistrationForUser(
              tournamentId: tournament.tournamentId,
              userId: userId,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _tournament = tournament;
        _existingRegistration = existing;
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
    return null;
  }

  Future<void> _goToSignInAndContinue() async {
    final tournament = _tournament;
    if (tournament == null) {
      return;
    }

    final route = '/tournaments/${tournament.tournamentId}/register';
    widget.sessionController.setPendingRouteAfterAuth(route);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SignInPage(
          sessionController: widget.sessionController,
          onAuthSuccess: () {
            final pending = widget.sessionController.consumePendingRouteAfterAuth();
            if (pending != null) {
              Navigator.of(context)
                ..pop()
                ..pushReplacementNamed(pending);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );

    if (mounted) {
      await _loadTournament();
    }
  }

  Future<void> _goToSignUpAndContinue() async {
    final tournament = _tournament;
    if (tournament == null) {
      return;
    }

    final route = '/tournaments/${tournament.tournamentId}/register';
    widget.sessionController.setPendingRouteAfterAuth(route);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SignUpPage(
          sessionController: widget.sessionController,
          onAuthSuccess: () {
            final pending = widget.sessionController.consumePendingRouteAfterAuth();
            if (pending != null) {
              Navigator.of(context)
                ..pop()
                ..pushReplacementNamed(pending);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );

    if (mounted) {
      await _loadTournament();
    }
  }

  Future<void> _submitRegistration() async {
    final tournament = _tournament;
    if (tournament == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await _goToSignInAndContinue();
      return;
    }

    final playerName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : widget.sessionController.profile?.fullName ?? user.email ?? 'Player';
    final playerEmail = user.email?.trim() ?? '';

    if (playerEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account must include an email to register.')),
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
      final result = await _registrationService.registerForTournament(
        tournament: tournament,
        user: user,
        playerName: playerName,
        playerEmail: playerEmail,
      );

      if (!mounted) {
        return;
      }

      final message = result.assignedStatus == RegistrationStatus.waitlisted
          ? 'Tournament is full. You have been placed on the waitlist.'
          : 'Registration successful.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
  Widget build(BuildContext context) {
    final tournament = _tournament;
    final availabilityError = tournament == null ? null : _validateTournamentAvailability(tournament);
    final signedInUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Registration')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
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
                                  Text('Course: ${tournament.location}'),
                                  Text('Event Date: ${_dateLabel(tournament.eventDate)}'),
                                  Text(
                                    'Registration Deadline: ${_dateLabel(tournament.registrationDeadline)}',
                                  ),
                                  Text('Entry Fee: TBD'),
                                  Text(
                                    'Spots Remaining: ${tournament.maxPlayers - tournament.currentPlayerCount}',
                                  ),
                                  const SizedBox(height: 14),
                                  if (_existingRegistration != null) ...[
                                    Text(
                                      _existingRegistration!.status == RegistrationStatus.waitlisted
                                          ? 'You are already waitlisted for this tournament.'
                                          : 'You are already registered for this tournament.',
                                      style: const TextStyle(color: Colors.green),
                                    ),
                                  ] else if (availabilityError != null) ...[
                                    Text(
                                      tournament.currentPlayerCount >= tournament.maxPlayers
                                          ? 'Tournament is full. You can still join the waitlist.'
                                          : availabilityError,
                                      style: const TextStyle(color: Colors.redAccent),
                                    ),
                                  ] else if (signedInUser == null) ...[
                                    const Text(
                                      'Sign in or create an account to complete registration.',
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 12,
                                      children: [
                                        FilledButton(
                                          onPressed: _goToSignInAndContinue,
                                          child: const Text('Sign In to Register'),
                                        ),
                                        OutlinedButton(
                                          onPressed: _goToSignUpAndContinue,
                                          child: const Text('Create Account'),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    FilledButton(
                                      onPressed: _isSubmitting ? null : _submitRegistration,
                                      child: Text(
                                        _isSubmitting
                                            ? 'Submitting...'
                                            : tournament.currentPlayerCount >= tournament.maxPlayers
                                                ? 'Join Waitlist'
                                                : 'Register',
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
