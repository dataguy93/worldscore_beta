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

  String? get _currentGmUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _openTournamentForm({
    Tournament? initialValue,
    required String title,
    required String submitLabel,
    required Future<void> Function(TournamentDraft value) onSubmit,
  }) async {
    final nameController = TextEditingController(text: initialValue?.name ?? '');
    final locationController = TextEditingController(text: initialValue?.location ?? '');
    final maxProsController = TextEditingController(
      text: (initialValue?.maxPros ?? 40).toString(),
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
                        controller: maxProsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Max Players',
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
                    final maxPros = int.tryParse(maxProsController.text.trim());
                    if (name.isEmpty ||
                        location.isEmpty ||
                        eventDate == null ||
                        registrationDeadline == null ||
                        maxPros == null ||
                        maxPros <= 0) {
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
                        maxPros: maxPros,
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
    final userId = _currentGmUserId;
    if (userId == null || userId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in as a GM before creating a tournament.'),
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
          gmUserId: userId,
          eventDate: draft.eventDate,
          location: draft.location,
          registrationDeadline: draft.registrationDeadline,
          maxPros: draft.maxPros,
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
              gmUserId: created.gmUserId,
              createdAt: created.createdAt,
              eventDate: created.eventDate,
              location: created.location,
              registrationOpen: false,
              registrationDeadline: created.registrationDeadline,
              maxPros: created.maxPros,
              currentProCount: created.currentProCount,
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
                  label: const Text('Add PRO'),
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
                              registrant.proName,
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
    final proNameController = TextEditingController();
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
            'Add PRO to registrations',
            style: TextStyle(color: _headingColor),
          ),
          content: SizedBox(
            width: 540,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: proNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'PRO name',
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
                final proName = proNameController.text.trim();
                final handicapText = handicapController.text.trim();
                final email = emailController.text.trim();
                final phone = phoneController.text.trim();
                final handicap = double.tryParse(handicapText);

                if (proName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PRO name is required.')),
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
                    proName: proName,
                    handicap: handicap,
                    email: email.isEmpty ? null : email,
                    phone: phone.isEmpty ? null : phone,
                  );
                  if (!mounted) {
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$proName added to registrations.')),
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
                              final pros = registrants.where((r) {
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
                                    'Handicap: ${division.minHandicap} – ${division.maxHandicap}  ·  ${pros.length} Player${pros.length == 1 ? '' : 's'}',
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
                                    if (pros.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Text(
                                          'No PROs in this division.',
                                          style: TextStyle(color: _bodyTextColor),
                                        ),
                                      )
                                    else
                                      ...pros.map(
                                        (p) => ListTile(
                                          dense: true,
                                          title: Text(p.proName, style: const TextStyle(color: Colors.white)),
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

  Future<void> _confirmDeleteTournament(Tournament tournament) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panelColor,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _panelBorderColor),
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Delete Tournament', style: TextStyle(color: _headingColor)),
        content: Text(
          'Permanently delete "${tournament.name}"? This also removes its '
          'registrants, divisions, and uploaded round scores. This cannot be undone.',
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

    if (confirm != true) {
      return;
    }

    try {
      await _tournamentService.deleteTournament(tournament);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Deleted "${tournament.name}".')),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not delete tournament: $error')),
        );
    }
  }

  Future<void> _confirmCloseTournament(Tournament tournament) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panelColor,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _panelBorderColor),
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Close Tournament', style: TextStyle(color: _headingColor)),
        content: Text(
          'Close "${tournament.name}"? It will move to the Closed Tournaments '
          'section. You can still view its registrants and divisions.',
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
              backgroundColor: _accentSurfaceColor,
              foregroundColor: _headingColor,
              side: const BorderSide(color: _panelBorderColor),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      await _tournamentService.updateTournamentStatus(
        tournament.tournamentId,
        TournamentStatus.closed,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Closed "${tournament.name}".')),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not close tournament: $error')),
        );
    }
  }

  Future<void> _confirmReopenTournament(Tournament tournament) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panelColor,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _panelBorderColor),
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Re-open Tournament', style: TextStyle(color: _headingColor)),
        content: Text(
          'Re-open "${tournament.name}"? It will move back to the Open '
          'Tournaments section.',
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
              backgroundColor: _accentSurfaceColor,
              foregroundColor: _headingColor,
              side: const BorderSide(color: _panelBorderColor),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Re-open'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      await _tournamentService.updateTournamentStatus(
        tournament.tournamentId,
        TournamentStatus.open,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Re-opened "${tournament.name}".')),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not re-open tournament: $error')),
        );
    }
  }

  Widget _buildTournamentCard(Tournament tournament) {
    final isClosed = tournament.status == TournamentStatus.closed;

    return Card(
      color: _accentSurfaceColor,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _panelBorderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tournament.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_displayDate(tournament.eventDate)} · ${tournament.location}\n'
              'Status: ${_displayStatus(tournament.status)} | '
              'Players: ${tournament.currentProCount}/${tournament.maxPros}',
              style: const TextStyle(color: _bodyTextColor),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                if (isClosed)
                  IconButton(
                    tooltip: 'Re-open Tournament',
                    onPressed: () => _confirmReopenTournament(tournament),
                    icon: const Icon(Icons.lock_open_outlined, color: _headingColor),
                  )
                else
                  IconButton(
                    tooltip: 'Close Tournament',
                    onPressed: () => _confirmCloseTournament(tournament),
                    icon: const Icon(Icons.lock_outline, color: _headingColor),
                  ),
                IconButton(
                  tooltip: 'Delete Tournament',
                  onPressed: () => _confirmDeleteTournament(tournament),
                  icon: const Icon(Icons.delete_outline, color: _errorTextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentsSection({
    required String title,
    required String? gmUserId,
    required bool Function(Tournament) filter,
    required String emptyMessage,
  }) {
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _headingColor,
              ),
            ),
            const SizedBox(height: 12),
            if (gmUserId == null || gmUserId.isEmpty)
              const Text(
                'Sign in to view your tournaments.',
                style: TextStyle(color: _bodyTextColor),
              )
            else
              StreamBuilder<List<Tournament>>(
                stream: _tournamentService.streamGmTournaments(gmUserId),
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

                  final tournaments =
                      (snapshot.data ?? []).where(filter).toList();
                  if (tournaments.isEmpty) {
                    return Text(
                      emptyMessage,
                      style: const TextStyle(color: _bodyTextColor),
                    );
                  }

                  return Column(
                    children: tournaments.map(_buildTournamentCard).toList(),
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
    final gmUserId = _currentGmUserId;

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
            _buildTournamentsSection(
              title: 'Open Tournaments',
              gmUserId: gmUserId,
              filter: (tournament) => tournament.status != TournamentStatus.closed,
              emptyMessage: 'No open tournaments.',
            ),
            const SizedBox(height: 16),
            _buildTournamentsSection(
              title: 'Closed Tournaments',
              gmUserId: gmUserId,
              filter: (tournament) => tournament.status == TournamentStatus.closed,
              emptyMessage: 'No closed tournaments.',
            ),
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
      role: WorldScoreRole.gm,
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
    required this.maxPros,
    required this.inviteOnly,
    required this.registrationOpen,
    required this.numberOfRounds,
  });

  final String name;
  final String location;
  final DateTime eventDate;
  final DateTime registrationDeadline;
  final int maxPros;
  final bool inviteOnly;
  final bool registrationOpen;
  final int numberOfRounds;
}

String _displayStatus(TournamentStatus status) {
  final name = status.name;
  return name.isEmpty ? name : '${name[0].toUpperCase()}${name.substring(1)}';
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
