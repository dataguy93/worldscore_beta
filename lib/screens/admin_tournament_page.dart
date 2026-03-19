import 'package:flutter/material.dart';

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
  final List<_TournamentConfig> _tournaments = [];

  Future<void> _openTournamentForm({
    _TournamentConfig? initialValue,
    required String title,
    required String submitLabel,
    required void Function(_TournamentConfig value) onSubmit,
  }) async {
    final startDate = ValueNotifier<DateTime?>(initialValue?.startDate);
    final rounds = ValueNotifier<int>(initialValue?.roundCount ?? 1);
    final eventType = ValueNotifier<String>(initialValue?.eventType ?? 'Singles');

    final playerController = TextEditingController();
    final tournamentNameController = TextEditingController(text: initialValue?.name ?? '');
    final clubController = TextEditingController(text: initialValue?.clubOrCourse ?? '');
    final cityController = TextEditingController(text: initialValue?.city ?? '');
    final stateController = TextEditingController(text: initialValue?.state ?? '');
    final countryController = TextEditingController(text: initialValue?.country ?? '');

    final players = [...?initialValue?.registeredPlayers];
    final roundFormats = [...?initialValue?.roundFormats];
    if (roundFormats.isEmpty) {
      roundFormats.add('Stroke Play');
    }

    Future<void> pickStartDate(StateSetter setStateDialog) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 4),
        initialDate: startDate.value ?? now,
      );
      if (picked != null) {
        setStateDialog(() {
          startDate.value = picked;
        });
      }
    }

    if (!mounted) {
      return;
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
                        title: const Text('Start date', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          startDate.value == null
                              ? 'No start date selected'
                              : _displayDate(startDate.value!),
                        ),
                        trailing: TextButton(
                          onPressed: () => pickStartDate(setStateDialog),
                          child: const Text('Select'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Register player', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: playerController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Enter player name',
                                hintStyle: TextStyle(color: _bodyTextColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              final name = playerController.text.trim();
                              if (name.isEmpty) {
                                return;
                              }
                              setStateDialog(() {
                                players.add(name);
                                playerController.clear();
                              });
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: players
                            .map(
                              (player) => InputChip(
                                label: Text(player),
                                onDeleted: () {
                                  setStateDialog(() {
                                    players.remove(player);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        value: rounds.value,
                        decoration: const InputDecoration(
                          labelText: 'Number of rounds to be played',
                        ),
                        items: List.generate(
                          6,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1}'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              rounds.value = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: clubController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Club / Course name',
                          labelStyle: TextStyle(color: _bodyTextColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cityController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'City',
                                labelStyle: TextStyle(color: _bodyTextColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: stateController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'State',
                                labelStyle: TextStyle(color: _bodyTextColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: countryController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Country',
                                labelStyle: TextStyle(color: _bodyTextColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Format options for each round',
                        style: TextStyle(color: Colors.white),
                      ),
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
                              labelStyle: const TextStyle(color: _bodyTextColor),
                            ),
                            onChanged: (value) => roundFormats[index] = value,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Event type', style: TextStyle(color: Colors.white)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'Singles',
                              groupValue: eventType.value,
                              title: const Text('Singles'),
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
                              title: const Text('Group'),
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
                  onPressed: () {
                    if (tournamentNameController.text.trim().isEmpty ||
                        startDate.value == null ||
                        clubController.text.trim().isEmpty ||
                        cityController.text.trim().isEmpty ||
                        stateController.text.trim().isEmpty ||
                        countryController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Please complete all required tournament fields.'),
                          ),
                        );
                      return;
                    }

                    onSubmit(
                      _TournamentConfig(
                        id: initialValue?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                        name: tournamentNameController.text.trim(),
                        startDate: startDate.value!,
                        registeredPlayers: players,
                        roundCount: rounds.value,
                        clubOrCourse: clubController.text.trim(),
                        city: cityController.text.trim(),
                        state: stateController.text.trim(),
                        country: countryController.text.trim(),
                        roundFormats: roundFormats,
                        eventType: eventType.value,
                      ),
                    );
                    Navigator.of(dialogContext).pop();
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
      onSubmit: (tournament) {
        setState(() {
          _tournaments.add(tournament);
        });
      },
    );
  }

  void _editTournament(_TournamentConfig tournament) {
    _openTournamentForm(
      initialValue: tournament,
      title: 'Manage Existing Tournament',
      submitLabel: 'Save Changes',
      onSubmit: (updated) {
        setState(() {
          final index = _tournaments.indexWhere((item) => item.id == updated.id);
          if (index >= 0) {
            _tournaments[index] = updated;
          }
        });
      },
    );
  }

  Future<void> _deleteTournament(_TournamentConfig tournament) async {
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
      setState(() {
        _tournaments.removeWhere((item) => item.id == tournament.id);
      });
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
                  'Set start date, register players, choose rounds, course/location, round formats, and event type.',
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
                    if (_tournaments.isEmpty)
                      const Text(
                        'No tournaments created yet.',
                        style: TextStyle(color: _bodyTextColor),
                      )
                    else
                      ..._tournaments.map(
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
                              '${_displayDate(tournament.startDate)} · ${tournament.clubOrCourse} (${tournament.city}, ${tournament.state}, ${tournament.country})',
                              style: const TextStyle(color: _bodyTextColor),
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  tooltip: 'Edit tournament',
                                  onPressed: () => _editTournament(tournament),
                                  icon: const Icon(Icons.edit_outlined, color: _headingColor),
                                ),
                                IconButton(
                                  tooltip: 'Delete tournament',
                                  onPressed: () => _deleteTournament(tournament),
                                  icon:
                                      const Icon(Icons.delete_outline, color: Color(0xFFE57373)),
                                ),
                              ],
                            ),
                          ),
                        ),
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

class _TournamentConfig {
  const _TournamentConfig({
    required this.id,
    required this.name,
    required this.startDate,
    required this.registeredPlayers,
    required this.roundCount,
    required this.clubOrCourse,
    required this.city,
    required this.state,
    required this.country,
    required this.roundFormats,
    required this.eventType,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final List<String> registeredPlayers;
  final int roundCount;
  final String clubOrCourse;
  final String city;
  final String state;
  final String country;
  final List<String> roundFormats;
  final String eventType;
}

String _displayDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
