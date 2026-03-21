import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlayerRoundHistoryPage extends StatelessWidget {
  const PlayerRoundHistoryPage({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  Widget build(BuildContext context) {
    final roundsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('scorecards')
        .orderBy('uploadedAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142234),
        foregroundColor: Colors.white,
        title: const Text('Round History'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: roundsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _StatusMessage(
              icon: Icons.error_outline,
              message: 'Unable to load your rounds right now.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final roundDocs = snapshot.data?.docs ?? [];
          if (roundDocs.isEmpty) {
            return const _StatusMessage(
              icon: Icons.history,
              message: 'No rounds logged yet.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: roundDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final roundData = roundDocs[index].data();
              final courseName =
                  (roundData['courseName'] as String?)?.trim().isNotEmpty == true
                      ? (roundData['courseName'] as String).trim()
                      : 'Unknown course';
              final totalScore = roundData['totalScore'];
              final uploadedAt = roundData['uploadedAt'];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF142234),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1F3A56)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: const TextStyle(
                        color: Color(0xFF4FC3F7),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Date',
                      value: _formatUploadedAt(uploadedAt),
                    ),
                    const SizedBox(height: 4),
                    _DetailRow(
                      label: 'Score',
                      value: totalScore is num ? totalScore.toString() : '-',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatUploadedAt(Object? uploadedAt) {
    if (uploadedAt is! Timestamp) {
      return '-';
    }

    final date = uploadedAt.toDate();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year;

    return '$month/$day/$year';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: const TextStyle(
          color: Color(0xFF9FB3C8),
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
  const _StatusMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF9FB3C8), size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
