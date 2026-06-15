import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/course_selection.dart';
import '../models/ocr_scorecard_response.dart';
import '../models/upload_selection_context.dart';
import '../services/course_lookup_service.dart';
import '../services/ocr_service.dart';
import '../widgets/course_picker_dialog.dart';
import '../widgets/upload_context_dialog.dart';
import '../widgets/upload_widget.dart';

/// Batch scorecard upload for GMs. Walks the GM through:
/// 1. Choosing the tournament + round the cards belong to.
/// 2. Choosing the course (applied to every card in the batch).
/// 3. Picking multiple scorecard photos from the gallery.
/// 4. Running OCR on each photo (with progress).
/// 5. Reviewing each detected scorecard one at a time, assigning PROs, and
///    saving — reusing the same [OcrScorecardView] as the single-card flow.
class GmBatchUploadPage extends StatefulWidget {
  const GmBatchUploadPage({super.key});

  @override
  State<GmBatchUploadPage> createState() => _GmBatchUploadPageState();
}

enum _BatchPhase { setup, processing, review }

class _GmBatchUploadPageState extends State<GmBatchUploadPage> {
  static const Color _bg = Color(0xFF031C14);
  static const Color _accent = Color(0xFF3CE081);
  static const Color _muted = Color(0xFF7EA699);

  final OcrService _ocrService = OcrService(useMockData: false);
  final CourseLookupService _courseLookupService = CourseLookupService();
  final ImagePicker _imagePicker = ImagePicker();

  _BatchPhase _phase = _BatchPhase.setup;
  UploadSelectionContext? _uploadContext;
  CourseSelection? _courseSelection;

