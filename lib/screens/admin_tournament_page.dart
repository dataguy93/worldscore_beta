import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/tournament.dart';

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

  final CollectionReference<Map<String, dynamic>> _tournamentCollection =
      FirebaseFirestore.instance.collection('tournaments');

  Future<void> _openTournamentForm({
    Tournament? initialValue,
    required String title,
    required String submitLabel,
    required Future<void> Function(Tournament value) onSubmit,
  }) async {
    final eventDate = ValueNotifier<DateTime?>(initialValue?.eventDate);
    final registrationDeadline = ValueNotifier<DateTime?>(
      initialValue?.registrationDeadline,
    );
    final rounds = ValueNotifier<int>(initialValue?.numberOfRounds ?? 1);
    final registrationOpen =
        ValueNotifier<bool>(initialValue?.registrationOpen ?? true);
    final inviteOnly = ValueNotifier<bool>(initialValue?.inviteOnly ?? false);
    final registrationMode = ValueNotifier<String>(
      initialValue?.publicRegistrationSlug != null ? 'slug' : 'token',
    );

    final nameController = TextEditingController(text: initialValue?.name ?? '');
    final directorUserIdController = TextEditingController(
      text: initialValue?.directorUserId ?? '',
    );
    final clubController = TextEditingController(
      text: initialValue?.clubOrCourseName ?? '',
    );
    final cityController = TextEditingController(text: initialValue?.city ?? '');
    final stateController = TextEditingController(text: initialValue?.state ?? '');
    final countryController = TextEditingController(
      text: initialValue?.country ?? '',
    );
    final maxPlayersController = TextEditingController(
      text: initialValue?.maxPlayers.toString() ?? '72',
    );
    final currentPlayersController = TextEditingController(
      text: initialValue?.currentPlayerCount.toString() ?? '0',
    );
    final slugController = TextEditingController(
      text: initialValue?.publicRegistrationSlug ?? '',
    );
    final tokenController = TextEditingController(
      text: initialValue?.registrationToken ?? '',
    );

    Future<void> pickDate({
      required ValueNotifier<DateTime?> target,
      required StateSetter setStateDialog,
      DateTime? firstDate,
    }) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        firstDate: firstDate ?? DateTime(now.year - 1),
        lastDate: DateTime(now.year + 4),
        initialDate: target.value ?? now,
      );

      if (picked != null) {
        setStateDialog(() {
          target.value = picked;
        });
      }
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: _panelColor,
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              contentTextStyle: const TextStyle(color: _bodyTextColor),
              title: Text(title),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _textField(nameController, 'Tournament name'),
                      const SizedBox(height: 10),
                      _textField(directorUserIdController, 'Director user ID'),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Event date',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          eventDate.value == null
                              ? 'No event date selected'
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
                      const SizedBox(height: 10),
                      _textField(clubController, 'Course / Club name'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _textField(cityController, 'City')),
                          const SizedBox(width: 8),
                          Expanded(child: _textField(stateController, 'State')),
                          const SizedBox(width: 8),
                          Expanded(child: _textField(countryController, 'Country')),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        value: registrationOpen.value,
                        onChanged: (value) =>
                            setStateDialog(() => registrationOpen.value = value),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Registration open',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Registration deadline',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          registrationDeadline.value == null
                              ? 'No registration deadline selected'
                              : _displayDate(registrationDeadline.value!),
                        ),
                        trailing: TextButton(
                          onPressed: () => pickDate(
                            target: registrationDeadline,
                            setStateDialog: setStateDialog,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                          ),
                          child: const Text('Select'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: rounds.value,
                        decoration: const InputDecoration(
                          labelText: 'Number of rounds (1-4)',
                        ),
                        items: List.generate(
                          4,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        selectedItemBuilder: (context) => List.generate(
                          4,
                          (index) => Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => rounds.value = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _textField(
                        maxPlayersController,
                        'Max players',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      _textField(
                        currentPlayersController,
                        'Current player count',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Public registration slug OR registration token',
                        style: TextStyle(color: Colors.white),
                      ),
                      RadioListTile<String>(
                        value: 'slug',
                        groupValue: registrationMode.value,
                        title: const Text(
                          'Use public registration slug',
                          style: TextStyle(color: Colors.white),
                        ),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => registrationMode.value = value);
                          }
                        },
                      ),
                      if (registrationMode.value == 'slug')
                        _textField(slugController, 'Public registration slug'),
                      RadioListTile<String>(
                        value: 'token',
                        groupValue: registrationMode.value,
                        title: const Text(
                          'Use private registration token',
                          style: TextStyle(color: Colors.white),
                        ),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => registrationMode.value = value);
                          }
                        },
                      ),
                      if (registrationMode.value == 'token')
                        _textField(tokenController, 'Registration token'),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: inviteOnly.value,
                        onChanged: (value) =>
                            setStateDialog(() => inviteOnly.value = value),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Invite only',
                          style: TextStyle(color: Colors.white),
                        ),
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
                    final currentPlayerCount = int.tryParse(
                      currentPlayersController.text.trim(),
                    );

                    final modeValue = registrationMode.value == 'slug'
                        ? slugController.text.trim()
                        : tokenController.text.trim();

                    if (nameController.text.trim().isEmpty ||
                        directorUserIdController.text.trim().isEmpty ||
                        eventDate.value == null ||
                        clubController.text.trim().isEmpty ||
                        cityController.text.trim().isEmpty ||
                        stateController.text.trim().isEmpty ||
                        countryController.text.trim().isEmpty ||
                        registrationDeadline.value == null ||
                        maxPlayers == null ||
                        currentPlayerCount == null ||
                        modeValue.isEmpty) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please complete all required tournament fields.',
                            ),
                          ),
                        );
                      return;
                    }

                    if (currentPlayerCount > maxPlayers) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Current player count cannot be greater than max players.',
                            ),
                          ),
                        );
                      return;
                    }

                    try {
                      await onSubmit(
                        Tournament(
                          tournamentId: initialValue?.tournamentId ??
                              _tournamentCollection.doc().id,
                          name: nameController.text.trim(),
                          directorUserId: directorUserIdController.text.trim(),
                          createdAt: initialValue?.createdAt,
                          eventDate: eventDate.value!,
                          clubOrCourseName: clubController.text.trim(),
                          country: countryController.text.trim(),
                          state: stateController.text.trim(),
                          city: cityController.text.trim(),
                          registrationOpen: registrationOpen.value,
                          registrationDeadline: registrationDeadline.value!,
                          numberOfRounds: rounds.value,
                          maxPlayers: maxPlayers,
                          currentPlayerCount: currentPlayerCount,
                          publicRegistrationSlug: registrationMode.value == 'slug'
                              ? slugController.text.trim()
                              : null,
                          registrationToken: registrationMode.value == 'token'
                              ? tokenController.text.trim()
                              : null,
                          inviteOnly: inviteOnly.value,
                        ),
                      );

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text('Unable to save tournament: $error')),
                        );
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

  void _createTournament() {
    _openTournamentForm(
      title: 'Create Tournament',
      submitLabel: 'Create',
      onSubmit: (tournament) async {
        await _tournamentCollection.doc(tournament.tournamentId).set(tournament.toMap());
      },
    );
  }

  void _editTournament(Tournament tournament) {
    _openTournamentForm(
      initialValue: tournament,
      title: 'Manage Existing Tournament',
      submitLabel: 'Save Changes',
      onSubmit: (updated) async {
        await _tournamentCollection
            .doc(updated.tournamentId)
            .update(updated.toMap());
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
      await _tournamentCollection.doc(tournament.tournamentId).delete();
    }
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
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Admin · Tournament Setup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
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
                  'Set event data, director ownership, registration controls, rounds, and capacity.',
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
                      'Change any tournament settings or delete a tournament you previously created.',
                      style: TextStyle(color: _bodyTextColor),
                    ),
                    const SizedBox(height: 14),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _tournamentCollection.orderBy('eventDate').snapshots(),
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

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Text(
                            'No tournaments created yet.',
                            style: TextStyle(color: _bodyTextColor),
                          );
                        }

                        return Column(
                          children: docs
                              .map((doc) => Tournament.fromDoc(doc))
                              .map(
                                (tournament) => Card(
                                  color: const Color(0xFF0F1D2E),
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
                                      '${_displayDate(tournament.eventDate)} · ${tournament.clubOrCourseName} (${tournament.city}, ${tournament.state}, ${tournament.country})',
                                      style: const TextStyle(color: _bodyTextColor),
                                    ),
                                    trailing: Wrap(
                                      spacing: 8,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit tournament',
                                          onPressed: () => _editTournament(tournament),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: _headingColor,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete tournament',
                                          onPressed: () => _deleteTournament(tournament),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Color(0xFFE57373),
                                          ),
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
            ),
          ],
        ),
      ),
    );
  }
}

Widget _textField(
  TextEditingController controller,
  String label, {
  TextInputType keyboardType = TextInputType.text,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _AdminTournamentPageState._bodyTextColor),
    ),
  );
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

String _displayDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
