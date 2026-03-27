import 'dart:convert';

class OcrFlaggedHole {
  final String player;
  final int hole;
  final int? score;
  final String reason;

  const OcrFlaggedHole({
    required this.player,
    required this.hole,
    required this.score,
    required this.reason,
  });

  factory OcrFlaggedHole.fromJson(Map<String, dynamic> json) {
    return OcrFlaggedHole(
      player: (json['player'] ?? '').toString(),
      hole: _toInt(json['hole']) ?? 0,
      score: _toInt(json['score'] ?? json['extracted']),
      reason: (json['reason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'player': player,
    'hole': hole,
    'score': score,
    'reason': reason,
  };
}

class OcrScorecardResponse {
  final String courseName;
  final List<String> warnings;
  final List<String> issues;
  final Map<int, int?> parByHole;
  final List<OcrPlayerScore> players;
  final String confidence;
  final String cardType;
  final List<OcrFlaggedHole> flaggedHoles;

  const OcrScorecardResponse({
    required this.courseName,
    required this.warnings,
    required this.issues,
    required this.parByHole,
    required this.players,
    required this.confidence,
    required this.cardType,
    required this.flaggedHoles,
  });

  List<String> get topLevelMessages => [...warnings, ...issues];

  factory OcrScorecardResponse.fromJson(Map<String, dynamic> json) {
    final players = _parsePlayers(json);
    final parByHole = _parseParByHole(json, players);

    return OcrScorecardResponse(
      courseName:
          _firstString(
            json,
            const ['course_name', 'courseName', 'course', 'course_title'],
          ) ??
          'Unknown Course',
      warnings: _parseMessageList(json, 'warnings'),
      issues:
          _parseMessageList(json, 'issues') +
          _parseMessageList(json, 'top_level_issues'),
      parByHole: parByHole,
      players: players,
      confidence: _firstString(json, const ['confidence']) ?? 'UNKNOWN',
      cardType: _firstString(json, const ['card_type', 'cardType']) ?? 'UNKNOWN',
      flaggedHoles: _parseFlaggedHoles(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_name': courseName,
      'warnings': warnings,
      'issues': issues,
      'par_by_hole': {
        for (final entry in parByHole.entries) '${entry.key}': entry.value,
      },
      'players': players.map((player) => player.toJson()).toList(),
      'confidence': confidence,
      'card_type': cardType,
      'flagged_holes': flaggedHoles.map((fh) => fh.toJson()).toList(),
    };
  }

  static List<OcrFlaggedHole> _parseFlaggedHoles(Map<String, dynamic> json) {
    final dynamic raw = json['flagged_holes'] ?? json['flaggedHoles'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => OcrFlaggedHole.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return const [];
  }

  static List<OcrPlayerScore> _parsePlayers(Map<String, dynamic> json) {
    final dynamic rawPlayers =
        json['players'] ?? json['player_scores'] ?? json['scores'];
    if (rawPlayers is List) {
      return rawPlayers
          .whereType<Map>()
          .map(
            (player) => OcrPlayerScore.fromJson(Map<String, dynamic>.from(player)),
          )
          .toList();
    }
    return const [];
  }

  static Map<int, int?> _parseParByHole(
    Map<String, dynamic> json,
    List<OcrPlayerScore> players,
  ) {
    final Map<int, int?> output = {
      for (var hole = 1; hole <= 18; hole++) hole: null,
    };
    final dynamic rawPars = json['par'] ?? json['pars'] ?? json['par_by_hole'];

    if (rawPars is Map) {
      for (final entry in rawPars.entries) {
        final hole = int.tryParse('${entry.key}');
        if (hole != null && hole >= 1 && hole <= 18) {
          output[hole] = _toInt(entry.value);
        }
      }
    } else if (rawPars is List) {
      for (var i = 0; i < rawPars.length && i < 18; i++) {
        output[i + 1] = _toInt(rawPars[i]);
      }
    }

    for (final player in players) {
      for (final holeEntry in player.holes.entries) {
        if (output[holeEntry.key] != null) {
          continue;
        }
        final inferredPar = holeEntry.value.par;
        if (inferredPar != null) {
          output[holeEntry.key] = inferredPar;
        }
      }
    }

    return output;
  }
}

class OcrPlayerScore {
  final String name;
  final Map<int, OcrHoleScore> holes;
  final int? front9Total;
  final int? back9Total;
  final int? grossTotal;

  const OcrPlayerScore({
    required this.name,
    required this.holes,
    required this.front9Total,
    required this.back9Total,
    required this.grossTotal,
  });

  factory OcrPlayerScore.fromJson(Map<String, dynamic> json) {
    final parsedHoles = <int, OcrHoleScore>{};
    final dynamic rawHoles = json['holes'];

    if (rawHoles is Map) {
      var fallbackHoleNumber = 1;
      for (final entry in rawHoles.entries) {
        final hole =
            _parseHoleNumber(entry.key) ??
            _parseHoleNumber(entry.value) ??
            fallbackHoleNumber;
        if (hole < 1 || hole > 18) {
          continue;
        }
        if (entry.value is Map) {
          parsedHoles[hole] = OcrHoleScore.fromJson(
            Map<String, dynamic>.from(entry.value),
            fallbackHole: hole,
          );
        } else {
          parsedHoles[hole] = OcrHoleScore(score: _toInt(entry.value));
        }

        if (hole >= fallbackHoleNumber) {
          fallbackHoleNumber = hole + 1;
        }
      }
    } else if (rawHoles is List) {
      for (var index = 0; index < rawHoles.length; index++) {
        final item = rawHoles[index];
        if (item is Map) {
          final hole =
              _toInt(item['hole']) ??
              _toInt(item['hole_number']) ??
              _toInt(item['number']) ??
              _parseHoleNumber(item) ??
              (index + 1);
          if (hole < 1 || hole > 18) {
            continue;
          }
          parsedHoles[hole] = OcrHoleScore.fromJson(
            Map<String, dynamic>.from(item),
            fallbackHole: hole,
          );
          continue;
        }
        final hole = index + 1;
        if (hole < 1 || hole > 18) {
          continue;
        }
        parsedHoles[hole] = OcrHoleScore(score: _toInt(item));
      }
    } else if (rawHoles is String) {
      final values = rawHoles
          .split(RegExp(r'[\s,|;/]+'))
          .where((value) => value.isNotEmpty);
      var hole = 1;
      for (final value in values) {
        if (hole > 18) {
          break;
        }
        parsedHoles[hole] = OcrHoleScore(score: _toInt(value));
        hole += 1;
      }
    }

    return OcrPlayerScore(
      name:
          (json['player'] ?? json['name'] ?? json['player_name'] ?? 'Unknown Player')
              .toString(),
      holes: parsedHoles,
      front9Total: _toInt(json['front_9_total'] ?? json['out'] ?? json['front9']),
      back9Total: _toInt(json['back_9_total'] ?? json['in'] ?? json['back9']),
      grossTotal: _toInt(json['gross_total'] ?? json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player': name,
      'holes': {
        for (final entry in holes.entries) '${entry.key}': entry.value.toJson(),
      },
      'front_9_total': front9Total,
      'back_9_total': back9Total,
      'gross_total': grossTotal,
    };
  }
}

class OcrHoleScore {
  final int? score;
  final int? par;
  final String? confidenceLevel;
  final double? confidence;

  const OcrHoleScore({
    required this.score,
    this.par,
    this.confidenceLevel,
    this.confidence,
  });

  bool get isLowConfidence {
    final normalized = confidenceLevel?.toLowerCase();
    if (normalized != null &&
        (normalized == 'low' ||
            normalized == 'weak' ||
            normalized == 'uncertain')) {
      return true;
    }
    return (confidence ?? 1) < 0.6;
  }

  factory OcrHoleScore.fromJson(
    Map<String, dynamic> json, {
    int? fallbackHole,
  }) {
    final score = _toInt(
      json['score'] ??
          json['strokes'] ??
          json['value'] ??
          json['gross'] ??
          json['player_score'] ??
          json['ocr_score'],
    );

    int? inferredScore = score;
    if (inferredScore == null) {
      inferredScore = _inferScoreFromUnknownShape(json, fallbackHole: fallbackHole);
    }

    return OcrHoleScore(
      score: inferredScore,
      par: _toInt(json['par']),
      confidenceLevel: _toNullableString(
        json['confidence_level'] ?? json['confidenceLevel'],
      ),
      confidence: _toDouble(json['confidence'] ?? json['score_confidence']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'par': par,
      'confidence_level': confidenceLevel,
      'confidence': confidence,
    };
  }
}

List<String> _parseMessageList(Map<String, dynamic> json, String key) {
  final dynamic raw = json[key];
  if (raw is List) {
    return raw
        .map((item) {
          if (item is String) {
            return item;
          }
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            return _toNullableString(map['message'] ?? map['text']) ??
                const JsonEncoder().convert(map);
          }
          return item.toString();
        })
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
  if (raw is String && raw.trim().isNotEmpty) {
    return [raw];
  }
  return const [];
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _toNullableString(json[key]);
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String? _toNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _toInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

int? _parseHoleNumber(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    return _toInt(map['hole']) ??
        _toInt(map['hole_number']) ??
        _toInt(map['number']) ??
        _parseHoleNumber(map['label']) ??
        _parseHoleNumber(map['key']);
  }

  final text = value.toString();
  final direct = int.tryParse(text);
  if (direct != null) {
    return direct;
  }

  final match = RegExp(r'(\d{1,2})').firstMatch(text);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

int? _inferScoreFromUnknownShape(
  Map<String, dynamic> json, {
  int? fallbackHole,
}) {
  final ignoredKeys = <String>{
    'hole',
    'hole_number',
    'number',
    'par',
    'confidence',
    'confidence_level',
    'confidenceLevel',
    'score_confidence',
    if (fallbackHole != null) '$fallbackHole',
  };

  for (final entry in json.entries) {
    if (ignoredKeys.contains(entry.key)) {
      continue;
    }
    final parsed = _toInt(entry.value);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}
