class SkinHoleResult {
  final int hole;
  final int skinsValue;
  final String? winner;
  final Map<String, int> netScores;

  const SkinHoleResult({
    required this.hole,
    required this.skinsValue,
    required this.winner,
    required this.netScores,
  });
}

class SkinsResult {
  final List<SkinHoleResult> holeResults;
  final Map<String, int> totalSkins;
  final bool usedNetScores;

  const SkinsResult({
    required this.holeResults,
    required this.totalSkins,
    required this.usedNetScores,
  });
}

class SkinsCalculator {
  /// Calculate skins game results.
  ///
  /// [playerScores] maps player name -> (hole number -> gross score).
  /// [playerHandicaps] maps player name -> course handicap.
  /// [handicapByHole] maps hole number -> stroke index for net score allocation.
  static SkinsResult calculate({
    required Map<String, Map<int, int?>> playerScores,
    required Map<String, int> playerHandicaps,
    required Map<int, int?> handicapByHole,
  }) {
    final playerNames = playerScores.keys.toList();
    final hasStrokeIndex = handicapByHole.values.any((v) => v != null);

    // Build net scores per hole per player.
    final Map<String, Map<int, int?>> netScores = {};
    for (final name in playerNames) {
      netScores[name] = {};
      for (var hole = 1; hole <= 18; hole++) {
        final gross = playerScores[name]?[hole];
        if (gross == null) {
          netScores[name]![hole] = null;
          continue;
        }
        if (hasStrokeIndex) {
          final strokeIndex = handicapByHole[hole];
          final handicap = playerHandicaps[name] ?? 0;
          final strokes =
              strokeIndex != null ? _strokesOnHole(handicap, strokeIndex) : 0;
          netScores[name]![hole] = gross - strokes;
        } else {
          netScores[name]![hole] = gross;
        }
      }
    }

    // Walk holes and apply skins carry-over rules.
    final List<SkinHoleResult> holeResults = [];
    final Map<String, int> totalSkins = {
      for (final name in playerNames) name: 0,
    };
    int carry = 0;

    for (var hole = 1; hole <= 18; hole++) {
      final value = 1 + carry;
      final Map<String, int> holeNetScores = {};

      for (final name in playerNames) {
        final score = netScores[name]?[hole];
        if (score != null) {
          holeNetScores[name] = score;
        }
      }

      if (holeNetScores.isEmpty) {
        holeResults.add(SkinHoleResult(
          hole: hole,
          skinsValue: value,
          winner: null,
          netScores: holeNetScores,
        ));
        carry += 1;
        continue;
      }

      final minScore = holeNetScores.values.reduce((a, b) => a < b ? a : b);
      final winners = holeNetScores.entries
          .where((e) => e.value == minScore)
          .map((e) => e.key)
          .toList();

      if (winners.length == 1) {
        totalSkins[winners.first] =
            (totalSkins[winners.first] ?? 0) + value;
        holeResults.add(SkinHoleResult(
          hole: hole,
          skinsValue: value,
          winner: winners.first,
          netScores: holeNetScores,
        ));
        carry = 0;
      } else {
        holeResults.add(SkinHoleResult(
          hole: hole,
          skinsValue: value,
          winner: null,
          netScores: holeNetScores,
        ));
        carry += 1;
      }
    }

    return SkinsResult(
      holeResults: holeResults,
      totalSkins: totalSkins,
      usedNetScores: hasStrokeIndex,
    );
  }

  /// How many handicap strokes a player receives on a given hole.
  ///
  /// A player with course handicap H receives floor(H/18) strokes on every
  /// hole, plus one additional stroke on holes whose stroke index is
  /// <= (H % 18).
  static int _strokesOnHole(int handicap, int strokeIndex) {
    if (handicap <= 0 || strokeIndex <= 0) return 0;
    final baseStrokes = handicap ~/ 18;
    final extraCutoff = handicap % 18;
    return baseStrokes + (strokeIndex <= extraCutoff ? 1 : 0);
  }
}
