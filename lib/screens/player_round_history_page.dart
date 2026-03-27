import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/player_score_upload_service.dart';

class PlayerRoundHistoryPage extends StatelessWidget {
  const PlayerRoundHistoryPage({
    required this.userId,
    required this.scoreService,
    super.key,
  });

  final String userId;
  final PlayerScoreUploadService scoreService;

  @override
  Widget build(BuildContext context) {
    final roundsStream = scoreService.streamUserScorecardHistory(userId);

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
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3CE081)),
            );
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
              final imageUrl = roundData['scorecardImageUrl'] as String?;

              return GestureDetector(
                onTap: imageUrl != null
                    ? () => _showScorecardImage(context, imageUrl, courseName)
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
                      Text(
                        courseName,
                        style: const TextStyle(
                          color: Color(0xFF3CE081),
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
            },
          );
        },
      ),
    );
  }

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