  final List<_BatchItem> _items = [];
  int _processedCount = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSetup());
  }

  Future<void> _runSetup() async {
    final gmUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final uploadContext = await showUploadContextDialog(
      context,
      gmUserId: gmUserId,
    );
    if (uploadContext == null || !mounted) {
      _popIfPossible();
      return;
    }

    final courseSelection = await showCoursePickerDialog(
      context,
      title: 'Select course',
      confirmLabel: 'Continue',
      lookupService: _courseLookupService,
    );
    if (courseSelection == null || courseSelection.name.trim().isEmpty || !mounted) {
      _popIfPossible();
      return;
    }

    final List<XFile> picked;
    try {
      picked = await _imagePicker.pickMultiImage();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not open gallery: $error')));
      _popIfPossible();
      return;
    }

    if (picked.isEmpty || !mounted) {
      _popIfPossible();
      return;
    }

    setState(() {
      _uploadContext = uploadContext;
      _courseSelection = courseSelection;
      _phase = _BatchPhase.processing;
      _processedCount = 0;
    });

    await _processImages(picked);
  }

  Future<void> _processImages(List<XFile> picked) async {
    final results = <_BatchItem>[];

    for (var index = 0; index < picked.length; index++) {
      final file = picked[index];
      try {
        final bytes = await file.readAsBytes();
        final fileName = file.name.isNotEmpty
            ? file.name
            : 'scorecard_batch_$index.jpg';
        final scorecard = await _ocrService.fetchScorecardResults(bytes, fileName);
        results.add(_BatchItem(imageBytes: bytes, scorecard: scorecard));
      } catch (error) {
        Uint8List? bytes;
        try {
          bytes = await file.readAsBytes();
        } catch (_) {
          bytes = null;
        }
        results.add(_BatchItem(imageBytes: bytes, error: '$error'));
      }

      if (!mounted) {
        return;
      }
      setState(() => _processedCount = index + 1);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(results);
      _currentIndex = 0;
      _phase = _BatchPhase.review;
    });
  }

  void _popIfPossible() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  int get _savedCount => _items.where((item) => item.saved).length;
  int get _skippedCount => _items.where((item) => item.skipped).length;

  Future<void> _saveCurrent() async {
    final item = _items[_currentIndex];
    final didSave = await item.viewKey.currentState?.confirmSelectedPro();
    if (didSave == true && mounted) {
      setState(() {
        item.saved = true;
        item.skipped = false;
      });
      _advance();
    }
  }

  void _skipCurrent() {
    setState(() {
      final item = _items[_currentIndex];
      if (!item.saved) {
        item.skipped = true;
      }
    });
    _advance();
  }

  void _advance() {
    if (_currentIndex < _items.length - 1) {
      setState(() => _currentIndex += 1);
    } else {
      _maybeFinish();
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex -= 1);
    }
  }

  void _maybeFinish() {
    final remaining = _items
        .where((item) => !item.saved && !item.skipped && item.error == null)
        .length;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Batch upload summary'),
          content: Text(
            'Saved: $_savedCount\n'
            'Skipped: $_skippedCount\n'
            'Not yet reviewed: $remaining',
          ),
          actions: [
            if (remaining > 0)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Keep reviewing'),
              ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _popIfPossible();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF083A28),
        foregroundColor: Colors.white,
        title: const Text('Batch Upload'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _BatchPhase.setup:
        return const Center(
          child: CircularProgressIndicator(color: _accent),
        );
      case _BatchPhase.processing:
        return _buildProcessing();
      case _BatchPhase.review:
        return _buildReview();
    }
  }

  Widget _buildProcessing() {
    final total = _processedCount == 0 ? null : _processedCount;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: _accent, size: 40),
            const SizedBox(height: 16),
            Text(
              total == null
                  ? 'Reading scorecards...'
                  : 'Processing scorecard $_processedCount...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFF0F5A3F),
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hang tight — running AI OCR on each photo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'No scorecards to review.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final item = _items[_currentIndex];
    final uploadContext = _uploadContext;

    return Column(
      children: [
        _buildReviewHeader(uploadContext),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: item.error != null
                ? _buildErrorCard(item)
                : OcrScorecardView(
                    key: item.viewKey,
                    scorecard: item.scorecard!,
                    uploadContext: uploadContext,
                    imageBytes: item.imageBytes ?? Uint8List(0),
                    courseSelection: _courseSelection,
                  ),
          ),
        ),
        _buildReviewControls(item),
      ],
    );
  }

  Widget _buildReviewHeader(UploadSelectionContext? uploadContext) {
    final statusLabel = StringBuffer('Card ${_currentIndex + 1} of ${_items.length}');
    statusLabel.write('  •  $_savedCount saved');
    if (_skippedCount > 0) {
      statusLabel.write('  •  $_skippedCount skipped');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF072E21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (uploadContext != null)
            Text(
              '${uploadContext.tournament.name} • ${uploadContext.roundLabel}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            statusLabel.toString(),
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(_BatchItem item) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B4513)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFFF6B6B)),
              SizedBox(width: 8),
              Text(
                'Could not read this scorecard',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.error ?? 'Unknown error',
            style: const TextStyle(color: Color(0xFFFFAA88), fontSize: 12),
          ),
          if (item.imageBytes != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(item.imageBytes!, height: 200, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Skip this card and review it manually later.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewControls(_BatchItem item) {
    final isLast = _currentIndex == _items.length - 1;
    final canSave = item.error == null && !item.saved;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF072E21),
        border: Border(top: BorderSide(color: Color(0xFF165D43))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: _currentIndex > 0 ? _goPrevious : null,
              icon: const Icon(Icons.chevron_left),
              color: Colors.white,
              disabledColor: const Color(0xFF3E5C50),
              tooltip: 'Previous',
            ),
            const SizedBox(width: 4),
            if (item.saved)
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: _accent, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Saved',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: OutlinedButton(
                  onPressed: _skipCurrent,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _muted,
                    side: const BorderSide(color: Color(0xFF165D43)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(item.error != null ? 'Skip' : 'Skip card'),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: const Color(0xFF03301F),
                  disabledBackgroundColor: const Color(0xFF1F4734),
                  disabledForegroundColor: const Color(0xFF5E7D72),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: canSave
                    ? _saveCurrent
                    : (isLast ? _maybeFinish : _advance),
                child: Text(
                  canSave
                      ? 'Save & Next'
                      : (isLast ? 'Finish' : 'Next'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One scorecard in a batch: the source image, its OCR result (or error), and
/// whether the GM has already saved or skipped it.
class _BatchItem {
  _BatchItem({
    required this.imageBytes,
    this.scorecard,
    this.error,
  });

  final Uint8List? imageBytes;
  final OcrScorecardResponse? scorecard;
  final String? error;
  final GlobalKey<OcrScorecardViewState> viewKey = GlobalKey<OcrScorecardViewState>();

  bool saved = false;
  bool skipped = false;
}
