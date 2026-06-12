import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/course_selection.dart';
import '../services/course_lookup_service.dart';

/// Shows a search-and-select dialog for picking a golf course. Returns the
/// chosen [CourseSelection] (canonical when picked from a suggestion, free-text
/// when typed), or null if cancelled.
///
/// [title] / [confirmLabel] let the same dialog serve both the pre-capture
/// prompt and the post-OCR "change course" flow. [initialQuery] pre-fills the
/// search box (e.g. with the course name the OCR read off the card).
Future<CourseSelection?> showCoursePickerDialog(
  BuildContext context, {
  String title = 'Select course',
  String confirmLabel = 'Continue',
  String initialQuery = '',
  CourseLookupService? lookupService,
}) {
  return showDialog<CourseSelection>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _CoursePickerDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialQuery: initialQuery,
      lookupService: lookupService ?? CourseLookupService(),
    ),
  );
}

class _CoursePickerDialog extends StatefulWidget {
  const _CoursePickerDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialQuery,
    required this.lookupService,
  });

  final String title;
  final String confirmLabel;
  final String initialQuery;
  final CourseLookupService lookupService;

  @override
  State<_CoursePickerDialog> createState() => _CoursePickerDialogState();
}

class _CoursePickerDialogState extends State<_CoursePickerDialog> {
  late final TextEditingController _controller;
  Timer? _debounce;
  int _requestSeq = 0;
  List<CourseSelection> _suggestions = const [];
  bool _isSearching = false;
  CourseSelection? _selected;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().length >= 2) {
      _runSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Typing invalidates any previously picked suggestion.
    setState(() => _selected = null);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _suggestions = const [];
        _isSearching = false;
      });
      return;
    }

    final seq = ++_requestSeq;
    setState(() => _isSearching = true);

    final results = await widget.lookupService.searchCourses(trimmed);

    // Drop stale responses from earlier keystrokes.
    if (!mounted || seq != _requestSeq) {
      return;
    }
    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }

  void _pick(CourseSelection course) {
    setState(() {
      _selected = course;
      _controller.text = course.name;
      _controller.selection = TextSelection.collapsed(offset: course.name.length);
      _suggestions = const [];
    });
  }

  void _confirm() {
    final selected = _selected;
    if (selected != null) {
      Navigator.of(context).pop(selected);
      return;
    }
    final typed = _controller.text.trim();
    if (typed.isEmpty) return;
    // No suggestion chosen — fall back to a free-text course.
    Navigator.of(context).pop(CourseSelection.freeText(typed));
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _controller.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConfig.placesSearchEnabled
                  ? 'Search for the course and pick it from the list so scores '
                      'for the same course stay grouped together.'
                  : 'Start typing to reuse a previously-entered course, or type '
                      'a new course name.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Course',
                hintText: 'e.g. Pebble Beach Golf Links',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_selected?.isCanonical == true
                        ? const Icon(Icons.check_circle, color: Color(0xFF3CE081))
                        : null),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _onChanged(value);
                setState(() {}); // refresh confirm-enabled state
              },
              onSubmitted: (_) => _confirm(),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: Material(
                  color: const Color(0xFF0E2A52),
                  borderRadius: BorderRadius.circular(8),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final course = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.golf_course, size: 20),
                        title: Text(
                          course.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: course.secondaryText != null
                            ? Text(
                                course.secondaryText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () => _pick(course),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canConfirm ? _confirm : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
