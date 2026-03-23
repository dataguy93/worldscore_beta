import 'package:flutter/material.dart';

import '../models/tournament.dart';
import '../services/tournament_service.dart';

class TournamentResultsPage extends StatefulWidget {
  const TournamentResultsPage({
    required this.directorUserId,
    super.key,
  });

  final String directorUserId;

  @override
  State<TournamentResultsPage> createState() => _TournamentResultsPageState();
}

class _TournamentResultsPageState extends State<TournamentResultsPage> {
  static const _cardsSubmitted = 34;
  static const _totalCards = 48;
  final TournamentService _tournamentService = TournamentService();
  _TournamentSelection? _selection;

  int _readTotalRounds(Tournament tournament) {
    return tournament.totalRounds < 1 ? 1 : tournament.totalRounds;
  }

  _TournamentSelection? _effectiveSelection(List<Tournament> tournaments) {
    if (tournaments.isEmpty) {
      return null;
    }

    final currentSelection = _selection;
    var selectedTournament = currentSelection?.tournament ?? tournaments.first;
    final stillExists =
        tournaments.any((item) => item.tournamentId == selectedTournament.tournamentId);
    if (!stillExists) {
      selectedTournament = tournaments.first;
    }
    final totalRounds = _readTotalRounds(selectedTournament);
    final selectedRound = (currentSelection?.round ?? 1).clamp(1, totalRounds);

    return _TournamentSelection(
      tournament: selectedTournament,
      round: selectedRound,
      totalRounds: totalRounds,
    );
  }

  Future<void> _showTournamentPicker(
    List<Tournament> tournaments,
    _TournamentSelection currentSelection,
  ) async {
    if (tournaments.isEmpty) {
      return;
    }

    var selectedTournament = currentSelection.tournament;
    var selectedRound = currentSelection.round;
    var totalRounds = _readTotalRounds(selectedTournament);
    selectedRound = selectedRound.clamp(1, totalRounds);

    final picked = await showModalBottomSheet<_TournamentSelection>(
      context: context,
      backgroundColor: const Color(0xFF06261B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final rounds = List<int>.generate(totalRounds, (index) => index + 1);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leaderboard tournament',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedTournament.tournamentId,
                    dropdownColor: const Color(0xFF0B3A2B),
                    decoration: _pickerDecoration('Tournament'),
                    items: tournaments
                        .map(
                          (tournament) => DropdownMenuItem<String>(
                            value: tournament.tournamentId,
                            child: Text(tournament.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      final updated = tournaments.firstWhere((item) => item.tournamentId == value);
                      setModalState(() {
                        selectedTournament = updated;
                        totalRounds = _readTotalRounds(updated);
                        selectedRound = selectedRound.clamp(1, totalRounds);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedRound,
                    dropdownColor: const Color(0xFF0B3A2B),
                    decoration: _pickerDecoration('Round'),
                    items: rounds
                        .map(
                          (round) => DropdownMenuItem<int>(
                            value: round,
                            child: Text('Round $round of $totalRounds'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setModalState(() => selectedRound = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          _TournamentSelection(
                            tournament: selectedTournament,
                            round: selectedRound,
                            totalRounds: totalRounds,
                          ),
                        );
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }
    setState(() => _selection = picked);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _cardsSubmitted / _totalCards;

    return Scaffold(
      backgroundColor: const Color(0xFF031C14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<List<Tournament>>(
                stream: widget.directorUserId.trim().isEmpty
                    ? const Stream<List<Tournament>>.empty()
                    : _tournamentService.streamDirectorTournaments(widget.directorUserId.trim()),
                builder: (context, snapshot) {
                  final tournaments = snapshot.data ?? const <Tournament>[];
                  final effectiveSelection = _effectiveSelection(tournaments);

                  return _HeaderSection(
                    selection: effectiveSelection,
                    canSelect: tournaments.isNotEmpty,
                    onSelect: tournaments.isEmpty || effectiveSelection == null
                        ? null
                        : () => _showTournamentPicker(tournaments, effectiveSelection),
                  );
                },
              ),
              const SizedBox(height: 14),
              const _LiveBadge(),
              const SizedBox(height: 12),
              _SubmissionProgress(progress: progress),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF114834), height: 1),
              const SizedBox(height: 14),
              const _TopChips(),
              const SizedBox(height: 12),
              const _RoleToggle(),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF114834), height: 1),
              const SizedBox(height: 16),
              const _MetricsGrid(),
              const SizedBox(height: 16),
              const _TrendsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _pickerDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF9CC4B9)),
    filled: true,
    fillColor: const Color(0xFF0E3227),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF1D6848)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF43D787)),
    ),
  );
}

class _TournamentSelection {
  const _TournamentSelection({
    required this.tournament,
    required this.round,
    required this.totalRounds,
  });

