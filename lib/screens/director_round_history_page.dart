import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/tournament.dart';
import '../services/registration_service.dart';
import '../services/tournament_service.dart';

class DirectorRoundHistoryPage extends StatefulWidget {
  const DirectorRoundHistoryPage({super.key});

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
      appBar: AppBar(
        backgroundColor: const Color(0xFF072E21),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Round History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

          // Resolve value to the exact instance in the current list so Flutter's
          // dropdown assertion (value must appear exactly once in items) is satisfied
          // even after the stream emits new Tournament objects.
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

class _ScorecardList extends StatelessWidget {
  const _ScorecardList({
    required this.registrationService,
    required this.tournamentId,
    required this.round,
  });

  final RegistrationService registrationService;
  final String tournamentId;
  final int round;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: registrationService.streamRoundScoreDocs(
        tournamentId: tournamentId,
        round: round,
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

        // Sort by player name for consistent ordering.
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
            return _ScorecardCard(data: sorted[index].data());
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Scorecard card
// ---------------------------------------------------------------------------

class _ScorecardCard extends StatelessWidget {
  const _ScorecardCard({required this.data});

  final Map<String, dynamic> data;

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
      onTap: imageUrl != null
          ? () => _showScorecardImage(context, imageUrl, '$playerName — $courseName')
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF072E21),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF165D43)),
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
            if (imageUrl != null) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.image_outlined, color: Color(0xFF7EA699), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Tap to view scorecard',
                    style: TextStyle(
                      color: Color(0xFF7EA699),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
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
