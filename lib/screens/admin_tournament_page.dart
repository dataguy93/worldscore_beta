import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/tournament.dart';
import '../models/tournament_registration.dart';
import '../services/registration_link_service.dart';
import '../services/tournament_service.dart';

class AdminTournamentPage extends StatefulWidget {
  const AdminTournamentPage({super.key});

  @override
  State<AdminTournamentPage> createState() => _AdminTournamentPageState();
}

class _AdminTournamentPageState extends State<AdminTournamentPage> {
  static const Color _backgroundColor = Color(0xFF0D1B2A);
  static const Color _panelColor = Color(0xFF142234);
  static const Color _panelBorderColor = Color(0xFF1F3A56);
  static const Color _headingColor = Color(0xFF4FC3F7);
  static const Color _bodyTextColor = Color(0xFF9FB3C8);

  final TournamentService _tournamentService = TournamentService();
  final RegistrationLinkService _registrationLinkService =
      const RegistrationLinkService();

  String get _directorUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous-director';

  Future<void> _openTournamentForm({
    _TournamentFormValue? initialValue,
    required String title,
    required String submitLabel,
    required Future<void> Function(_TournamentFormValue value) onSubmit,
  }) async {
    final eventDate = ValueNotifier<DateTime?>(initialValue?.eventDate);
    final registrationDeadline =
        ValueNotifier<DateTime?>(initialValue?.registrationDeadline);
    final rounds = ValueNotifier<int>(initialValue?.roundCount ?? 1);
    final eventType = ValueNotifier<String>(initialValue?.eventType ?? 'Singles');
    var registrationOpen = initialValue?.registrationOpen ?? true;
    var inviteOnly = initialValue?.inviteOnly ?? false;
    var status = initialValue?.status ?? TournamentStatus.open;

    final tournamentNameController =
        TextEditingController(text: initialValue?.name ?? '');
    final locationController =
        TextEditingController(text: initialValue?.location ?? '');
    final maxPlayersController =
        TextEditingController(text: (initialValue?.maxPlayers ?? 72).toString());

    final roundFormats = [...?initialValue?.roundFormats];
    if (roundFormats.isEmpty) {
      roundFormats.add('Stroke Play');
    }

    Future<void> pickDate({
      required ValueNotifier<DateTime?> target,
      required StateSetter setStateDialog,
    }) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 4),
        initialDate: target.value ?? now,
      );
      if (picked != null) {
        setStateDialog(() => target.value = picked);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            while (roundFormats.length < rounds.value) {
              roundFormats.add('Round ${roundFormats.length + 1} Format');
            }
            while (roundFormats.length > rounds.value) {
              roundFormats.removeLast();
            }

            return AlertDialog(
              backgroundColor: _panelColor,
              title: Text(title, style: const TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: tournamentNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Tournament name',
                          labelStyle: TextStyle(color: _bodyTextColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Event date',
                            style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          eventDate.value == null
                              ? 'No date selected'
                              : _displayDate(eventDate.value!),
                        ),
                        trailing: TextButton(
                          onPressed: () => pickDate(
                            target: eventDate,
                            setStateDialog: setStateDialog,
                          ),
                          child: const Text('Select'),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Registration deadline',
                            style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          registrationDeadline.value == null
                              ? 'No deadline selected'
                              : _displayDate(registrationDeadline.value!),
                        ),
                        trailing: TextButton(
                          onPressed: () => pickDate(
                            target: registrationDeadline,
                            setStateDialog: setStateDialog,
                          ),
                          child: const Text('Select'),
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
                      SwitchListTile(
                        value: registrationOpen,
                        onChanged: (value) =>
                            setStateDialog(() => registrationOpen = value),
                        title: const Text('Registration open',
                            style: TextStyle(color: Colors.white)),
                      ),
                      SwitchListTile(
                        value: inviteOnly,
                        onChanged: (value) =>
                            setStateDialog(() => inviteOnly = value),
                        title: const Text('Invite only',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TournamentStatus>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: TournamentStatus.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => status = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: rounds.value,
                        decoration: const InputDecoration(
                          labelText: 'Number of rounds',
                        ),
                        items: List.generate(
                          4,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1}'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => rounds.value = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text('Format options for each round',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      ...List.generate(
                        rounds.value,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextFormField(
                            initialValue: roundFormats[index],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Round ${index + 1} format',
                              labelStyle:
                                  const TextStyle(color: _bodyTextColor),
                            ),
                            onChanged: (value) => roundFormats[index] = value,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Event type',
                          style: TextStyle(color: Colors.white)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'Singles',
                              groupValue: eventType.value,
                              title: const Text('Singles',
                                  style: TextStyle(color: Colors.white)),
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) {
                                if (value != null) {
                                  setStateDialog(() => eventType.value = value);
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'Group',
                              groupValue: eventType.value,
                              title: const Text('Group',
                                  style: TextStyle(color: Colors.white)),
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) {
                                if (value != null) {
                                  setStateDialog(() => eventType.value = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final maxPlayers = int.tryParse(maxPlayersController.text.trim());
                    if (tournamentNameController.text.trim().isEmpty ||
                        eventDate.value == null ||
                        registrationDeadline.value == null ||
                        locationController.text.trim().isEmpty ||
                        maxPlayers == null ||
                        maxPlayers <= 0) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please complete all required fields.'),
                          ),
                        );
                      return;
                    }

                    await onSubmit(
                      _TournamentFormValue(
                        tournamentId: initialValue?.tournamentId ??
                            FirebaseFirestore.instance.collection('tournaments').doc().id,
                        name: tournamentNameController.text.trim(),
                        eventDate: eventDate.value!,
                        location: locationController.text.trim(),
                        registrationOpen: registrationOpen,
                        registrationDeadline: registrationDeadline.value!,
                        maxPlayers: maxPlayers,
                        currentPlayerCount: initialValue?.currentPlayerCount ?? 0,
                        inviteOnly: inviteOnly,
                        status: status,
                        roundCount: rounds.value,
                        roundFormats: roundFormats,
                        eventType: eventType.value,
                        publicRegistrationSlug: initialValue?.publicRegistrationSlug ??
                            _tournamentService.generatePublicSlug(
                              tournamentNameController.text.trim(),
                            ),
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
    await _openTournamentForm(
      title: 'Create Tournament',
      submitLabel: 'Create',
      onSubmit: (form) async {
        final tournament = Tournament(
          tournamentId: form.tournamentId,
          name: form.name,
          directorUserId: _directorUserId,
          createdAt: DateTime.now(),
          eventDate: form.eventDate,
          location: form.location,
          registrationOpen: form.registrationOpen,
          registrationDeadline: form.registrationDeadline,
          maxPlayers: form.maxPlayers,
          currentPlayerCount: form.currentPlayerCount,
          publicRegistrationSlug: form.publicRegistrationSlug,
          inviteOnly: form.inviteOnly,
          status: form.status,
          roundCount: form.roundCount,
          roundFormats: form.roundFormats,
          eventType: form.eventType,
        );
        await _tournamentService.createTournament(tournament);
        if (!mounted) {
          return;
        }
        final link = _registrationLinkService.buildRegistrationLink(
          slug: tournament.publicRegistrationSlug,
        );
        _showSnack('Tournament created. Invite link copied to clipboard.');
        await _registrationLinkService.copyToClipboard(link);
      },
    );
  }

  Future<void> _editTournament(Tournament tournament) async {
    await _openTournamentForm(
      initialValue: _TournamentFormValue.fromTournament(tournament),
      title: 'Manage Existing Tournament',
      submitLabel: 'Save Changes',
      onSubmit: (form) async {
        await FirebaseFirestore.instance
            .collection('tournaments')
            .doc(form.tournamentId)
            .update(form.toMapForUpdate());
      },
    );
  }

  Future<void> _deleteTournament(Tournament tournament) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tournament'),
        backgroundColor: _panelColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(color: _bodyTextColor),
        content: Text('Delete "${tournament.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournament.tournamentId)
          .delete();
    }
  }

  Future<void> _shareInviteLink(Tournament tournament) async {
    final link = _registrationLinkService.buildRegistrationLink(
      slug: tournament.publicRegistrationSlug,
    );
    await _registrationLinkService.copyToClipboard(link);
    // Future extension: add native share-sheet (share_plus), email, or SMS sender.
    _showSnack('Invite link copied: $link');
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
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2E44), Color(0xFF223F5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFF355C84)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back to Director Home',
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Admin · Tournament Setup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _AdminSectionCard(
              title: 'Create a Tournament',
              subtitle:
                  'Create tournaments with public registration links and capacity controls.',
              buttonLabel: 'Create Tournament',
              onPressed: _createTournament,
            ),
            const SizedBox(height: 16),
            Card(
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
                      'Manage Existing Tournament',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _headingColor,
                      ),
                    ),
                    const Text(
                      'Edit tournament settings, copy invite links, and monitor registrants.',
                      style: TextStyle(color: _bodyTextColor),
                    ),
                    const SizedBox(height: 14),
                    StreamBuilder<List<Tournament>>(
                      stream: _tournamentService
                          .watchDirectorTournaments(_directorUserId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text(
                            'Unable to load tournaments.',
                            style: TextStyle(color: Color(0xFFE57373)),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final tournaments = snapshot.data ?? <Tournament>[];
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
                                  color: const Color(0xFF0F1D2E),
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                        color: _panelBorderColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ExpansionTile(
                                    title: Text(
                                      tournament.name,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      '${_displayDate(tournament.eventDate)} · ${tournament.location}\n'
                                      'Status: ${tournament.statusLabel} · Registrants: ${tournament.currentPlayerCount}/${tournament.maxPlayers}',
                                      style: const TextStyle(
                                          color: _bodyTextColor),
                                    ),
                                    trailing: Wrap(
                                      spacing: 8,
                                      children: [
                                        IconButton(
                                          tooltip: 'Share invite link',
                                          onPressed: () =>
                                              _shareInviteLink(tournament),
                                          icon: const Icon(Icons.share,
                                              color: _headingColor),
                                        ),
                                        IconButton(
                                          tooltip: 'Edit tournament',
                                          onPressed: () =>
                                              _editTournament(tournament),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: _headingColor,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete tournament',
                                          onPressed: () =>
                                              _deleteTournament(tournament),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Color(0xFFE57373),
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 12),
                                        child: _RegistrantListSection(
                                          tournamentId:
                                              tournament.tournamentId,
                                          tournamentService:
                                              _tournamentService,
                                        ),
                                      ),
                                    ],
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
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrantListSection extends StatelessWidget {
  const _RegistrantListSection({
    required this.tournamentId,
    required this.tournamentService,
  });

  final String tournamentId;
  final TournamentService tournamentService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TournamentRegistration>>(
      stream: tournamentService.watchRegistrationsForTournament(tournamentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Unable to load registrants.',
            style: TextStyle(color: Color(0xFFE57373)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final registrations = snapshot.data ?? <TournamentRegistration>[];
        if (registrations.isEmpty) {
          return const Text(
            'No registrants yet.',
            style: TextStyle(color: _AdminTournamentPageState._bodyTextColor),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrants',
              style: TextStyle(
                color: _AdminTournamentPageState._headingColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...registrations.map(
              (registration) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  registration.playerName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${registration.status.name} · ${_displayDateTime(registration.createdAt)}',
                  style: const TextStyle(
                      color: _AdminTournamentPageState._bodyTextColor),
                ),
              ),
            ),
          ],
        );
      },
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
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentFormValue {
  const _TournamentFormValue({
    required this.tournamentId,
    required this.name,
    required this.eventDate,
    required this.location,
    required this.registrationOpen,
    required this.registrationDeadline,
    required this.maxPlayers,
    required this.currentPlayerCount,
    required this.publicRegistrationSlug,
    required this.inviteOnly,
    required this.status,
    required this.roundCount,
    required this.roundFormats,
    required this.eventType,
  });

  final String tournamentId;
  final String name;
  final DateTime eventDate;
  final String location;
  final bool registrationOpen;
  final DateTime registrationDeadline;
  final int maxPlayers;
  final int currentPlayerCount;
  final String publicRegistrationSlug;
  final bool inviteOnly;
  final TournamentStatus status;
  final int roundCount;
  final List<String> roundFormats;
  final String eventType;

  factory _TournamentFormValue.fromTournament(Tournament tournament) {
    return _TournamentFormValue(
      tournamentId: tournament.tournamentId,
      name: tournament.name,
      eventDate: tournament.eventDate,
      location: tournament.location,
      registrationOpen: tournament.registrationOpen,
      registrationDeadline: tournament.registrationDeadline,
      maxPlayers: tournament.maxPlayers,
      currentPlayerCount: tournament.currentPlayerCount,
      publicRegistrationSlug: tournament.publicRegistrationSlug,
      inviteOnly: tournament.inviteOnly,
      status: tournament.status,
      roundCount: tournament.roundCount,
      roundFormats: tournament.roundFormats,
      eventType: tournament.eventType,
    );
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'name': name,
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location,
      'registrationOpen': registrationOpen,
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'maxPlayers': maxPlayers,
      'currentPlayerCount': currentPlayerCount,
      'publicRegistrationSlug': publicRegistrationSlug,
      'inviteOnly': inviteOnly,
      'status': status.name,
      'roundCount': roundCount,
      'roundFormats': roundFormats,
      'eventType': eventType,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

String _displayDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _displayDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$month-$day $hour:$minute';
}
