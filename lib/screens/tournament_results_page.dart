import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tournament.dart';
import '../models/tournament_registration.dart';
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
  Stream<QuerySnapshot<Map<String, dynamic>>>? _roundScoreStream;

  String? get _currentDirectorUserId => FirebaseAuth.instance.currentUser?.uid;

  void _updateRoundScoreStream() {
    final id = _selectedTournamentId;
    if (id == null || id.isEmpty) {
      setState(() => _roundScoreStream = null);
      return;
    }
    setState(() {
      _roundScoreStream = _registrationService
          .streamRoundScoreDocs(tournamentId: id, round: _selectedRound)
          .asBroadcastStream();
    });
  }

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
                  _selectedTournamentId = tournamentId;
                  _updateRoundScoreStream();
                },
                onRoundChanged: (round) {
                  _selectedRound = round;
                  _updateRoundScoreStream();
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
              _TopChips(
                registrationService: _registrationService,
                selectedTournamentId: _selectedTournamentId,
                selectedRound: _selectedRound,
              ),
              const SizedBox(height: 12),
              const _RoleToggle(),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF114834), height: 1),
              const SizedBox(height: 16),
              _MetricsGrid(
                registrationService: _registrationService,
                selectedTournamentId: _selectedTournamentId,
                selectedRound: _selectedRound,
              ),
              const SizedBox(height: 16),
              _TrendsCard(
                selectedTournamentId: _selectedTournamentId,
                selectedRound: _selectedRound,
                roundScoreStream: _roundScoreStream,
              ),
              const SizedBox(height: 16),
              _LiveLeaderboardCard(
                selectedTournamentId: _selectedTournamentId,
                selectedRound: _selectedRound,
                registrationService: _registrationService,
                roundScoreStream: _roundScoreStream,
              ),
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
  const _TopChips({
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

    return StreamBuilder<int>(
      stream: tournamentId == null || tournamentId.isEmpty
          ? null
          : registrationService.streamRoundAnomalyCount(
              tournamentId: tournamentId,
              round: selectedRound,
            ),
      builder: (context, snapshot) {
        final count = snapshot.data;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            const _DashboardChip(
              label: 'Overview',
              icon: Icons.grid_view_rounded,
              selected: true,
            ),
            _DashboardChip(
              label: 'Anomalies',
              icon: Icons.warning_amber_rounded,
              badge: count == null ? null : '$count',
              badgeDimmed: count != null && count == 0,
            ),
            const _DashboardChip(
              label: 'Audit Trail',
              icon: Icons.shield_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _DashboardChip extends StatelessWidget {
  const _DashboardChip({
    required this.label,
    required this.icon,
    this.badge,
    this.badgeDimmed = false,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final String? badge;
  final bool badgeDimmed;
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
                color: badgeDimmed ? const Color(0xFF162920) : const Color(0xFF4D3D12),
                border: Border.all(
                  color: badgeDimmed ? const Color(0xFF2A4038) : const Color(0xFF8A6A12),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                badge!,
                style: TextStyle(
                  color: badgeDimmed ? const Color(0xFF4D6B60) : const Color(0xFFF1BD2F),
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
  const _MetricsGrid({
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
            value: '--',
            label: 'Players',
            sublabel: '-- finished',
          ),
          _MetricCard(
            borderColor: Color(0xFF137A48),
            background: Color(0xFF093823),
            icon: Icons.trending_down_rounded,
            iconColor: Color(0xFF3EE483),
            value: '--',
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
            return StreamBuilder<double?>(
              stream: registrationService.streamRoundAverageTotalScore(
                tournamentId: tournamentId,
                round: selectedRound,
              ),
              builder: (context, avgScoreSnapshot) {
                final averageTotalScore = avgScoreSnapshot.data;

                return StreamBuilder<int>(
                  stream: registrationService.streamRoundAnomalyCount(
                    tournamentId: tournamentId,
                    round: selectedRound,
                  ),
                  builder: (context, anomalySnapshot) {
                    final anomalyCount = anomalySnapshot.data;

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.25,
                      children: [
                        _MetricCard(
                          borderColor: const Color(0xFF12598A),
                          background: const Color(0xFF082538),
                          icon: Icons.groups_outlined,
                          iconColor: const Color(0xFF62A9FF),
                          value: '$totalRegistered',
                          label: 'Players',
                          sublabel: '$cardsSubmitted finished',
                        ),
                        _MetricCard(
                          borderColor: const Color(0xFF137A48),
                          background: const Color(0xFF093823),
                          icon: Icons.trending_down_rounded,
                          iconColor: const Color(0xFF3EE483),
                          value: averageTotalScore == null
                              ? '--'
                              : averageTotalScore.toStringAsFixed(1),
                          label: 'Avg Score',
                          sublabel: 'vs par 72',
                        ),
                        _MetricCard(
                          borderColor: const Color(0xFF7C5E1A),
                          background: const Color(0xFF25220D),
                          icon: Icons.warning_amber_rounded,
                          iconColor: const Color(0xFFF7C132),
                          value: anomalyCount == null ? '--' : '$anomalyCount',
                          label: 'Anomalies',
                          sublabel: 'review',
                        ),
                        const _MetricCard(
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
                  },
                );
              },
            );
          },
        );
      },
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
  const _TrendsCard({
    required this.selectedTournamentId,
    required this.selectedRound,
    required this.roundScoreStream,
  });

  final String? selectedTournamentId;
  final int selectedRound;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? roundScoreStream;

  @override
  State<_TrendsCard> createState() => _TrendsCardState();
}

class _TrendsCardState extends State<_TrendsCard> {
  int? _selectedBarIndex;
  _TrendView _selectedTrend = _TrendView.cardFlow;
  late PageController _holePageController;
  int _holePageIndex = 0;

  @override
  void initState() {
    super.initState();
    _holePageController = PageController(keepPage: false);
  }

  @override
  void didUpdateWidget(_TrendsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTournamentId != widget.selectedTournamentId ||
        oldWidget.selectedRound != widget.selectedRound) {
      _holePageIndex = 0;
      if (_holePageController.hasClients) {
        _holePageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _holePageController.dispose();
    super.dispose();
  }

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
            _holeAnalysisSection(),
        ],
      ),
    );
  }

  // Default pars used for birdie/par/bogey classification.
  // Par data is not stored in Firestore — update here if course pars are added.
  static const _front9Pars = [4, 5, 3, 4, 4, 5, 3, 4, 4];
  static const _back9Pars  = [4, 3, 5, 4, 4, 3, 5, 4, 4];

  Widget _holeAnalysisSection() {
    final tournamentId = widget.selectedTournamentId;

    if (tournamentId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Select a tournament to view hole analysis.',
            style: TextStyle(color: Color(0xFF6F9183), fontSize: 13),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.roundScoreStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 230,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF47E590),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No scores submitted for this round yet.',
                style: TextStyle(color: Color(0xFF6F9183), fontSize: 13),
              ),
            ),
          );
        }

        List<int?> extractHoles(Map rawScores, int startHole) {
          return List<int?>.generate(9, (i) {
            final val = rawScores['${startHole + i}'];
            if (val == null) return null;
            if (val is int) return val;
            if (val is double) return val.round();
            return int.tryParse('$val');
          });
        }

        final front9Scores = docs.map((doc) {
          final raw = doc.data()['scoresByHole'];
          return raw is Map ? extractHoles(raw, 1) : List<int?>.filled(9, null);
        }).toList();

        final back9Scores = docs.map((doc) {
          final raw = doc.data()['scoresByHole'];
          return raw is Map ? extractHoles(raw, 10) : List<int?>.filled(9, null);
        }).toList();

        final front9Data = _buildHoleAnalysisData(
          holePars: _front9Pars,
          playerScoresByHole: front9Scores,
        );
        final back9Data = _buildHoleAnalysisData(
          holePars: _back9Pars,
          playerScoresByHole: back9Scores,
        );

        final pages = [
          (label: 'Front 9', holeStart: 1, data: front9Data),
          (label: 'Back 9', holeStart: 10, data: back9Data),
        ];

        return Column(
          children: [
            SizedBox(
              height: 230,
              child: PageView.builder(
                controller: _holePageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _holePageIndex = i),
                itemBuilder: (context, i) => _HoleAnalysisChart(
                  labels: [
                    for (var h = pages[i].holeStart; h < pages[i].holeStart + 9; h++)
                      '$h',
                  ],
                  columns: pages[i].data,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Page indicator + legend row
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pages.length; i++) ...[
                        GestureDetector(
                          onTap: () => _holePageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _holePageIndex == i
                                  ? const Color(0xFF195D3D)
                                  : const Color(0xFF1A3127),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _holePageIndex == i
                                    ? const Color(0xFF299A65)
                                    : const Color(0xFF275343),
                              ),
                            ),
                            child: Text(
                              pages[i].label,
                              style: TextStyle(
                                color: _holePageIndex == i
                                    ? const Color(0xFF58EB9D)
                                    : const Color(0xFF6F9183),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _HoleLegendChip(label: 'Birdie', color: Color(0xFF47E590)),
                      _HoleLegendChip(label: 'Par', color: Color(0xFF44A8FF)),
                      _HoleLegendChip(label: 'Bogey', color: Color(0xFFFFA64D)),
                      _HoleLegendChip(label: 'Double+', color: Color(0xFFFF6161)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<_HoleAnalysisColumn> _buildHoleAnalysisData({
    required List<int> holePars,
    required List<List<int?>> playerScoresByHole,
  }) {
    final columns = <_HoleAnalysisColumn>[];
    for (var holeIndex = 0; holeIndex < holePars.length; holeIndex++) {
      var birdie = 0;
      var par = 0;
      var bogey = 0;
      var doublePlus = 0;

      for (final playerScores in playerScoresByHole) {
        if (holeIndex >= playerScores.length) {
          continue;
        }
        final score = playerScores[holeIndex];
        if (score == null) {
          continue;
        }
        final toPar = score - holePars[holeIndex];
        if (toPar <= -1) {
          birdie += 1;
        } else if (toPar == 0) {
          par += 1;
        } else if (toPar == 1) {
          bogey += 1;
        } else {
          doublePlus += 1;
        }
      }
      columns.add(
        _HoleAnalysisColumn(
          birdie: birdie,
          par: par,
          bogey: bogey,
          doublePlus: doublePlus,
        ),
      );
    }
    return columns;
  }
}

class _LiveLeaderboardCard extends StatelessWidget {
  const _LiveLeaderboardCard({
    required this.selectedTournamentId,
    required this.selectedRound,
    required this.registrationService,
    required this.roundScoreStream,
  });

  final String? selectedTournamentId;
  final int selectedRound;
  final RegistrationService registrationService;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? roundScoreStream;

  @override
  Widget build(BuildContext context) {
    final tournamentId = selectedTournamentId;

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
          if (tournamentId == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Text(
                'Select a tournament to view registered players.',
                style: TextStyle(
                  color: Color(0xFF7EA699),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            StreamBuilder<List<TournamentRegistration>>(
              stream: registrationService.streamRegistrants(tournamentId),
              builder: (context, registrationSnapshot) {
                if (registrationSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (registrationSnapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    child: Text(
                      'Unable to load registered players.',
                      style: TextStyle(
                        color: Color(0xFFE57373),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                final registeredPlayers = (registrationSnapshot.data ?? [])
                    .where((entry) => entry.status == RegistrationStatus.registered)
                    .toList();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: roundScoreStream,
                  builder: (context, scoreSnapshot) {
                    if (scoreSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final scoreByRegistration = <String, Map<String, dynamic>>{
                      for (final doc in scoreSnapshot.data?.docs ?? const [])
                        doc.id: doc.data(),
                    };

                    final players = _buildLeaderboardPlayers(
                      registeredPlayers: registeredPlayers,
                      scoreByRegistration: scoreByRegistration,
                    );

                    if (players.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                        child: Text(
                          'No registered players found.',
                          style: TextStyle(
                            color: Color(0xFF7EA699),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (var i = 0; i < players.length; i++)
                          Padding(
                            padding: EdgeInsets.only(bottom: i == players.length - 1 ? 0 : 6),
                            child: _LeaderboardRow(
                              player: players[i],
                              highlighted: i == 0,
                              onTap: players[i].scoresByHole.isEmpty
                                  ? null
                                  : () => showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => _PlayerScorecardSheet(
                                          player: players[i],
                                          round: selectedRound,
                                        ),
                                      ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

List<_LeaderboardPlayer> _buildLeaderboardPlayers({
  required List<TournamentRegistration> registeredPlayers,
  required Map<String, Map<String, dynamic>> scoreByRegistration,
}) {
  final unsortedPlayers = registeredPlayers.map((registration) {
    final scoreDoc = scoreByRegistration[registration.registrationId];
    final gross = (scoreDoc?['totalScore'] as num?)?.toInt();
    final handicap = registration.handicap ?? 0;
    final net = gross == null ? null : (gross - handicap).round();
    final relativeToPar = net == null ? null : net - _courseParForScorecard(scoreDoc);

    final rawScores = scoreDoc?['scoresByHole'];
    final rawPars = scoreDoc?['parsByHole'];
    final scoresByHole = <int, int?>{
      if (rawScores is Map)
        for (final e in rawScores.entries)
          if (int.tryParse(e.key.toString()) case final k?) k: (e.value as num?)?.toInt(),
    };
    final parsByHole = <int, int?>{
      if (rawPars is Map)
        for (final e in rawPars.entries)
          if (int.tryParse(e.key.toString()) case final k?) k: (e.value as num?)?.toInt(),
    };

    return _LeaderboardPlayer(
      rank: 0,
      initials: _initialsForName(registration.playerName),
      name: registration.playerName,
      gross: gross,
      net: net,
      scoreLabel: _formatToParLabel(relativeToPar),
      scoreColor: _colorForToPar(relativeToPar),
      trend: _LeaderboardTrend.neutral,
      relativeToPar: relativeToPar,
      registrationId: registration.registrationId,
      handicap: handicap.toDouble(),
      scoresByHole: scoresByHole,
      parsByHole: parsByHole,
    );
  }).toList()
    ..sort((a, b) {
      if (a.net == null && b.net == null) {
        return a.name.compareTo(b.name);
      }
      if (a.net == null) {
        return 1;
      }
      if (b.net == null) {
        return -1;
      }
      final byNet = a.net!.compareTo(b.net!);
      if (byNet != 0) {
        return byNet;
      }
      return a.name.compareTo(b.name);
    });

  return List.generate(
    unsortedPlayers.length,
    (index) => _LeaderboardPlayer(
      rank: index + 1,
      initials: unsortedPlayers[index].initials,
      name: unsortedPlayers[index].name,
      gross: unsortedPlayers[index].gross,
      net: unsortedPlayers[index].net,
      scoreLabel: unsortedPlayers[index].scoreLabel,
      scoreColor: unsortedPlayers[index].scoreColor,
      trend: unsortedPlayers[index].trend,
      relativeToPar: unsortedPlayers[index].relativeToPar,
      registrationId: unsortedPlayers[index].registrationId,
      handicap: unsortedPlayers[index].handicap,
      scoresByHole: unsortedPlayers[index].scoresByHole,
      parsByHole: unsortedPlayers[index].parsByHole,
    ),
  );
}

int _courseParForScorecard(Map<String, dynamic>? scoreDoc) {
  final explicitCoursePar = (scoreDoc?['coursePar'] as num?)?.toInt();
  if (explicitCoursePar != null && explicitCoursePar > 0) {
    return explicitCoursePar;
  }

  final scoresByHole = scoreDoc?['scoresByHole'];
  if (scoresByHole is Map && scoresByHole.isNotEmpty) {
    return scoresByHole.length * 4;
  }

  return 72;
}

String _initialsForName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '--';
  }
  if (parts.length == 1) {
    final value = parts.first;
    return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _formatToParLabel(int? value) {
  if (value == null) {
    return '-';
  }
  if (value == 0) {
    return 'E';
  }
  if (value > 0) {
    return '+$value';
  }
  return '$value';
}

Color _colorForToPar(int? value) {
  if (value == null) {
    return const Color(0xFF97ACA2);
  }
  if (value < 0) {
    return const Color(0xFF47E590);
  }
  if (value > 0) {
    return const Color(0xFFFB7E83);
  }
  return const Color(0xFF97ACA2);
}

class _LeaderboardHeaderRow extends StatelessWidget {
  const _LeaderboardHeaderRow();

  @override
  Widget build(BuildContext context) {
    const grossColWidth = 28.0;
    const netColWidth = 28.0;
    const scoreColWidth = 30.0;
    const trendColWidth = 18.0;
    const statHeaderOffset = 14.0;

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
    this.onTap,
  });

  final _LeaderboardPlayer player;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const grossColWidth = 28.0;
    const netColWidth = 28.0;
    const scoreColWidth = 30.0;
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
              '${player.gross ?? '-'}',
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
              '${player.net ?? '-'}',
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
            width: trendColWidth,
            child: player.trend == _LeaderboardTrend.neutral
                ? const SizedBox.shrink()
                : Icon(
                    _iconForTrend(player.trend),
                    size: 14,
                    color: _colorForTrend(player.trend),
                  ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
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
    required this.trend,
    required this.relativeToPar,
    required this.registrationId,
    required this.handicap,
    required this.scoresByHole,
    required this.parsByHole,
  });

  final int rank;
  final String initials;
  final String name;
  final int? gross;
  final int? net;
  final String scoreLabel;
  final Color scoreColor;
  final _LeaderboardTrend trend;
  final int? relativeToPar;
  final String registrationId;
  final double handicap;
  final Map<int, int?> scoresByHole;
  final Map<int, int?> parsByHole;
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
      child: Row(
        children: [
          Expanded(
            child: _TrendTab(
              label: 'Card Flow',
              selected: selectedTrend == _TrendView.cardFlow,
              onTap: () => onSelected(_TrendView.cardFlow),
            ),
          ),
          Expanded(
            child: _TrendTab(
              label: 'Avg Score',
              selected: selectedTrend == _TrendView.avgScore,
              onTap: () => onSelected(_TrendView.avgScore),
            ),
          ),
          Expanded(
            child: _TrendTab(
              label: 'Hole Analysis',
              selected: selectedTrend == _TrendView.holeAnalysis,
              onTap: () => onSelected(_TrendView.holeAnalysis),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF195D3D) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF299A65) : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
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

class _HoleLegendChip extends StatelessWidget {
  const _HoleLegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF93AFA3),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HoleAnalysisColumn {
  const _HoleAnalysisColumn({
    required this.birdie,
    required this.par,
    required this.bogey,
    required this.doublePlus,
  });

  final int birdie;
  final int par;
  final int bogey;
  final int doublePlus;

  int get submitted => birdie + par + bogey + doublePlus;
}

class _HoleAnalysisChart extends StatelessWidget {
  const _HoleAnalysisChart({
    required this.labels,
    required this.columns,
  });

  final List<String> labels;
  final List<_HoleAnalysisColumn> columns;

  @override
  Widget build(BuildContext context) {
    final maxSubmitted = columns.fold<int>(
      0,
      (max, column) => column.submitted > max ? column.submitted : max,
    );
    final safeMax = maxSubmitted == 0 ? 1 : maxSubmitted;
    final yLabels = [
      safeMax,
      ((safeMax * 0.66).round()).clamp(1, safeMax),
      ((safeMax * 0.33).round()).clamp(1, safeMax),
      0,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 26,
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
                      painter: _HoleAnalysisChartPainter(
                        columns: columns,
                        maxSubmitted: safeMax,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final label in labels)
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
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

class _HoleAnalysisChartPainter extends CustomPainter {
  _HoleAnalysisChartPainter({
    required this.columns,
    required this.maxSubmitted,
  });

  final List<_HoleAnalysisColumn> columns;
  final int maxSubmitted;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF234B3C)
      ..strokeWidth = 1;
    const rows = 4;
    for (var i = 0; i < rows; i++) {
      final y = size.height * (i / (rows - 1));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (columns.isEmpty) {
      return;
    }

    final barWidth = size.width / (columns.length * 1.8);
    final gap =
        (size.width - (barWidth * columns.length)) / (columns.length + 1);
    final birdiePaint = Paint()..color = const Color(0xFF47E590);
    final parPaint = Paint()..color = const Color(0xFF44A8FF);
    final bogeyPaint = Paint()..color = const Color(0xFFFFA64D);
    final doublePaint = Paint()..color = const Color(0xFFFF6161);

    for (var i = 0; i < columns.length; i++) {
      final column = columns[i];
      final left = gap + i * (barWidth + gap);
      final right = left + barWidth;
      var currentBottom = size.height;

      final segments = <_HoleSegment>[
        _HoleSegment(value: column.doublePlus, paint: doublePaint),
        _HoleSegment(value: column.bogey, paint: bogeyPaint),
        _HoleSegment(value: column.par, paint: parPaint),
        _HoleSegment(value: column.birdie, paint: birdiePaint),
      ];
      for (final segment in segments) {
        final value = segment.value;
        if (value <= 0) {
          continue;
        }
        final height = (value / maxSubmitted) * size.height;
        final top = (currentBottom - height).clamp(0.0, size.height);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(left, top, right, currentBottom),
            const Radius.circular(4),
          ),
          segment.paint,
        );
        currentBottom = top;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HoleAnalysisChartPainter oldDelegate) {
    return oldDelegate.columns != columns ||
        oldDelegate.maxSubmitted != maxSubmitted;
  }
}

class _HoleSegment {
  const _HoleSegment({
    required this.value,
    required this.paint,
  });

  final int value;
  final Paint paint;
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

// ---------------------------------------------------------------------------
// Player scorecard sheet
// ---------------------------------------------------------------------------

class _PlayerScorecardSheet extends StatelessWidget {
  const _PlayerScorecardSheet({
    required this.player,
    required this.round,
  });

  final _LeaderboardPlayer player;
  final int round;

  @override
  Widget build(BuildContext context) {
    final holeNumbers = (player.scoresByHole.keys.toList()..sort());
    final front9 = holeNumbers.where((h) => h <= 9).toList();
    final back9 = holeNumbers.where((h) => h > 9).toList();

    int? _sum(List<int> holes) {
      var total = 0;
      var hasAny = false;
      for (final h in holes) {
        final s = player.scoresByHole[h];
        if (s != null) {
          total += s;
          hasAny = true;
        }
      }
      return hasAny ? total : null;
    }

    final front9Total = _sum(front9);
    final back9Total = _sum(back9);
    final shortId = player.registrationId.length >= 4
        ? player.registrationId.substring(0, 4).toUpperCase()
        : player.registrationId.toUpperCase();
    final hcpDisplay = player.handicap == player.handicap.roundToDouble()
        ? player.handicap.toInt().toString()
        : player.handicap.toStringAsFixed(1);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF071A10),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // drag handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D4E3A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: const TextStyle(
                              color: Color(0xFFE6F1EC),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'SC-$shortId — Round $round — HCP $hcpDisplay',
                            style: const TextStyle(
                              color: Color(0xFF6F9183),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D3B29),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1A8052)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 14, color: Color(0xFF4BE58F)),
                          SizedBox(width: 5),
                          Text(
                            'Override',
                            style: TextStyle(
                              color: Color(0xFF4BE58F),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Color(0xFF6F9183), size: 22),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  children: [
                    const Text(
                      'HOLE-BY-HOLE',
                      style: TextStyle(
                        color: Color(0xFF4D7A65),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.55,
                      ),
                      itemCount: holeNumbers.length,
                      itemBuilder: (context, index) {
                        final hole = holeNumbers[index];
                        final score = player.scoresByHole[hole];
                        final par = player.parsByHole[hole];
                        return _HoleScoreCard(hole: hole, score: score, par: par);
                      },
                    ),
                    const SizedBox(height: 20),
                    // totals row
                    Row(
                      children: [
                        Expanded(
                          child: _ScorecardTotal(
                            value: front9Total,
                            label: 'Front 9',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ScorecardTotal(
                            value: back9Total,
                            label: 'Back 9',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ScorecardTotal(
                            value: player.gross,
                            label: 'Gross',
                            highlight: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoleScoreCard extends StatelessWidget {
  const _HoleScoreCard({
    required this.hole,
    required this.score,
    required this.par,
  });

  final int hole;
  final int? score;
  final int? par;

  @override
  Widget build(BuildContext context) {
    final toPar = (score != null && par != null) ? score! - par! : null;
    final bg = _background(toPar);
    final border = _border(toPar);
    final scoreColor = _scoreColor(toPar);
    final label = _label(toPar);
    final labelColor = _labelColor(toPar);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'H$hole${par != null ? ' • Par $par' : ''}',
            style: const TextStyle(
              color: Color(0xFF5D8070),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                score != null ? '$score' : '-',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _background(int? toPar) {
    if (toPar == null) return const Color(0xFF0D2018);
    if (toPar >= 4) return const Color(0xFF3A0D0D);
    if (toPar >= 2) return const Color(0xFF1A1030);
    if (toPar == 1) return const Color(0xFF0D1F3A);
    if (toPar == 0) return const Color(0xFF0D2018);
    if (toPar == -1) return const Color(0xFF0A2A15);
    return const Color(0xFF0A3520);
  }

  Color _border(int? toPar) {
    if (toPar == null) return const Color(0xFF1A3D28);
    if (toPar >= 4) return const Color(0xFF7B1A1A);
    if (toPar >= 2) return const Color(0xFF3D2070);
    if (toPar == 1) return const Color(0xFF1E4070);
    if (toPar == 0) return const Color(0xFF1A3D28);
    if (toPar == -1) return const Color(0xFF0D4020);
    return const Color(0xFF0D5030);
  }

  Color _scoreColor(int? toPar) {
    if (toPar == null) return const Color(0xFFD0E8D8);
    if (toPar >= 4) return const Color(0xFFFF6B6B);
    if (toPar >= 2) return const Color(0xFFD0A8FF);
    if (toPar == 1) return const Color(0xFF7EADFF);
    if (toPar == 0) return const Color(0xFFD0E8D8);
    if (toPar == -1) return const Color(0xFF47E590);
    return const Color(0xFF3EFF90);
  }

  Color _labelColor(int? toPar) {
    if (toPar == null) return const Color(0xFF4D7A65);
    if (toPar >= 4) return const Color(0xFFF87171);
    if (toPar >= 2) return const Color(0xFFBB8AFF);
    if (toPar == 1) return const Color(0xFF6B9FE8);
    if (toPar == 0) return const Color(0xFF4D7A65);
    if (toPar == -1) return const Color(0xFF3EE483);
    return const Color(0xFF3AE880);
  }

  String _label(int? toPar) {
    if (toPar == null) return '-';
    if (toPar <= -3) return 'Albatross';
    if (toPar == -2) return 'Eagle';
    if (toPar == -1) return 'Birdie';
    if (toPar == 0) return 'Par';
    if (toPar == 1) return 'Bogey';
    if (toPar == 2) return 'Double';
    if (toPar == 3) return 'Triple';
    return '+$toPar';
  }
}

class _ScorecardTotal extends StatelessWidget {
  const _ScorecardTotal({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final int? value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF0D3B29) : const Color(0xFF0D2018),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? const Color(0xFF1A8052) : const Color(0xFF1A3D28),
        ),
      ),
      child: Column(
        children: [
          Text(
            value != null ? '$value' : '--',
            style: TextStyle(
              color: highlight ? const Color(0xFF47E590) : const Color(0xFFE6F1EC),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6F9183),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
