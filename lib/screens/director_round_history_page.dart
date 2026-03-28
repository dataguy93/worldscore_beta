import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/tournament.dart';
import '../services/registration_service.dart';
import '../services/tournament_service.dart';
import '../controllers/session_controller.dart';
import '../widgets/worldscore_header.dart';

class DirectorRoundHistoryPage extends StatefulWidget {
  const DirectorRoundHistoryPage({this.sessionController, super.key});

  final SessionController? sessionController;

  @override
  State<DirectorRoundHistoryPage> createState() => _DirectorRoundHistoryPageState();
}

class _DirectorRoundHistoryPageState extends State<DirectorRoundHistoryPage> {
  final _tournamentService = TournamentService();
  final _registrationService = RegistrationService();

  Tournament? _selectedTournament;
  int _selectedRound = 1;

  String? get _directorUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final uid = _directorUid;
    if (uid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF031C14),
        body: Center(
          child: Text('Not signed in.', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF031C14),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: WorldScoreHeader(
                subtitle: 'Round History',
                role: WorldScoreRole.director,
                onBack: () => Navigator.of(context).pop(),
                sessionController: widget.sessionController,
              ),
            ),
            _TournamentSelector(
              tournamentService: _tournamentService,
              directorUid: uid,
              selected: _selectedTournament,
              onChanged: (tournament) => setState(() {
                _selectedTournament = tournament;
                _selectedRound = 1;
              }),
            ),
            if (_selectedTournament != null) ...[
              _RoundSelector(
                selected: _selectedRound,
                numberOfRounds: _selectedTournament!.numberOfRounds,
                onChanged: (round) => setState(() => _selectedRound = round),
              ),
              Expanded(
                child: _ScorecardList(
                  registrationService: _registrationService,
                  tournamentId: _selectedTournament!.tournamentId,
                  round: _selectedRound,
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    'Select a tournament to view scorecards.',
                    style: TextStyle(color: Color(0xFF7EA699), fontSize: 15),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tournament selector
// ---------------------------------------------------------------------------

class _TournamentSelector extends StatelessWidget {
  const _TournamentSelector({
    required this.tournamentService,
    required this.directorUid,
    required this.selected,
    required this.onChanged,
  });

  final TournamentService tournamentService;
  final String directorUid;
  final Tournament? selected;
  final ValueChanged<Tournament?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF072E21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF165D43)),
      ),
      child: StreamBuilder<List<Tournament>>(
        stream: tournamentService.streamDirectorTournaments(directorUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF3CE081),
                  ),
                ),
              ),
            );
          }

          final tournaments = snapshot.data ?? [];
          if (tournaments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No tournaments found.',
                style: TextStyle(color: Color(0xFF7EA699), fontSize: 14),
              ),
            );
          }

          final validSelected = selected == null
              ? null
              : tournaments.where((t) => t.tournamentId == selected!.tournamentId).firstOrNull;

          return DropdownButtonHideUnderline(
            child: DropdownButton<Tournament>(
              value: validSelected,
              hint: const Text(
                'Select a tournament',
                style: TextStyle(color: Color(0xFF7EA699), fontSize: 14),
              ),
              dropdownColor: const Color(0xFF072E21),
              icon: const Icon(Icons.expand_more, color: Color(0xFF3CE081)),
              isExpanded: true,
              items: tournaments.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(
                    t.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Round selector
// ---------------------------------------------------------------------------

class _RoundSelector extends StatelessWidget {
  const _RoundSelector({
    required this.selected,
    required this.numberOfRounds,
    required this.onChanged,
  });

  final int selected;
  final int numberOfRounds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: List.generate(numberOfRounds, (index) {
          final round = index + 1;
          final isSelected = round == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(round),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F5A3F) : const Color(0xFF072E21),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF3CE081) : const Color(0xFF165D43),
                  ),
                ),
                child: Text(
                  'Round $round',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF3CE081) : const Color(0xFF7EA699),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scorecard list
// ---------------------------------------------------------------------------

class _ScorecardList extends StatefulWidget {
  const _ScorecardList({
    required this.registrationService,
    required this.tournamentId,
    required this.round,
  });

  final RegistrationService registrationService;
  final String tournamentId;
  final int round;

  @override
  State<_ScorecardList> createState() => _ScorecardListState();
}

class _ScorecardListState extends State<_ScorecardList> {
  int? _expandedIndex;

  @override
  void didUpdateWidget(covariant _ScorecardList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournamentId != widget.tournamentId ||
        oldWidget.round != widget.round) {
      _expandedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.registrationService.streamRoundScoreDocs(
        tournamentId: widget.tournamentId,
        round: widget.round,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _StatusMessage(
            icon: Icons.error_outline,
            message: 'Unable to load scorecards right now.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3CE081)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _StatusMessage(
            icon: Icons.inbox_outlined,
            message: 'No scorecards uploaded for this round.',
          );
        }

        final sorted = List.of(docs)
          ..sort((a, b) {
            final nameA = (a.data()['playerName'] as String?) ?? '';
            final nameB = (b.data()['playerName'] as String?) ?? '';
            return nameA.compareTo(nameB);
          });

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final isExpanded = _expandedIndex == index;
            return _ScorecardCard(
              data: sorted[index].data(),
              isExpanded: isExpanded,
              onTap: () {
                setState(() {
                  _expandedIndex = isExpanded ? null : index;
                });
              },
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Scorecard card with expandable results
// ---------------------------------------------------------------------------

class _ScorecardCard extends StatelessWidget {
  const _ScorecardCard({
    required this.data,
    required this.isExpanded,
    required this.onTap,
  });

  final Map<String, dynamic> data;
  final bool isExpanded;
  final VoidCallback onTap;

  void _showScorecardImage(BuildContext context, String imageUrl, String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF031C14),
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF3CE081),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF7EA699)),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3CE081),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image_outlined,
                                    color: Color(0xFF7EA699), size: 48),
                                SizedBox(height: 8),
                                Text(
                                  'Could not load scorecard image.',
                                  style: TextStyle(
                                      color: Color(0xFF7EA699), fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerName = (data['playerName'] as String?)?.trim().isNotEmpty == true
        ? (data['playerName'] as String).trim()
        : 'Unknown Player';
    final courseName = (data['courseName'] as String?)?.trim().isNotEmpty == true
        ? (data['courseName'] as String).trim()
        : 'Unknown Course';
    final totalScore = data['totalScore'];
    final uploadedAt = data['uploadedAt'];
    final roundLabel = (data['roundLabel'] as String?)?.trim();
    final imageUrl = data['scorecardImageUrl'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF072E21),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded ? const Color(0xFF3CE081) : const Color(0xFF165D43),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    playerName,
                    style: const TextStyle(
                      color: Color(0xFF3CE081),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (totalScore is num)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3D25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1E8F5C)),
                    ),
                    child: Text(
                      totalScore.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF7EA699),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Course', value: courseName),
            const SizedBox(height: 4),
            _InfoRow(label: 'Uploaded', value: _formatTimestamp(uploadedAt)),
            if (roundLabel != null && roundLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              _InfoRow(label: 'Round', value: roundLabel),
            ],
            if (isExpanded) ...[
              const SizedBox(height: 12),
              if (imageUrl != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showScorecardImage(
                      context,
                      imageUrl,
                      '$playerName — $courseName',
                    ),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('View Scorecard Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3CE081),
                      side: const BorderSide(color: Color(0xFF1E8F5C)),
                      backgroundColor: const Color(0xFF0A3D25),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _RoundResultsTable(data: data),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(Object? value) {
    if (value is! Timestamp) return '-';
    final d = value.toDate();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$month/$day/${d.year}';
  }
}

// ---------------------------------------------------------------------------
// Round results table (read-only hole-by-hole scores)
// ---------------------------------------------------------------------------

class _RoundResultsTable extends StatelessWidget {
  const _RoundResultsTable({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rawScores = data['scoresByHole'] as Map<String, dynamic>?;
    final rawPars = data['parsByHole'] as Map<String, dynamic>?;

    if (rawScores == null || rawScores.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No hole-by-hole data available.',
          style: TextStyle(color: Color(0xFF7EA699), fontSize: 13),
        ),
      );
    }

    final scores = <int, int?>{};
    final pars = <int, int?>{};
    for (var hole = 1; hole <= 18; hole++) {
      scores[hole] = _toInt(rawScores['$hole']);
      pars[hole] = rawPars != null ? _toInt(rawPars['$hole']) : null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _NineHoleResultsTable(
            label: 'Front 9',
            startHole: 1,
            endHole: 9,
            scores: scores,
            pars: pars,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _NineHoleResultsTable(
            label: 'Back 9',
            startHole: 10,
            endHole: 18,
            scores: scores,
            pars: pars,
          ),
        ),
      ],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }
}

// ---------------------------------------------------------------------------
// Nine-hole results table (read-only)
// ---------------------------------------------------------------------------

class _NineHoleResultsTable extends StatelessWidget {
  const _NineHoleResultsTable({
    required this.label,
    required this.startHole,
    required this.endHole,
    required this.scores,
    required this.pars,
  });

  final String label;
  final int startHole;
  final int endHole;
  final Map<int, int?> scores;
  final Map<int, int?> pars;

  @override
  Widget build(BuildContext context) {
    final hasPars = pars.values.any((v) => v != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Color(0xFFB8D4C8),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFF165D43), width: 1),
            verticalInside: BorderSide(color: Color(0xFF165D43), width: 1),
            top: BorderSide(color: Color(0xFF1E8F5C), width: 1.2),
            left: BorderSide(color: Color(0xFF1E8F5C), width: 1.2),
            right: BorderSide(color: Color(0xFF1E8F5C), width: 1.2),
            bottom: BorderSide(color: Color(0xFF1E8F5C), width: 1.2),
          ),
          columnWidths: {
            0: const FlexColumnWidth(1),
            if (hasPars) 1: const FlexColumnWidth(1),
            if (hasPars) 2: const FlexColumnWidth(1) else 1: const FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF052A1A)),
              children: [
                const _Cell(
                  child: Text('#', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7EA699), fontWeight: FontWeight.w800)),
                ),
                if (hasPars)
                  const _Cell(
                    child: Text('Par', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFD4A843), fontWeight: FontWeight.w800)),
                  ),
                const _Cell(
                  child: Text('Score', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF3CE081), fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            for (var hole = startHole; hole <= endHole; hole++)
              TableRow(
                children: [
                  _Cell(
                    color: const Color(0xFF0A3D25),
                    child: Text('$hole', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB8D4C8), fontWeight: FontWeight.w700)),
                  ),
                  if (hasPars)
                    _Cell(
                      child: Text(
                        pars[hole]?.toString() ?? '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFD4A843), fontWeight: FontWeight.w700),
                      ),
                    ),
                  _Cell(
                    child: Text(
                      scores[hole]?.toString() ?? '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _scoreColor(scores[hole], pars[hole]),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF052A1A)),
              children: [
                _Cell(
                  child: Text(
                    startHole == 1 ? 'OUT' : 'IN',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF3CE081), fontWeight: FontWeight.w800),
                  ),
                ),
                if (hasPars)
                  _Cell(
                    child: Text(
                      _sum(pars, startHole, endHole),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFD4A843), fontWeight: FontWeight.w800),
                    ),
                  ),
                _Cell(
                  child: Text(
                    _sum(scores, startHole, endHole),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF3CE081), fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static Color _scoreColor(int? score, int? par) {
    if (score == null || par == null) return const Color(0xFFB8D4C8);
    if (score < par) return const Color(0xFF3CE081);
    if (score > par) return const Color(0xFFFF7B7B);
    return const Color(0xFFB8D4C8);
  }

  static String _sum(Map<int, int?> values, int start, int end) {
    var hasValue = false;
    var total = 0;
    for (var hole = start; hole <= end; hole++) {
      final value = values[hole];
      if (value != null) {
        hasValue = true;
        total += value;
      }
    }
    return hasValue ? '$total' : '-';
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _Cell extends StatelessWidget {
  const _Cell({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? const Color(0xFF072E21),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: const TextStyle(
          color: Color(0xFF7EA699),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF7EA699), size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF7EA699), fontSize: 15),
          ),
        ],
      ),
    );
  }
}
