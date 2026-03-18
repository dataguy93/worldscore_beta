class OcrResult {
  const OcrResult({
    required this.courseName,
    required this.issues,
    required this.par,
    required this.parFront9Total,
    required this.parBack9Total,
    required this.players,
  });

  final String? courseName;
  final List<String> issues;
  final List<int> par;
  final int? parFront9Total;
  final int? parBack9Total;
  final List<OcrPlayer> players;

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    return OcrResult(
      courseName: _asString(json['course_name']),
      issues: _asStringList(json['issues']),
      par: _asIntList(json['par']),
      parFront9Total: _asInt(json['par_front_9_total']),
      parBack9Total: _asInt(json['par_back_9_total']),
      players: _asPlayerList(json['players']),
    );
  }

  static List<OcrPlayer> _asPlayerList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((rawPlayer) => OcrPlayer.fromJson(Map<String, dynamic>.from(rawPlayer)))
        .toList(growable: false);
  }
}

class OcrPlayer {
  const OcrPlayer({
    required this.name,
    required this.holes,
    required this.front9Total,
    required this.back9Total,
    required this.grossTotal,
    required this.handicap,
    required this.notes,
  });

  final String? name;
  final List<int> holes;
  final int? front9Total;
  final int? back9Total;
  final int? grossTotal;
  final int? handicap;
  final String? notes;

  factory OcrPlayer.fromJson(Map<String, dynamic> json) {
    return OcrPlayer(
      name: _asString(json['name']),
      holes: _asIntList(json['holes']),
      front9Total: _asInt(json['front_9_total']),
      back9Total: _asInt(json['back_9_total']),
      grossTotal: _asInt(json['gross_total']),
      handicap: _asInt(json['handicap']),
      notes: _asString(json['notes']),
    );
  }
}

String? _asString(Object? value) {
  if (value == null) {
    return null;
  }

  final parsed = value.toString().trim();
  return parsed.isEmpty ? null : parsed;
}

int? _asInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

List<int> _asIntList(Object? value) {
  if (value is! List) {
    return const [];
  }

  final parsed = <int>[];
  for (final element in value) {
    final intValue = _asInt(element);
    if (intValue != null) {
      parsed.add(intValue);
    }
  }

  return parsed;
}

List<String> _asStringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  final parsed = <String>[];
  for (final element in value) {
    final stringValue = _asString(element);
    if (stringValue != null) {
      parsed.add(stringValue);
    }
  }

  return parsed;
}
