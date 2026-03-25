import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tournament.dart';
import '../services/registration_service.dart';
import '../services/tournament_service.dart';

class TournamentResultsPage extends StatefulWidget {
  const TournamentResultsPage({super.key});

  @override
  State<TournamentResultsPage> createState() => _TournamentResultsPageState();
}

class _TournamentResultsPageState extends State<TournamentResultsPage> {
  final TournamentService _tournamentService = TournamentService();
  final RegistrationService _registrationService = RegistrationService();
  String? _selectedTournamentId;
  int _selectedRound = 1;

  String? get _currentDirectorUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031C14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderSection(
                tournamentService: _tournamentService,
                directorUserId: _currentDirectorUserId,
                selectedTournamentId: _selectedTournamentId,
                selectedRound: _selectedRound,
                onTournamentChanged: (tournamentId) {
                  setState(() => _selectedTournamentId = tournamentId);
                },
                onRoundChanged: (round) {
                  setState(() => _selectedRound = round);
                },
              ),
              const SizedBox(height: 14),
              const _LiveBadge(),
              const SizedBox(height: 12),
              _SubmissionProgress(
                registrationService: _registrationService,
                selectedTournamentId: _selectedTournamentId,
                selectedRound: _selectedRound,
              ),
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
              const SizedBox(height: 16),
              const _LiveLeaderboardCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatefulWidget {
  const _HeaderSection({
    required this.tournamentService,
    required this.directorUserId,
    required this.selectedTournamentId,
    required this.selectedRound,
    required this.onTournamentChanged,
    required this.onRoundChanged,
  });

  final TournamentService tournamentService;
  final String? directorUserId;
  final String? selectedTournamentId;
  final int selectedRound;
  final ValueChanged<String> onTournamentChanged;
  final ValueChanged<int> onRoundChanged;

  @override
  State<_HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<_HeaderSection> {
  @override
  Widget build(BuildContext context) {
    final directorUserId = widget.directorUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _BackToDirectorHomeButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Row(
                children: [
                  Text(
                    'WorldScore',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: Color(0xFF3CE081),
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const _DirectorPill(),
          ],
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Tournament Leaderboard',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9AC3B7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (directorUserId == null || directorUserId.isEmpty)
          const Text(
            'Sign in to select a tournament.',
            style: TextStyle(
              color: Color(0xFF7EA699),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          StreamBuilder<List<Tournament>>(
            stream: widget.tournamentService
                .streamDirectorTournaments(directorUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return const Text(
                  'Unable to load tournaments.',
                  style: TextStyle(
                    color: Color(0xFFE57373),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }

              final tournaments = snapshot.data ?? [];
              if (tournaments.isEmpty) {
                return const Text(
                  'No tournaments available.',
                  style: TextStyle(
                    color: Color(0xFF7EA699),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }

              final selectedTournament = tournaments.firstWhere(
                (tournament) =>
                    tournament.tournamentId == widget.selectedTournamentId,
                orElse: () => tournaments.first,
              );
              final selectedTournamentId = selectedTournament.tournamentId;
              if (widget.selectedTournamentId != selectedTournamentId) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) {
                    return;
                  }
                  widget.onTournamentChanged(selectedTournamentId);
                });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF083A28),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF1E8F5C)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedTournamentId,
                              dropdownColor: const Color(0xFF083A28),
                              iconEnabledColor: const Color(0xFF9AC3B7),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              isExpanded: true,
                              items: tournaments
                                  .map(
                                    (tournament) => DropdownMenuItem<String>(
                                      value: tournament.tournamentId,
                                      child: Text(
                                        tournament.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                widget.onTournamentChanged(value);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF083A28),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF1E8F5C)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: 'Round ${widget.selectedRound}',
                              dropdownColor: const Color(0xFF083A28),
                              iconEnabledColor: const Color(0xFF9AC3B7),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              isExpanded: true,
                              items: List.generate(
                                4,
                                (index) => DropdownMenuItem<String>(
                                  value: 'Round ${index + 1}',
                                  child: Text('Round ${index + 1}'),
                                ),
                              ),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                final round = int.tryParse(
                                  value.replaceFirst('Round ', ''),
                                );
                                if (round == null) {
                                  return;
                                }
                                widget.onRoundChanged(round);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${selectedTournament.name} • Round ${widget.selectedRound} of 4 • ${selectedTournament.location}',
                    style: const TextStyle(
                      color: Color(0xFF7EA699),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
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

class _BackToDirectorHomeButton extends StatelessWidget {
  const _BackToDirectorHomeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Back to Director Home',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF083A28),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E8F5C)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF9AC3B7),
            size: 16,
          ),
        ),
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
  const _SubmissionProgress({
    required this.registrationService,
    required this.selectedTournamentId,
    required this.selectedRound,
  });

  final RegistrationService registrationService;
  final String? selectedTournamentId;
  final int selectedRound;

  @override
  Widget build(BuildContext context) {
    final tournamentId = selectedTournamentId;
    if (tournamentId == null || tournamentId.isEmpty) {
      return const Text(
        '-- / -- Cards submitted',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return StreamBuilder<int>(
      stream: registrationService.streamRegisteredCount(tournamentId),
      builder: (context, totalSnapshot) {
        final totalRegistered = totalSnapshot.data ?? 0;
        return StreamBuilder<int>(
          stream: registrationService.streamRoundSubmissionCount(
            tournamentId: tournamentId,
            round: selectedRound,
          ),
          builder: (context, submittedSnapshot) {
            final cardsSubmitted = submittedSnapshot.data ?? 0;
            final progress = totalRegistered == 0
                ? 0.0
                : (cardsSubmitted / totalRegistered).clamp(0.0, 1.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$cardsSubmitted / $totalRegistered Cards submitted',
                  style: const TextStyle(
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
          },
        );
      },
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

class _TrendsCard extends StatefulWidget {
  const _TrendsCard();

  @override
  State<_TrendsCard> createState() => _TrendsCardState();
}

class _TrendsCardState extends State<_TrendsCard> {
  int? _selectedBarIndex;
  _TrendView _selectedTrend = _TrendView.cardFlow;

  @override
  Widget build(BuildContext context) {
    const barValues = [2.2, 6.0, 10.5, 16.8, 21.5, 27.0, 34.0];
    const labels = ['8:00', '8:30', '9:00', '9:30', '10:00', '10:30', '11:00'];
    const yAxisValues = [36, 27, 18, 9, 0];
    const avgScores = [73.1, 72.0, 71.0, 70.5, 70.0, 71.0, 70.8];

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
          _TrendTabs(
            selectedTrend: _selectedTrend,
            onSelected: (trend) {
              setState(() {
                _selectedTrend = trend;
              });
            },
          ),
          const SizedBox(height: 14),
          if (_selectedTrend == _TrendView.cardFlow)
            SizedBox(
              height: 210,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final axisValue in yAxisValues)
                          Text(
                            '$axisValue',
                            style: const TextStyle(
                              color: Color(0xFF749488),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (var i = 0; i < barValues.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            setState(() {
                              _selectedBarIndex = i;
                            });
                          },
                          child: _TrendBar(
                            value: barValues[i],
                            maxValue: 36,
                            label: labels[i],
                            showTooltip: _selectedBarIndex == i,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (_selectedTrend == _TrendView.avgScore)
            const SizedBox(
              height: 210,
              child: _AvgScoreChart(
                labels: labels,
                values: avgScores,
              ),
            ),
          if (_selectedTrend == _TrendView.holeAnalysis)
            const SizedBox(
              height: 210,
              child: Center(
                child: Text(
                  'Hole analysis chart coming soon',
                  style: TextStyle(
                    color: Color(0xFF7C9D90),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveLeaderboardCard extends StatelessWidget {
  const _LiveLeaderboardCard();

  @override
  Widget build(BuildContext context) {
    const players = [
      _LeaderboardPlayer(
        rank: 1,
        initials: 'JS',
        name: 'Jordan Spieth',
        gross: 68,
        net: 65,
        scoreLabel: '-4',
        scoreColor: Color(0xFF47E590),
        thru: 'F',
        trend: _LeaderboardTrend.up,
      ),
      _LeaderboardPlayer(
        rank: 2,
        initials: 'RM',
        name: 'Rory McIlroy',
        gross: 70,
        net: 67,
        scoreLabel: '-2',
        scoreColor: Color(0xFF47E590),
        thru: 'F',
        trend: _LeaderboardTrend.neutral,
      ),
      _LeaderboardPlayer(
        rank: 3,
        initials: 'TW',
        name: 'Tiger Woods',
        gross: 71,
        net: 69,
        scoreLabel: '-1',
        scoreColor: Color(0xFF47E590),
        thru: '•14',
        trend: _LeaderboardTrend.up,
      ),
      _LeaderboardPlayer(
        rank: 4,
        initials: 'DJ',
        name: 'Dustin Johnson',
        gross: 72,
        net: 70,
        scoreLabel: 'E',
        scoreColor: Color(0xFF97ACA2),
        thru: 'F',
        trend: _LeaderboardTrend.down,
      ),
      _LeaderboardPlayer(
        rank: 5,
        initials: 'CM',
        name: 'Collin Morikawa',
        gross: 73,
        net: 71,
        scoreLabel: '+1',
        scoreColor: Color(0xFFFB7E83),
        thru: '•10',
        trend: _LeaderboardTrend.neutral,
      ),
      _LeaderboardPlayer(
        rank: 6,
        initials: 'JT',
        name: 'Justin Thomas',
        gross: 74,
        net: 71,
        scoreLabel: '+2',
        scoreColor: Color(0xFFFB7E83),
        thru: 'F',
        trend: _LeaderboardTrend.down,
      ),
      _LeaderboardPlayer(
        rank: 7,
        initials: 'PC',
        name: 'Patrick Cantlay',
        gross: 75,
        net: 72,
        scoreLabel: '+3',
        scoreColor: Color(0xFFFB7E83),
        thru: '•7',
        trend: _LeaderboardTrend.neutral,
      ),
      _LeaderboardPlayer(
        rank: 8,
        initials: 'XS',
        name: 'Xander Schauffele',
        gross: 76,
        net: 73,
        scoreLabel: '+4',
        scoreColor: Color(0xFFFB7E83),
        thru: 'F',
        trend: _LeaderboardTrend.up,
      ),
    ];

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
          Row(
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Leaderboard',
                      style: TextStyle(
                        color: Color(0xFFE6F1EC),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Click a player to view scorecard',
                      style: TextStyle(
                        color: Color(0xFF6F9183),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Updating',
                style: TextStyle(
                  color: Color(0xFF47E590),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _LeaderboardHeaderRow(),
          const SizedBox(height: 6),
          for (var i = 0; i < players.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == players.length - 1 ? 0 : 6),
              child: _LeaderboardRow(
                player: players[i],
                highlighted: i == 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaderboardHeaderRow extends StatelessWidget {
  const _LeaderboardHeaderRow();

  @override
  Widget build(BuildContext context) {
    const grossColWidth = 28.0;
    const netColWidth = 28.0;
    const scoreColWidth = 30.0;
    const thruColWidth = 34.0;
    const trendColWidth = 18.0;
    const statHeaderOffset = 6.0;

    const headerStyle = TextStyle(
      color: Color(0xFF5D7B6F),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.35,
    );

    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text('#', style: headerStyle)),
          Expanded(flex: 5, child: Text('PLAYER', style: headerStyle)),
          SizedBox(width: statHeaderOffset),
          SizedBox(width: grossColWidth, child: Text('G', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: netColWidth, child: Text('N', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: scoreColWidth, child: Text('+/-', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: thruColWidth, child: Text('THRU', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: trendColWidth),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.player,
    required this.highlighted,
  });

  final _LeaderboardPlayer player;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    const grossColWidth = 28.0;
    const netColWidth = 28.0;
    const scoreColWidth = 30.0;
    const thruColWidth = 34.0;
    const trendColWidth = 18.0;

    final row = SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${player.rank}',
              style: TextStyle(
                color: highlighted ? const Color(0xFFF6D65A) : const Color(0xFF6F9183),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF0A6A42),
            child: Text(
              player.initials,
              style: const TextStyle(
                color: Color(0xFF79E2A7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              player.name,
              style: const TextStyle(
                color: Color(0xFFE6F1EC),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: grossColWidth,
            child: Text(
              '${player.gross}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB7CAC1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: netColWidth,
            child: Text(
              '${player.net}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB7CAC1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: scoreColWidth,
            child: Text(
              player.scoreLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: player.scoreColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: thruColWidth,
            child: Text(
              player.thru,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF47E590),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: trendColWidth,
            child: Icon(
              _iconForTrend(player.trend),
              size: 14,
              color: _colorForTrend(player.trend),
            ),
          ),
        ],
      ),
    );

    return row;
  }

  IconData _iconForTrend(_LeaderboardTrend trend) {
    switch (trend) {
      case _LeaderboardTrend.up:
        return Icons.trending_up_rounded;
      case _LeaderboardTrend.down:
        return Icons.trending_down_rounded;
      case _LeaderboardTrend.neutral:
        return Icons.remove_rounded;
    }
  }

  Color _colorForTrend(_LeaderboardTrend trend) {
    switch (trend) {
      case _LeaderboardTrend.up:
        return const Color(0xFF47E590);
      case _LeaderboardTrend.down:
        return const Color(0xFFFB7E83);
      case _LeaderboardTrend.neutral:
        return const Color(0xFF5D7B6F);
    }
  }
}

class _LeaderboardPlayer {
  const _LeaderboardPlayer({
    required this.rank,
    required this.initials,
    required this.name,
    required this.gross,
    required this.net,
    required this.scoreLabel,
    required this.scoreColor,
    required this.thru,
    required this.trend,
  });

  final int rank;
  final String initials;
  final String name;
  final int gross;
  final int net;
  final String scoreLabel;
  final Color scoreColor;
  final String thru;
  final _LeaderboardTrend trend;
}

enum _LeaderboardTrend { up, down, neutral }

enum _TrendView { cardFlow, avgScore, holeAnalysis }

class _TrendTabs extends StatelessWidget {
  const _TrendTabs({
    required this.selectedTrend,
    required this.onSelected,
  });

  final _TrendView selectedTrend;
  final ValueChanged<_TrendView> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A3127),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF275343)),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TrendTab(
              label: 'Card Flow',
              selected: selectedTrend == _TrendView.cardFlow,
              onTap: () => onSelected(_TrendView.cardFlow),
            ),
            _TrendTab(
              label: 'Avg Score',
              selected: selectedTrend == _TrendView.avgScore,
              onTap: () => onSelected(_TrendView.avgScore),
            ),
            _TrendTab(
              label: 'Hole Analysis',
              selected: selectedTrend == _TrendView.holeAnalysis,
              onTap: () => onSelected(_TrendView.holeAnalysis),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendTab extends StatelessWidget {
  const _TrendTab({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

class _AvgScoreChart extends StatelessWidget {
  const _AvgScoreChart({
    required this.labels,
    required this.values,
  });

  final List<String> labels;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    const yLabels = [75, 72, 70, 68];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 30,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final axisValue in yLabels)
                Text(
                  '$axisValue',
                  style: const TextStyle(
                    color: Color(0xFF749488),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _AvgScoreChartPainter(values: values),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Text(
                        labels[i],
                        textAlign: i == 0
                            ? TextAlign.left
                            : i == labels.length - 1
                                ? TextAlign.right
                                : TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF749488),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvgScoreChartPainter extends CustomPainter {
  _AvgScoreChartPainter({required this.values});

  final List<double> values;

  static const _minY = 68.0;
  static const _maxY = 75.0;
  static const _parScore = 72.0;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF234B3C)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF45E68E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final horizontalSteps = [75.0, 72.0, 70.0, 68.0];
    for (final y in horizontalSteps) {
      final yPos = _toYPosition(y, size.height);
      _drawDashedLine(
        canvas: canvas,
        start: Offset(0, yPos),
        end: Offset(size.width, yPos),
        paint: gridPaint,
      );
    }

    if (values.length < 2) {
      return;
    }

    final xStep = size.width / (values.length - 1);
    for (var i = 0; i < values.length; i++) {
      final x = xStep * i;
      _drawDashedLine(
        canvas: canvas,
        start: Offset(x, 0),
        end: Offset(x, size.height),
        paint: gridPaint,
      );
    }

    final trendPath = Path()
      ..moveTo(0, _toYPosition(values.first, size.height));
    for (var i = 1; i < values.length; i++) {
      trendPath.lineTo(xStep * i, _toYPosition(values[i], size.height));
    }
    canvas.drawPath(trendPath, linePaint);

    final parText = TextPainter(
      text: const TextSpan(
        text: 'Par',
        style: TextStyle(
          color: Color(0xFF6F9183),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final parY = _toYPosition(_parScore, size.height) - (parText.height / 2);
    parText.paint(canvas, Offset((size.width / 2) - (parText.width / 2), parY));
  }

  double _toYPosition(double yValue, double height) {
    final normalized = ((yValue - _minY) / (_maxY - _minY)).clamp(0.0, 1.0);
    return height - (normalized * height);
  }

  void _drawDashedLine({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required Paint paint,
    double dashLength = 6,
    double gapLength = 5,
  }) {
    final delta = end - start;
    final totalDistance = delta.distance;
    final direction = delta / totalDistance;
    double drawn = 0;

    while (drawn < totalDistance) {
      final dashStart = start + direction * drawn;
      final dashEnd = start +
          direction * (drawn + dashLength).clamp(0.0, totalDistance);
      canvas.drawLine(dashStart, dashEnd, paint);
      drawn += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _AvgScoreChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.value,
    required this.maxValue,
    required this.label,
    required this.showTooltip,
  });

  final double value;
  final double maxValue;
  final String label;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    final heightFactor = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                FractionallySizedBox(
                  heightFactor: heightFactor,
                  widthFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF48C97A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                if (showTooltip)
                  Positioned(
                    bottom: (heightFactor * 180).clamp(48.0, 168.0).toDouble(),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF062B1D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0E6140)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Color(0xFF9CB1A8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Cards Submitted: ${value.round()}',
                            style: const TextStyle(
                              color: Color(0xFF58EB9D),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
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