  final Tournament tournament;
  final int round;
  final int totalRounds;
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.selection,
    required this.canSelect,
    required this.onSelect,
  });

  final _TournamentSelection? selection;
  final bool canSelect;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final display = selection == null
        ? 'Select a tournament and round'
        : '${selection!.tournament.name} • '
            'Round ${selection!.round} of ${selection!.totalRounds} • '
            '${selection!.tournament.location}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'WorldScore',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: Color(0xFF3CE081),
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Tournament Dashboard',
                    style: TextStyle(
                      color: Color(0xFF9AC3B7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _DirectorPill(),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: canSelect ? onSelect : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.golf_course_rounded,
                  color: Color(0xFF7EA699),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    display,
                    style: const TextStyle(
                      color: Color(0xFF7EA699),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (canSelect)
                  const Icon(
                    Icons.expand_more_rounded,
                    color: Color(0xFF7EA699),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DirectorPill extends StatelessWidget {
  const _DirectorPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF083F2A),
        border: Border.all(color: const Color(0xFF1D8E5B)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rocket_launch_outlined,
            size: 14,
            color: Color(0xFF4BE58F),
          ),
          SizedBox(width: 6),
          Text(
            'Director',
            style: TextStyle(
              color: Color(0xFF4BE58F),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF083A28),
        border: Border.all(color: const Color(0xFF1E8F5C)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: Color(0xFF35DD7F)),
          SizedBox(width: 8),
          Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFF3CE081),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionProgress extends StatelessWidget {
  const _SubmissionProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '34 / 48 Cards submitted',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: const Color(0xFF1A3B2F),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF3CE081)),
          ),
        ),
      ],
    );
  }
}

class _TopChips extends StatelessWidget {
  const _TopChips();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _DashboardChip(
          label: 'Overview',
          icon: Icons.grid_view_rounded,
          selected: true,
        ),
        _DashboardChip(
          label: 'Anomalies',
          icon: Icons.warning_amber_rounded,
          badge: '3',
        ),
        _DashboardChip(
          label: 'Audit Trail',
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }
}

class _DashboardChip extends StatelessWidget {
  const _DashboardChip({
    required this.label,
    required this.icon,
    this.badge,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final String? badge;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected ? const Color(0xFF0D3B29) : const Color(0xFF0A281D),
        border: Border.all(
          color: selected ? const Color(0xFF1A8052) : const Color(0xFF214536),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? const Color(0xFF4BE58F) : const Color(0xFF6F8E84),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF4BE58F) : const Color(0xFF7B958D),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4D3D12),
                border: Border.all(color: const Color(0xFF8A6A12)),
              ),
              alignment: Alignment.center,
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Color(0xFFF1BD2F),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        const Text(
          'Demo role:',
          style: TextStyle(
            color: Color(0xFF789A8E),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF102B21),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF284E40)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoleChip(label: '🏆 Pro'),
              SizedBox(width: 6),
              _RoleChip(label: '🚀 Director', active: true),
            ],
          ),
        ),
        const Text(
          '← Pricing',
          style: TextStyle(color: Color(0xFF5E7D72), fontSize: 14),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: active ? const Color(0xFF1A6A43) : Colors.transparent,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF59E89A) : const Color(0xFF778F88),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: const [
        _MetricCard(
          borderColor: Color(0xFF12598A),
          background: Color(0xFF082538),
          icon: Icons.groups_outlined,
          iconColor: Color(0xFF62A9FF),
          value: '8',
          label: 'Players',
          sublabel: '5 finished',
        ),
        _MetricCard(
          borderColor: Color(0xFF137A48),
          background: Color(0xFF093823),
          icon: Icons.trending_down_rounded,
          iconColor: Color(0xFF3EE483),
          value: '72.4',
          label: 'Avg Score',
          sublabel: 'vs par 72',
        ),
        _MetricCard(
          borderColor: Color(0xFF7C5E1A),
          background: Color(0xFF25220D),
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFFF7C132),
          value: '3',
          label: 'Anomalies',
          sublabel: 'review',
        ),
        _MetricCard(
          borderColor: Color(0xFF4B3287),
          background: Color(0xFF1C1E35),
          icon: Icons.check_circle_outline,
          iconColor: Color(0xFFAA80FF),
          value: '2',
          label: 'Overrides',
          sublabel: 'this round',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.borderColor,
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.sublabel,
  });

  final Color borderColor;
  final Color background;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFD7E5DE),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sublabel,
                  style: const TextStyle(
                    color: Color(0xFF80998F),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendsCard extends StatelessWidget {
  const _TrendsCard();

  @override
  Widget build(BuildContext context) {
    const barValues = [2.2, 6.0, 10.5, 16.8, 21.5, 27.0, 34.0];
    const labels = ['8:00', '8:30', '9:00', '9:30', '10:00', '10:30', '11:00'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF032A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F5D39)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Tournament Trends',
            style: TextStyle(
              color: Color(0xFFE6F1EC),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Real-time scoring data',
            style: TextStyle(
              color: Color(0xFF6F9183),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const _TrendTabs(),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < barValues.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _TrendBar(
                        value: barValues[i],
                        maxValue: 36,
                        label: labels[i],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendTabs extends StatelessWidget {
  const _TrendTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A3127),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF275343)),
      ),
      padding: const EdgeInsets.all(4),
      child: const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TrendTab(label: 'Card Flow', selected: true),
            _TrendTab(label: 'Avg Score'),
            _TrendTab(label: 'Hole Analysis'),
          ],
        ),
      ),
    );
  }
}

class _TrendTab extends StatelessWidget {
  const _TrendTab({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF195D3D) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? const Color(0xFF299A65) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF58EB9D) : const Color(0xFF778E84),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.value,
    required this.maxValue,
    required this.label,
  });

  final double value;
  final double maxValue;
  final String label;

  @override
  Widget build(BuildContext context) {
    final heightFactor = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              widthFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF48C97A),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF749488),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
