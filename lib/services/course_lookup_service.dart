import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/course_selection.dart';

/// Sources canonical golf-course names so that every player uploading a score
/// for the same course ends up referencing the same course identity.
///
/// Two sources are merged on every search:
///   1. The shared `/courses` Firestore collection — courses anyone has used
///      before. Free, instant, and works without a Places key. Keyed by
///      `place_id` so it stays deduplicated.
///   2. Google Places Autocomplete (New), filtered to golf courses — finds
///      courses nobody has uploaded yet.
///
/// When a course is confirmed, [recordCourseUse] upserts it back into
/// `/courses` so the next player gets it instantly from source #1.
class CourseLookupService {
  CourseLookupService({
    FirebaseFirestore? firestore,
    http.Client? client,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client();

  final FirebaseFirestore _firestore;
  final http.Client _client;

  CollectionReference<Map<String, dynamic>> get _coursesRef =>
      _firestore.collection('courses');

  /// Returns up to [limit] course suggestions matching [query], with
  /// previously-used (cached) courses first. Never throws — on any failure it
  /// returns whatever it managed to gather (possibly empty).
  Future<List<CourseSelection>> searchCourses(
    String query, {
    int limit = 8,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return const [];
    }

    final results = await Future.wait([
      _searchCachedCourses(trimmed),
      _searchPlaces(trimmed),
    ]);

    final cached = results[0];
    final remote = results[1];

    // Cached courses first; append Places results that aren't already cached.
    final seenPlaceIds = <String>{
      for (final c in cached)
        if (c.placeId != null) c.placeId!,
    };
    final merged = <CourseSelection>[...cached];
    for (final suggestion in remote) {
      final id = suggestion.placeId;
      if (id != null && seenPlaceIds.contains(id)) {
        continue;
      }
      if (id != null) seenPlaceIds.add(id);
      merged.add(suggestion);
    }

    return merged.take(limit).toList();
  }

  /// Prefix search over the shared `/courses` cache by lowercased name.
  Future<List<CourseSelection>> _searchCachedCourses(String query) async {
    try {
      final lower = query.toLowerCase();
      final snapshot = await _coursesRef
          .orderBy('nameLower')
          .startAt([lower])
          .endAt(['$lower'])
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CourseSelection(
          name: (data['name'] as String?)?.trim() ?? doc.id,
          placeId: data['placeId'] as String? ?? doc.id,
          secondaryText: data['secondaryText'] as String?,
        );
      }).toList();
    } catch (_) {
      // Missing index or offline — just skip cached results.
      return const [];
    }
  }

  /// Golf-course autocomplete via our Cloud Run proxy (which forwards to
  /// Google Places New and keeps the API key server-side).
  Future<List<CourseSelection>> _searchPlaces(String query) async {
    if (!AppConfig.placesSearchEnabled) {
      return const [];
    }

    try {
      final response = await _client.post(
        Uri.parse(AppConfig.placesAutocompleteUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'input': query}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final decoded = jsonDecode(response.body);
      final suggestions = (decoded is Map && decoded['suggestions'] is List)
          ? decoded['suggestions'] as List
          : const [];

      final out = <CourseSelection>[];
      for (final entry in suggestions) {
        if (entry is! Map) continue;
        final prediction = entry['placePrediction'];
        if (prediction is! Map) continue;

        final placeId = prediction['placeId'] as String?;
        final structured =
            prediction['structuredFormat'] is Map ? prediction['structuredFormat'] as Map : null;
        final mainText = _textField(structured?['mainText']);
        final secondaryText = _textField(structured?['secondaryText']);
        final fullText = _textField(prediction['text']);

        final name = (mainText ?? fullText)?.trim();
        if (name == null || name.isEmpty) continue;

        out.add(CourseSelection(
          name: name,
          placeId: placeId,
          secondaryText: secondaryText?.trim(),
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Pulls the `.text` string out of a Places `{ "text": "..." }` object.
  static String? _textField(dynamic node) {
    if (node is Map) {
      final value = node['text'];
      if (value is String) return value;
    }
    return null;
  }

  /// Upserts a confirmed course into the shared `/courses` cache so future
  /// uploads can reuse the same canonical name. No-op for free-text courses
  /// (no [CourseSelection.placeId]) — they have no stable identity to dedupe on.
  Future<void> recordCourseUse(CourseSelection course) async {
    if (!course.isCanonical) {
      return;
    }
    try {
      await _coursesRef.doc(course.placeId).set({
        'placeId': course.placeId,
        'name': course.name,
        'nameLower': course.name.toLowerCase(),
        if (course.secondaryText != null) 'secondaryText': course.secondaryText,
        'lastUsedAt': FieldValue.serverTimestamp(),
        'useCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (_) {
      // Best-effort cache write; never block an upload on it.
    }
  }
}
