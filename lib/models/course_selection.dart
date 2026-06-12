/// A course chosen for a scorecard upload.
///
/// When [placeId] is non-null the course came from Google Places (or the
/// shared `/courses` cache that mirrors it), so every player who picks the same
/// course shares the same [placeId] and the same canonical [name] — that's what
/// keeps course names uniform across uploads. When [placeId] is null the user
/// typed a free-form name that couldn't be matched to a known course.
class CourseSelection {
  const CourseSelection({
    required this.name,
    this.placeId,
    this.secondaryText,
  });

  /// Free-form fallback: a typed name with no canonical place behind it.
  factory CourseSelection.freeText(String name) =>
      CourseSelection(name: name.trim());

  /// Canonical display name (e.g. "Pebble Beach Golf Links").
  final String name;

  /// Stable Google Places id. The canonical key for course identity.
  final String? placeId;

  /// Locality / address line used to disambiguate same-named courses.
  final String? secondaryText;

  bool get isCanonical => placeId != null && placeId!.isNotEmpty;

  CourseSelection copyWith({String? name, String? placeId, String? secondaryText}) {
    return CourseSelection(
      name: name ?? this.name,
      placeId: placeId ?? this.placeId,
      secondaryText: secondaryText ?? this.secondaryText,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CourseSelection &&
      other.name == name &&
      other.placeId == placeId;

  @override
  int get hashCode => Object.hash(name, placeId);
}
