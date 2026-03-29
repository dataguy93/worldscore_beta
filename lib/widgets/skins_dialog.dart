import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ocr_scorecard_response.dart';
import '../services/skins_calculator.dart';

class SkinsDialog extends StatefulWidget {
  final List<OcrPlayerScore> players;
  final Map<String, Map<int, int?>> playerScores;
  final Map<int, int?> handicapByHole;

  const SkinsDialog({
    super.key,
    required this.players,
    required this.playerScores,
    required this.handicapByHole,
  });

  @override
  State<SkinsDialog> createState() => _SkinsDialogState();
}

class _SkinsDialogState extends State<SkinsDialog> {
  late final Map<String, TextEditingController> _controllers;
  SkinsResult? _result;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final player in widget.players)
        player.name: TextEditingController(text: '0'),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    final playerHandicaps = <String, int>{};
    for (final player in widget.players) {
      playerHandicaps[player.name] =
          int.tryParse(_controllers[player.name]?.text ?? '0') ?? 0;
    }
    setState(() {
      _result = SkinsCalculator.calculate(
        playerScores: widget.playerScores,
        playerHandicaps: playerHandicaps,
        handicapByHole: widget.handicapByHole,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasStrokeIndex =
        widget.handicapByHole.values.any((v) => v != null);
    final result = _result;
    final tooFewPlayers = widget.players.length < 2;

    return Dialog(
      backgroundColor: const Color(0xFF05162F),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Calculate Skins',
              style: TextStyle(
                color: Color(0xFFD7E4F7),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning when no stroke index data
                    if (!hasStrokeIndex)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A1A0A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF8B4513)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Color(0xFFFFCF66)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No hole stroke index data available. '
                                'Handicaps will have no effect — skins '
                                'will be calculated using gross scores.',
                                style: TextStyle(
                                    color: Color(0xFFFFCF66), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Handicap entry
                    const Text(
                      'PLAYER HANDICAPS',
                      style: TextStyle(
                        color: Color(0xFF72D981),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final player in widget.players) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              player.name,
                              style: const TextStyle(
                                color: Color(0xFF57C9FF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _controllers[player.name],
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]')),
                              ],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFD7E4F7),
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: const Color(0xFF112B4E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    const SizedBox(height: 4),

                    // Calculate button
                    Center(
                      child: FilledButton.icon(
                        onPressed: tooFewPlayers ? null : _calculate,
                        icon: const Icon(Icons.calculate),
                        label: const Text('Calculate'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2D7C2F),
                        ),
                      ),
                    ),

                    if (tooFewPlayers) ...[
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'At least 2 players required for skins.',
                          style:
                              TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
                        ),
                      ),
                    ],

                    // Results
                    if (result != null) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF2B578A)),
                      const SizedBox(height: 8),
                      Text(
                        result.usedNetScores
                            ? 'RESULTS (NET SCORES)'
                            : 'RESULTS (GROSS SCORES)',
                        style: const TextStyle(
                          color: Color(0xFF72D981),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Totals box
                      _TotalSkinsBox(totalSkins: result.totalSkins),

                      const SizedBox(height: 12),

                      // Hole-by-hole breakdown
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _HoleBreakdownTable(
                          result: result,
                          playerNames:
                              widget.players.map((p) => p.name).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Close button
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalSkinsBox extends StatelessWidget {
  final Map<String, int> totalSkins;

  const _TotalSkinsBox({required this.totalSkins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D7C2F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL SKINS',
            style: TextStyle(
              color: Color(0xFF67CC70),
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          for (final entry in totalSkins.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: Color(0xFF57C9FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${entry.value} ${entry.value == 1 ? 'skin' : 'skins'}',
                    style: TextStyle(
                      color: entry.value > 0
                          ? const Color(0xFF67CC70)
                          : const Color(0xFF6E8CAE),
                      fontWeight: FontWeight.w800,
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

class _HoleBreakdownTable extends StatelessWidget {
  final SkinsResult result;
  final List<String> playerNames;

  const _HoleBreakdownTable({
    required this.result,
    required this.playerNames,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: const TableBorder(
        horizontalInside: BorderSide(color: Color(0xFF2B578A), width: 0.5),
        verticalInside: BorderSide(color: Color(0xFF2B578A), width: 0.5),
        top: BorderSide(color: Color(0xFF2D5A91), width: 1),
        bottom: BorderSide(color: Color(0xFF2D5A91), width: 1),
        left: BorderSide(color: Color(0xFF2D5A91), width: 1),
        right: BorderSide(color: Color(0xFF2D5A91), width: 1),
      ),
      children: [
        // Header row
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF081A35)),
          children: [
            _cell('#', header: true),
            for (final name in playerNames)
              _cell(
                name.length > 10 ? '${name.substring(0, 10)}.' : name,
                header: true,
                color: const Color(0xFF57C9FF),
              ),
            _cell('Skins', header: true, color: const Color(0xFFFFCC2D)),
            _cell('Winner', header: true, color: const Color(0xFF67CC70)),
          ],
        ),
        // Data rows
        for (final hole in result.holeResults)
          TableRow(
            decoration: BoxDecoration(
              color: hole.winner != null
                  ? const Color(0xFF0D2A1A)
                  : const Color(0xFF102447),
            ),
            children: [
              _cell('${hole.hole}'),
              for (final name in playerNames)
                _cell(
                  hole.netScores[name]?.toString() ?? '-',
                  color: hole.winner == name
                      ? const Color(0xFF67CC70)
                      : null,
                  bold: hole.winner == name,
                ),
              _cell(
                '${hole.skinsValue}',
                color: hole.skinsValue > 1
                    ? const Color(0xFFFFCC2D)
                    : null,
                bold: hole.skinsValue > 1,
              ),
              _cell(
                hole.winner != null
                    ? (hole.winner!.length > 10
                        ? '${hole.winner!.substring(0, 10)}.'
                        : hole.winner!)
                    : 'Carry',
                color: hole.winner != null
                    ? const Color(0xFF67CC70)
                    : const Color(0xFF6E8CAE),
              ),
            ],
          ),
      ],
    );
  }

  static Widget _cell(
    String text, {
    bool header = false,
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ??
              (header ? const Color(0xFF8FAECC) : const Color(0xFFD6E1F1)),
          fontWeight: (header || bold) ? FontWeight.w800 : FontWeight.w600,
          fontSize: header ? 11 : 12,
        ),
      ),
    );
  }
}
