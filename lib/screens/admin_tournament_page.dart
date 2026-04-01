import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../models/tournament.dart';
import '../models/tournament_division.dart';
import '../models/tournament_registration.dart';
import '../services/registration_service.dart';
import '../services/tournament_service.dart';
import '../controllers/session_controller.dart';
import '../widgets/worldscore_header.dart';

class AdminTournamentPage extends StatefulWidget {
  const AdminTournamentPage({this.sessionController, super.key});

  final SessionController? sessionController;

  @override
  State<AdminTournamentPage> createState() => _AdminTournamentPageState();
}

class _AdminTournamentPageState extends State<AdminTournamentPage> {
  static const Color _backgroundColor = Color(0xFF031C14);
  static const Color _panelColor = Color(0xFF093823);
  static const Color _panelBorderColor = Color(0xFF137A48);
  static const Color _headingColor = Color(0xFF3CE081);
  static const Color _bodyTextColor = Color(0xFF7EA699);
  static const Color _accentSurfaceColor = Color(0xFF083A28);
  static const Color _errorTextColor = Color(0xFFFF9B9B);

  final TournamentService _tournamentService = TournamentService();
  final RegistrationService _registrationService = RegistrationService();

  String? get _currentDirectorUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _openTournamentForm({
    Tournament? initialValue,
    required String title,
    required String submitLabel,
    required Future<void> Function(TournamentDraft value) onSubmit,
  }) async {
    final nameController = TextEditingController(text: initialValue?.name ?? '');
    final locationController = TextEditingController(text: initialValue?.location ?? '');
    final maxPlayersController = TextEditingController(
      text: (initialValue?.maxPlayers ?? 40).toString(),
    );
    var eventDate = initialValue?.eventDate;
    var registrationDeadline = initialValue?.registrationDeadline;
    var inviteOnly = initialValue?.inviteOnly ?? false;
    var registrationOpen = initialValue?.registrationOpen ?? true;
    var numberOfRounds = initialValue?.numberOfRounds ?? 4;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickEventDate() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 4),
                initialDate: eventDate ?? now,
              );
              if (picked != null) {
                setStateDialog(() => eventDate = picked);
              }
            }

            Future<void> pickDeadline() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 4),
                initialDate: registrationDeadline ?? now,
              );
              if (picked != null) {
                setStateDialog(() => registrationDeadline = picked);
              }
            }

            return AlertDialog(
              backgroundColor: _panelColor,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: _panelBorderColor),
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(title, style: const TextStyle(color: _headingColor)),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Tournament name',
                          labelStyle: TextStyle(color: _bodyTextColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          labelStyle: TextStyle(color: _bodyTextColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: maxPlayersController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Max players',
                          labelStyle: TextStyle(color: _bodyTextColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: numberOfRounds,
                        dropdownColor: _panelColor,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Number of rounds',
                          labelStyle: TextStyle(color: _bodyTextColor),
                        ),
                        items: List.generate(
                          4,
                          (index) => DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text('${index + 1}'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => numberOfRounds = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Event date', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          eventDate == null ? 'Not selected' : _displayDate(eventDate!),
                          style: const TextStyle(color: _bodyTextColor),
                        ),
                        trailing: TextButton(
                          onPressed: pickEventDate,
                          style: TextButton.styleFrom(foregroundColor: _headingColor),
                          child: const Text('Select'),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Registration deadline',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          registrationDeadline == null
                              ? 'Not selected'
                              : _displayDate(registrationDeadline!),
                          style: const TextStyle(color: _bodyTextColor),
                        ),
                        trailing: TextButton(
                          onPressed: pickDeadline,
                          style: TextButton.styleFrom(foregroundColor: _headingColor),
                          child: const Text('Select'),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: registrationOpen,
                        onChanged: (value) => setStateDialog(() => registrationOpen = value),
                        title: const Text(
                          'Registration open',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: inviteOnly,
                        onChanged: (value) => setStateDialog(() => inviteOnly = value),
                        title: const Text(
                          'Invite only',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Open link model today, invite-only checks can be added later.',
                          style: TextStyle(color: _bodyTextColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(foregroundColor: _bodyTextColor),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentSurfaceColor,
                    foregroundColor: _headingColor,
                    side: const BorderSide(color: _panelBorderColor),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final location = locationController.text.trim();
                    final maxPlayers = int.tryParse(maxPlayersController.text.trim());
                    if (name.isEmpty ||
                        location.isEmpty ||
                        eventDate == null ||
                        registrationDeadline == null ||
                        maxPlayers == null ||
                        maxPlayers <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please complete all required fields.')),
                      );
                      return;
                    }

                    await onSubmit(
                      TournamentDraft(
                        name: name,
                        location: location,
                        eventDate: eventDate!,
                        registrationDeadline: registrationDeadline!,
                        maxPlayers: maxPlayers,
                        inviteOnly: inviteOnly,
                        registrationOpen: registrationOpen,
                        numberOfRounds: numberOfRounds,
                      ),
                    );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(submitLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createTournament() async {
    final userId = _currentDirectorUserId;
    if (userId == null || userId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in as a director before creating a tournament.'),
        ),
      );
      return;
    }

    await _openTournamentForm(
      title: 'Create Tournament',
      submitLabel: 'Create',
      onSubmit: (draft) async {
        final created = await _tournamentService.createTournament(
          name: draft.name,
          directorUserId: userId,
          eventDate: draft.eventDate,
          location: draft.location,
          registrationDeadline: draft.registrationDeadline,
          maxPlayers: draft.maxPlayers,
          inviteOnly: draft.inviteOnly,
          numberOfRounds: draft.numberOfRounds,
        );

        if (!mounted) {
          return;
        }

        if (!draft.registrationOpen) {
          await _tournamentService.updateTournament(
            Tournament(
              tournamentId: created.tournamentId,
              name: created.name,
              directorUserId: created.directorUserId,
              createdAt: created.createdAt,
              eventDate: created.eventDate,
              location: created.location,
              registrationOpen: false,
              registrationDeadline: created.registrationDeadline,
              maxPlayers: created.maxPlayers,
              currentPlayerCount: created.currentPlayerCount,
              publicRegistrationSlug: created.publicRegistrationSlug,
              inviteOnly: created.inviteOnly,
              numberOfRounds: created.numberOfRounds,
              status: TournamentStatus.draft,
            ),
          );
        }

        await _shareInviteLink(created, showSheet: false);
      },
    );
  }

  Future<void> _shareInviteLink(Tournament tournament, {bool showSheet = true}) async {
    final link = _tournamentService.buildPublicRegistrationLink(tournament.publicRegistrationSlug);
    await Clipboard.setData(ClipboardData(text: link));
    if (showSheet) {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Register for ${tournament.name}: $link',
          subject: 'Tournament registration invite',
        ),
      );
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite link copied to clipboard.')),
    );
  }

  Future<void> _showRegistrants(Tournament tournament) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panelColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrants · ${tournament.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _headingColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentSurfaceColor,
                    foregroundColor: _headingColor,
                    side: const BorderSide(color: _panelBorderColor),
                  ),
                  onPressed: () => _openManualRegistrantForm(tournament),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add player'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<TournamentRegistration>>(
                    stream: _registrationService.streamRegistrants(tournament.tournamentId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Text(
                          'Unable to load registrants.',
                          style: TextStyle(color: _errorTextColor),
                        );
                      }

                      final registrants = snapshot.data ?? [];
                      if (registrants.isEmpty) {
                        return const Text(
                          'No players registered yet.',
                          style: TextStyle(color: _bodyTextColor),
                        );
                      }

                      return ListView.separated(
                        itemCount: registrants.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final registrant = registrants[index];
                          return ListTile(
                            title: Text(
                              registrant.playerName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Status: ${registrant.status.name} · ${_displayDateTime(registrant.createdAt)}',
                              style: const TextStyle(color: _bodyTextColor),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openManualRegistrantForm(Tournament tournament) async {
    final playerNameController = TextEditingController();
    final handicapController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _panelColor,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _panelBorderColor),
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Add player to registrations',
            style: TextStyle(color: _headingColor),
          ),
          content: SizedBox(
            width: 540,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: playerNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Player name',
                    labelStyle: TextStyle(color: _bodyTextColor),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    labelStyle: TextStyle(color: _bodyTextColor),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: handicapController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Handicap',
                    labelStyle: TextStyle(color: _bodyTextColor),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    labelStyle: TextStyle(color: _bodyTextColor),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: _bodyTextColor),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accentSurfaceColor,
                foregroundColor: _headingColor,
                side: const BorderSide(color: _panelBorderColor),
              ),
              onPressed: () async {
                final playerName = playerNameController.text.trim();
                final handicapText = handicapController.text.trim();
                final email = emailController.text.trim();
                final phone = phoneController.text.trim();
                final handicap = double.tryParse(handicapText);

                if (playerName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Player name is required.')),
                  );
                  return;
                }
                if (handicap == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Handicap is required.')),
                  );
                  return;
                }

                try {
                  await _registrationService.addManualRegistrant(
                    tournament: tournament,
                    playerName: playerName,
                    handicap: handicap,
                    email: email.isEmpty ? null : email,
                    phone: phone.isEmpty ? null : phone,
                  );
                  if (!mounted) {
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$playerName added to registrations.')),
                  );
                } on TournamentRegistrationException catch (error) {
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.message)));
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDivisions(Tournament tournament) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panelColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.80,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Divisions · ${tournament.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _headingColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentSurfaceColor,
                    foregroundColor: _headingColor,
                    side: const BorderSide(color: _panelBorderColor),
                  ),
                  onPressed: () => _openDivisionForm(tournament),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Division'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<TournamentDivision>>(
                    stream: _tournamentService.streamDivisions(tournament.tournamentId),
                    builder: (context, divisionSnapshot) {
                      if (divisionSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (divisionSnapshot.hasError) {
                        return const Text(
                          'Unable to load divisions.',
                          style: TextStyle(color: _errorTextColor),
                        );
                      }

                      final divisions = divisionSnapshot.data ?? [];
                      if (divisions.isEmpty) {
                        return const Text(
                          'No divisions created yet. Add a division to distribute players by handicap.',
                          style: TextStyle(color: _bodyTextColor),
                        );
                      }

                      return StreamBuilder<List<TournamentRegistration>>(
                        stream: _registrationService.streamRegistrants(tournament.tournamentId),
                        builder: (context, regSnapshot) {
                          final registrants = regSnapshot.data ?? [];

                          return ListView.separated(
                            itemCount: divisions.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final division = divisions[index];
                              final players = registrants.where((r) {
                                final h = r.handicap;
                                if (h == null) return false;
                                return h >= division.minHandicap && h <= division.maxHandicap;
                              }).toList();

                              return Card(
                                color: _accentSurfaceColor,
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(color: _panelBorderColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ExpansionTile(
                                  iconColor: _headingColor,
                                  collapsedIconColor: _bodyTextColor,
                                  title: Text(
                                    division.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Handicap: ${division.minHandicap} – ${division.maxHandicap}  ·  ${players.length} player${players.length == 1 ? '' : 's'}',
                                    style: const TextStyle(color: _bodyTextColor),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit Division',
                                        icon: const Icon(Icons.edit_outlined, color: _headingColor, size: 20),
                                        onPressed: () => _openDivisionForm(tournament, existing: division),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete Division',
                                        icon: const Icon(Icons.delete_outline, color: _errorTextColor, size: 20),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: _panelColor,
                                              title: const Text('Delete Division', style: TextStyle(color: _headingColor)),
                                              content: Text(
                                                'Delete "${division.name}"? Players will not be removed from the tournament.',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(false),
                                                  style: TextButton.styleFrom(foregroundColor: _bodyTextColor),
                                                  child: const Text('Cancel'),
                                                ),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: const Color(0xFF5C1A1A),
                                                    foregroundColor: _errorTextColor,
                                                  ),
                                                  onPressed: () => Navigator.of(ctx).pop(true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await _tournamentService.deleteDivision(
                                              tournamentId: tournament.tournamentId,
                                              divisionId: division.divisionId,
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                  children: [
                                    if (players.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Text(
                                          'No players in this division.',
                                          style: TextStyle(color: _bodyTextColor),
                                        ),
                                      )
                                    else
                                      ...players.map(
                                        (p) => ListTile(
                                          dense: true,
                                          title: Text(p.playerName, style: const TextStyle(color: Colors.white)),
                                          trailing: Text(
                                            'HCP ${p.handicap?.toStringAsFixed(1) ?? '—'}',
                                            style: const TextStyle(color: _bodyTextColor),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDivisionForm(Tournament tournament, {TournamentDivision? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final minController = TextEditingController(
      text: existing != null ? existing.minHandicap.toString() : '',
    );
    final maxController = TextEditingController(
      text: existing != null ? existing.maxHandicap.toString() : '',
    );
    final isEditing = existing != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _panelColor,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _panelBorderColor),
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            isEditing ? 'Edit Division' : 'Add Division',
            style: const TextStyle(color: _headingColor),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Division name',
                    labelStyle: TextStyle(color: _bodyTextColor),
                    hintText: 'e.g. A Flight',
                    hintStyle: TextStyle(color: Color(0xFF4A7A66)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: minController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Minimum handicap',
                    labelStyle: TextStyle(color: _bodyTextColor),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: maxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Maximum handicap',
                    labelStyle: TextStyle(color: _bodyTextColor),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: _bodyTextColor),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accentSurfaceColor,
                foregroundColor: _headingColor,
                side: const BorderSide(color: _panelBorderColor),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final min = double.tryParse(minController.text.trim());
                final max = double.tryParse(maxController.text.trim());

                if (name.isEmpty || min == null || max == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields.')),
                  );
                  return;
                }
                if (min > max) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Minimum handicap cannot exceed maximum.')),
                  );
                  return;
                }

                if (isEditing) {
                  await _tournamentService.updateDivision(
                    TournamentDivision(
                      divisionId: existing.divisionId,
                      tournamentId: tournament.tournamentId,
                      name: name,
                      minHandicap: min,
                      maxHandicap: max,
                    ),
                  );
                } else {
                  await _tournamentService.addDivision(
                    tournamentId: tournament.tournamentId,
                    name: name,
                    minHandicap: min,
                    maxHandicap: max,
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExistingTournamentsSection(String? directorUserId) {
    return Card(
      color: _panelColor,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _panelBorderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Existing Tournaments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _headingColor,
              ),
            ),
            const SizedBox(height: 12),
            if (directorUserId == null || directorUserId.isEmpty)
              const Text(
                'Sign in to view your tournaments.',
                style: TextStyle(color: _bodyTextColor),
              )
            else
              StreamBuilder<List<Tournament>>(
                stream: _tournamentService.streamDirectorTournaments(directorUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Unable to load tournaments.',
                      style: TextStyle(color: _errorTextColor),
                    );
                  }

                  final tournaments = snapshot.data ?? [];
                  if (tournaments.isEmpty) {
                    return const Text(
                      'No tournaments created yet.',
                      style: TextStyle(color: _bodyTextColor),
                    );
                  }

                  return Column(
                    children: tournaments
                        .map(
                          (tournament) => Card(
                            color: _accentSurfaceColor,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: _panelBorderColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                tournament.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${_displayDate(tournament.eventDate)} · ${tournament.location}\n'
                                'Status: ${tournament.status.name} | '
                                'Players: ${tournament.currentPlayerCount}/${tournament.maxPlayers}',
                                style: const TextStyle(color: _bodyTextColor),
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    tooltip: 'Share Invite Link',
                                    onPressed: () => _shareInviteLink(tournament),
                                    icon: const Icon(Icons.share_outlined, color: _headingColor),
                                  ),
                                  IconButton(
                                    tooltip: 'View Registrants',
                                    onPressed: () => _showRegistrants(tournament),
                                    icon: const Icon(Icons.group_outlined, color: _headingColor),
                                  ),
                                  IconButton(
                                    tooltip: 'Manage Divisions',
                                    onPressed: () => _showDivisions(tournament),
                                    icon: const Icon(Icons.category_outlined, color: _headingColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final directorUserId = _currentDirectorUserId;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: _AdminHeaderSection(sessionController: widget.sessionController),
            ),
            const SizedBox(height: 14),
            _AdminSectionCard(
              title: 'Create a Tournament',
              subtitle:
                  'Create an event, open registration, and generate a shareable invite link.',
              buttonLabel: 'Create Tournament',
              onPressed: _createTournament,
            ),
            const SizedBox(height: 16),
            _buildExistingTournamentsSection(directorUserId),
          ],
        ),
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _AdminTournamentPageState._panelColor,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _AdminTournamentPageState._panelBorderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _AdminTournamentPageState._headingColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: _AdminTournamentPageState._bodyTextColor),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _AdminTournamentPageState._accentSurfaceColor,
                foregroundColor: _AdminTournamentPageState._headingColor,
                side: const BorderSide(color: _AdminTournamentPageState._panelBorderColor),
              ),
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHeaderSection extends StatelessWidget {
  const _AdminHeaderSection({this.sessionController});

  final SessionController? sessionController;

  @override
  Widget build(BuildContext context) {
    return WorldScoreHeader(
      subtitle: 'Tournament Administrator',
      role: WorldScoreRole.director,
      onBack: () => Navigator.of(context).pop(),
      sessionController: sessionController,
    );
  }
}

class TournamentDraft {
  const TournamentDraft({
    required this.name,
    required this.location,
    required this.eventDate,
    required this.registrationDeadline,
    required this.maxPlayers,
    required this.inviteOnly,
    required this.registrationOpen,
    required this.numberOfRounds,
  });

  final String name;
  final String location;
  final DateTime eventDate;
  final DateTime registrationDeadline;
  final int maxPlayers;
  final bool inviteOnly;
  final bool registrationOpen;
  final int numberOfRounds;
}

String _displayDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _displayDateTime(DateTime? date) {
  if (date == null) {
    return 'Pending';
  }
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$month-$day $hour:$minute';
}
