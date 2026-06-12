import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ocr_scorecard_response.dart';
import '../models/tournament.dart';
import '../models/tournament_registration.dart';
import '../services/ocr_service.dart';
import '../services/pro_score_upload_service.dart';
import '../services/registration_service.dart';
import '../services/tournament_service.dart';
import 'menu_card.dart';
import 'scorecard_camera_screen.dart';
import 'skins_dialog.dart';

class GmUploadWidget extends StatelessWidget {
  const GmUploadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _UploadWidget(
      requiresUploadContext: true,
      subtitle: 'Scan and upload scorecards as players finish each day.',
      menuBackgroundColor: Color(0xFF093823),
      menuBorderColor: Color(0xFF137A48),
      menuTitleColor: Color(0xFF3CE081),
      menuSubtitleColor: Color(0xFF7EA699),
      menuIcon: Icons.upload_file_rounded,
      menuBorderRadius: 24,
      menuMinHeight: 100.8,
      menuTitleFontSize: 24,
      menuPadding: EdgeInsets.all(18),
    );
  }
}

class ProUploadWidget extends StatelessWidget {
  const ProUploadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _UploadWidget(
      requiresUploadContext: false,
      subtitle: 'Submit a new scorecard using AI OCR.',
      menuBackgroundColor: Color(0xFF093823),
      menuBorderColor: Color(0xFF137A48),
      menuTitleColor: Color(0xFF3CE081),
      menuSubtitleColor: Color(0xFF7EA699),
      menuIcon: Icons.upload_file_rounded,
      menuBorderRadius: 24,
      menuMinHeight: 100.8,
      menuTitleFontSize: 24,
      menuPadding: EdgeInsets.all(18),
    );
  }
}

class _UploadWidget extends StatefulWidget {
  const _UploadWidget({
    required this.requiresUploadContext,
    required this.subtitle,
    this.menuBackgroundColor = const Color(0xFF142234),
    this.menuBorderColor = const Color(0xFF1F3A56),
    this.menuTitleColor = const Color(0xFF4FC3F7),
    this.menuSubtitleColor = const Color(0xFF9FB3C8),
    this.menuIcon,
    this.menuBorderRadius = 12,
    this.menuPadding = const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    this.menuTitleFontSize = 18,
    this.menuMinHeight,
  });

  final bool requiresUploadContext;
  final String subtitle;
  final Color menuBackgroundColor;
  final Color menuBorderColor;
  final Color menuTitleColor;
  final Color menuSubtitleColor;
  final IconData? menuIcon;
  final double menuBorderRadius;
  final EdgeInsetsGeometry menuPadding;
  final double menuTitleFontSize;
  final double? menuMinHeight;

  @override
  State<_UploadWidget> createState() => _UploadWidgetState();
}

class _UploadWidgetState extends State<_UploadWidget> with TickerProviderStateMixin {
  final OcrService _ocrService = OcrService(useMockData: false);
  final TournamentService _tournamentService = TournamentService();
  final RegistrationService _registrationService = RegistrationService();
  final ProScoreUploadService _proScoreUploadService = ProScoreUploadService();
  bool _isUploadingTestImage = false;

  AnimationController? _progressController;
  double _uploadProgress = 0.0;
  bool _isCompletingProgress = false;

  @override
  void dispose() {
    _progressController?.dispose();
    super.dispose();
  }

  void _startUploadProgress() {
    _progressController?.dispose();
    _uploadProgress = 0.0;
    _isCompletingProgress = false;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..addListener(() {
        if (!_isCompletingProgress && mounted) {
          setState(() {
            _uploadProgress =
                Curves.easeOut.transform(_progressController!.value) * 0.95;
          });
        }
      })
      ..forward();
  }

  Future<void> _completeUploadProgress() async {
    _isCompletingProgress = true;
    final startProgress = _uploadProgress;
    _progressController?.stop();
    _progressController?.dispose();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _uploadProgress = startProgress +
                (1.0 - startProgress) *
                    Curves.easeInOut.transform(_progressController!.value);
          });
        }
      });
    await _progressController!.forward();
  }

  void _resetUploadProgress() {
    _progressController?.stop();
    _progressController?.dispose();
    _progressController = null;
    _uploadProgress = 0.0;
    _isCompletingProgress = false;
  }

  void _showOcrResults(
    OcrScorecardResponse scorecard, {
    _UploadSelectionContext? uploadContext,
    required Uint8List imageBytes,
    String? courseNameOverride,
  }) {
    final scorecardViewKey = GlobalKey<_OcrScorecardViewState>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            decoration: BoxDecoration(
              color: const Color(0xFF05162F),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: OcrScorecardView(
                      key: scorecardViewKey,
                      scorecard: scorecard,
                      uploadContext: uploadContext,
                      imageBytes: imageBytes,
                      courseNameOverride: courseNameOverride,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () {
                        showDialog<void>(
                          context: dialogContext,
                          builder: (jsonDialogContext) {
                            return AlertDialog(
                              title: const Text('Raw OCR JSON'),
                              content: SingleChildScrollView(
                                child: SelectableText(
                                  const JsonEncoder.withIndent('  ').convert(scorecard.toJson()),
                                ),
                              ),
                              actions: [
                                FilledButton(
                                  onPressed: () => Navigator.of(jsonDialogContext).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('View Raw JSON'),
                    ),
                    TextButton(
                      onPressed: () {
                        scorecardViewKey.currentState?.showSkinsCalculator();
                      },
                      child: const Text('Calculate Skins'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final didUpload =
                            await scorecardViewKey.currentState?.confirmSelectedPro();
                        if (didUpload == true && dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      child: const Text('Confirm Score'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Prompts the PRO to enter the course name before the camera opens. Returns
  /// the trimmed name, or null if they cancel (which aborts the upload).
  Future<String?> _promptForCourseName() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final canContinue = controller.text.trim().isNotEmpty;
            return AlertDialog(
              title: const Text('Enter course name'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter the course name for this round before taking the '
                    'scorecard photo.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Course name',
                      hintText: 'Enter course name',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        Navigator.of(dialogContext).pop(value.trim());
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: canContinue
                      ? () => Navigator.of(dialogContext).pop(controller.text.trim())
                      : null,
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    final trimmed = result?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> _handleUploadSelection({
    required bool requiresUploadContext,
  }) async {
    final uploadContext = requiresUploadContext ? await _showUploadContextDialog() : null;
    if (requiresUploadContext && uploadContext == null) {
      return;
    }

    // Capture the course name up front so it overrides whatever the OCR reads
    // off the scorecard. Cancelling here aborts the whole upload.
    final courseName = await _promptForCourseName();
    if (courseName == null || !mounted) {
      return;
    }

    // Lock to portrait for the entire camera + confirm flow.
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Camera -> confirm loop: "Retake" reopens the camera.
    Uint8List? imageBytes;
    while (true) {
      final captured = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const ScorecardCameraScreen(),
        ),
      );

      if (captured == null || !mounted) {
        await SystemChrome.setPreferredOrientations([]);
        return;
      }

      imageBytes = captured;

      final didConfirmUpload = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Confirm scorecard photo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (uploadContext != null) ...[
                  Text(
                    'Tournament: ${uploadContext.tournament.name}',
                  ),
                  Text('Round: ${uploadContext.roundLabel}'),
                  const SizedBox(height: 12),
                ],
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: Image.memory(imageBytes!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Retake'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Use Photo'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        await SystemChrome.setPreferredOrientations([]);
        return;
      }

      if (didConfirmUpload == true) break; // Confirmed — proceed to OCR.
      if (didConfirmUpload == null) {
        await SystemChrome.setPreferredOrientations([]);
        return; // Dismissed — cancel entirely.
      }
      // didConfirmUpload == false → "Retake" — loop back to camera.
    }

    // Restore orientations now that the flow is confirmed.
    await SystemChrome.setPreferredOrientations([]);

    if (_isUploadingTestImage) {
      return;
    }

    setState(() {
      _isUploadingTestImage = true;
    });
    _startUploadProgress();

    try {
      final fileName =
          'scorecard_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final scorecard = await _ocrService.fetchScorecardResults(
        imageBytes,
        fileName,
      );

      if (!mounted) {
        return;
      }

      await _completeUploadProgress();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              uploadContext == null
                  ? 'Scorecard image confirmed. Review results before saving.'
                  : 'Image confirmed for ${uploadContext.tournament.name} (${uploadContext.roundLabel}). Review results before saving.',
            ),
          ),
        );

      _showOcrResults(
        scorecard,
        uploadContext: uploadContext,
        imageBytes: imageBytes,
        courseNameOverride: courseName,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Upload failed: $error')),
        );
    } finally {
      if (mounted) {
        _resetUploadProgress();
        setState(() {
          _isUploadingTestImage = false;
        });
      }
    }
  }

  Future<_UploadSelectionContext?> _showUploadContextDialog() {
    final gmUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final tournamentsStream = gmUserId.trim().isEmpty
        ? Stream.value(const <Tournament>[])
        : _tournamentService.streamGmTournaments(gmUserId);
    Tournament? selectedTournament;
    int? selectedRound;

    return showDialog<_UploadSelectionContext>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return StreamBuilder<List<Tournament>>(
              stream: tournamentsStream,
              builder: (context, tournamentSnapshot) {
                final tournaments = tournamentSnapshot.data ?? const <Tournament>[];

                if (selectedTournament != null) {
                  final matchingIndex = tournaments.indexWhere(
                    (tournament) =>
                        tournament.tournamentId == selectedTournament!.tournamentId,
                  );

                  if (matchingIndex == -1) {
                    selectedTournament = null;
                  } else {
                    selectedTournament = tournaments[matchingIndex];
                  }
                }

                return AlertDialog(
                  title: const Text('Select scorecard upload details'),
                  content: SizedBox(
                    width: 480,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Before uploading, choose the tournament and round.',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Tournament>(
                          decoration: const InputDecoration(
                            labelText: 'Tournament',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedTournament,
                          isExpanded: true,
                          items: tournaments
                              .map(
                                (tournament) => DropdownMenuItem<Tournament>(
                                  value: tournament,
                                  child: Text(tournament.name, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: tournaments.isEmpty
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedTournament = value;
                                    selectedRound = null;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Round',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedRound,
                          items: List.generate(
                            4,
                            (index) => index + 1,
                          )
                              .map(
                                (round) => DropdownMenuItem<int>(
                                  value: round,
                                  child: Text('Round $round'),
                                ),
                              )
                              .toList(),
                          onChanged: selectedTournament == null
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedRound = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: selectedTournament != null &&
                              selectedRound != null
                          ? () => Navigator.of(dialogContext).pop(
                                _UploadSelectionContext(
                                  tournament: selectedTournament!,
                                  round: selectedRound!,
                                ),
                              )
                          : null,
                      child: const Text('Continue'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MenuCard(
          label: 'Upload',
          subtitle: widget.subtitle,
          backgroundColor: widget.menuBackgroundColor,
          borderColor: widget.menuBorderColor,
          titleColor: widget.menuTitleColor,
          subtitleColor: widget.menuSubtitleColor,
          icon: widget.menuIcon,
          borderRadius: widget.menuBorderRadius,
          minHeight: widget.menuMinHeight,
          padding: widget.menuPadding,
          titleFontSize: widget.menuTitleFontSize,
          onTap: _isUploadingTestImage
              ? null
              : () => _handleUploadSelection(
                    requiresUploadContext: widget.requiresUploadContext,
                  ),
        ),
        if (_isUploadingTestImage) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  '${(_uploadProgress * 100).round()}%',
                  style: TextStyle(
                    color: widget.menuTitleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: widget.menuBorderColor,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.menuTitleColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _UploadSelectionContext {
  const _UploadSelectionContext({
    required this.tournament,
    required this.round,
  });

  final Tournament tournament;
  final int round;

  String get roundLabel => 'Round $round';
}

class OcrScorecardView extends StatefulWidget {
  final OcrScorecardResponse scorecard;
  final _UploadSelectionContext? uploadContext;
  final Uint8List imageBytes;

  /// Course name entered by the PRO before capturing the photo. When provided,
  /// it takes precedence over the course name read from the OCR data.
  final String? courseNameOverride;

  const OcrScorecardView({
    super.key,
    required this.scorecard,
    required this.imageBytes,
    this.uploadContext,
    this.courseNameOverride,
  });

  @override
  State<OcrScorecardView> createState() => _OcrScorecardViewState();
}

class _OcrScorecardViewState extends State<OcrScorecardView> {
  final Map<_EditedHoleKey, int?> _editedScores = {};
  final Map<int, int?> _editedPars = {};
  final ProScoreUploadService _proScoreUploadService = ProScoreUploadService();
  final RegistrationService _registrationService = RegistrationService();
  String? _selectedMeProName;
  final Map<String, String?> _selectedRegistrationIdsByPro = {};
  List<TournamentRegistration> _availableRoundRegistrations = const [];
  bool _isLoadingGmRegistrations = false;
  late String _courseName;

  @override
  void initState() {
    super.initState();
    final override = widget.courseNameOverride?.trim();
    _courseName = (override != null && override.isNotEmpty)
        ? override
        : widget.scorecard.courseName;
    _loadGmRegistrationsIfNeeded();
  }


  Future<void> _loadGmRegistrationsIfNeeded() async {
    final uploadContext = widget.uploadContext;
    if (uploadContext == null) {
      return;
    }

    setState(() {
      _isLoadingGmRegistrations = true;
    });

    try {
      final registrations = await _registrationService.fetchRegistrants(uploadContext.tournament.tournamentId);
      final uploadedRegistrationIds = await _proScoreUploadService.getUploadedRegistrationIdsForRound(
        tournamentId: uploadContext.tournament.tournamentId,
        round: uploadContext.round,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _availableRoundRegistrations = registrations
            .where((registration) =>
                registration.status == RegistrationStatus.registered &&
                !uploadedRegistrationIds.contains(registration.registrationId))
            .toList();
        _isLoadingGmRegistrations = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _availableRoundRegistrations = const [];
        _isLoadingGmRegistrations = false;
      });
    }
  }

  TournamentRegistration? _assignedRegistrationForPro(String proName) {
    final assignedId = _selectedRegistrationIdsByPro[proName];
    if (assignedId == null) {
      return null;
    }
    for (final registration in _availableRoundRegistrations) {
      if (registration.registrationId == assignedId) {
        return registration;
      }
    }
    return null;
  }

  List<TournamentRegistration> _dropdownOptionsForPro(String proName) {
    final usedRegistrationIds = _selectedRegistrationIdsByPro.entries
        .where((entry) => entry.key != proName)
        .map((entry) => entry.value)
        .whereType<String>()
        .toSet();
    final assignedRegistration = _assignedRegistrationForPro(proName);

    return _availableRoundRegistrations.where((registration) {
      if (assignedRegistration?.registrationId == registration.registrationId) {
        return true;
      }
      return !usedRegistrationIds.contains(registration.registrationId);
    }).toList();
  }

  void _assignRegistrationToPro({
    required String proName,
    required String? registrationId,
  }) {
    setState(() {
      if (registrationId == null) {
        _selectedRegistrationIdsByPro.remove(proName);
      } else {
        _selectedRegistrationIdsByPro[proName] = registrationId;
      }
    });
  }

  int? _scoreForProHole(OcrProScore pro, int hole) {
    return _editedScores[_EditedHoleKey(proName: pro.name, hole: hole)] ??
        pro.holes[hole]?.score;
  }

  int? _parForHole(int hole) {
    return _editedPars[hole] ?? widget.scorecard.parByHole[hole];
  }

  Map<int, int?> get _currentParByHole => {
    for (var hole = 1; hole <= 18; hole++) hole: _parForHole(hole),
  };

  void _toggleMePro(String proName) {
    setState(() {
      _selectedMeProName = _selectedMeProName == proName ? null : proName;
    });
  }

  Future<String?> _uploadScorecardImage() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final ref = FirebaseStorage.instance
          .ref()
          .child('scorecards/$userId/$timestamp.jpeg');
      await ref.putData(
        widget.imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<bool> confirmSelectedPro() async {
    final uploadContext = widget.uploadContext;
    final scorecardImageUrl = await _uploadScorecardImage();

    if (uploadContext != null) {
      if (_isLoadingGmRegistrations) {
        if (!mounted) {
          return false;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Loading available PROs. Please wait and try again.')),
          );
        return false;
      }

      final selectedAssignments = <String, TournamentRegistration>{
        for (final pro in widget.scorecard.pros)
          if (_assignedRegistrationForPro(pro.name) != null)
            pro.name: _assignedRegistrationForPro(pro.name)!,
      };

      if (selectedAssignments.isEmpty) {
        if (!mounted) {
          return false;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Assign at least one registered PRO before confirming.')),
          );
        return false;
      }

      try {
        for (final entry in selectedAssignments.entries) {
          final selectedPro = widget.scorecard.pros.firstWhere(
            (pro) => pro.name == entry.key,
            orElse: () => throw StateError('Selected PRO not found in scorecard.'),
          );
          final registration = entry.value;
          final scoresByHole = <int, int?>{
            for (var hole = 1; hole <= 18; hole++) hole: _scoreForProHole(selectedPro, hole),
          };

          await _proScoreUploadService.uploadRegistrationScore(
            tournamentId: uploadContext.tournament.tournamentId,
            round: uploadContext.round,
            registrationId: registration.registrationId,
            registrationUserId: registration.userId,
            registrationProName: registration.proName,
            detectedProName: selectedPro.name,
            scoresByHole: scoresByHole,
            parByHole: _currentParByHole,
            handicapByHole: widget.scorecard.handicapByHole,
            courseName: _courseName,
            scorecardImageUrl: scorecardImageUrl,
          );
        }

        if (!mounted) {
          return false;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Saved ${selectedAssignments.length} ${selectedAssignments.length == 1 ? 'PRO' : 'PROs'} for ${uploadContext.tournament.name} ${uploadContext.roundLabel}.',
              ),
            ),
          );
        return true;
      } catch (error) {
        if (!mounted) {
          return false;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Could not save score(s): $error')),
          );
        return false;
      }
    }

    final selectedProName = _selectedMeProName;
    if (selectedProName == null) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Select the PRO marked as Me before confirming.')),
        );
      return false;
    }

    final selectedPro = widget.scorecard.pros.firstWhere(
      (pro) => pro.name == selectedProName,
      orElse: () => throw StateError('Selected PRO not found in scorecard.'),
    );

    final scoresByHole = <int, int?>{
      for (var hole = 1; hole <= 18; hole++) hole: _scoreForProHole(selectedPro, hole),
    };

    try {
      await _proScoreUploadService.uploadMeScore(
        proName: selectedPro.name,
        scoresByHole: scoresByHole,
        parsByHole: _currentParByHole,
        handicapByHole: widget.scorecard.handicapByHole,
        courseName: _courseName,
        scorecardImageUrl: scorecardImageUrl,
      );
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Saved ${selectedPro.name} score to your profile.')),
        );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not save score: $error')),
        );
      return false;
    }
  }

  void showSkinsCalculator() {
    final proScores = <String, Map<int, int?>>{};
    for (final pro in widget.scorecard.pros) {
      proScores[pro.name] = {
        for (var hole = 1; hole <= 18; hole++)
          hole: _scoreForProHole(pro, hole),
      };
    }
    showDialog<void>(
      context: context,
      builder: (_) => SkinsDialog(
        pros: widget.scorecard.pros,
        proScores: proScores,
        handicapByHole: widget.scorecard.handicapByHole,
      ),
    );
  }

  Future<void> _editScore({
    required BuildContext context,
    required OcrProScore pro,
    required int hole,
  }) async {
    final currentScore = _scoreForProHole(pro, hole);
    final controller = TextEditingController(text: currentScore?.toString() ?? '');
    final updatedScore = await showDialog<int?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit ${pro.name} - Hole $hole'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Score',
              hintText: 'Enter strokes',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                Navigator.of(dialogContext).pop(parsed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || updatedScore == currentScore) {
      return;
    }

    setState(() {
      _editedScores[_EditedHoleKey(proName: pro.name, hole: hole)] = updatedScore;
    });
  }

  Future<void> _editPar({
    required BuildContext context,
    required int hole,
  }) async {
    final currentPar = _parForHole(hole);
    final controller = TextEditingController(text: currentPar?.toString() ?? '');
    final updatedPar = await showDialog<int?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit Par - Hole $hole'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Par',
              hintText: 'Enter par (3, 4, or 5)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                Navigator.of(dialogContext).pop(parsed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || updatedPar == currentPar) {
      return;
    }

    setState(() {
      _editedPars[hole] = updatedPar;
    });
  }

  Future<void> _editCourseName() async {
    final controller = TextEditingController(text: _courseName);
    final updatedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update course name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Course name',
              hintText: 'Enter course name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || updatedName == null || updatedName.isEmpty || updatedName == _courseName) {
      return;
    }

    setState(() {
      _courseName = updatedName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071937),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Rounds',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD7E4F7),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF05162F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2D7C2F), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'COURSE',
                        style: TextStyle(
                          color: Color(0xFF72D981),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _editCourseName,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        foregroundColor: const Color(0xFF58C2FF),
                        side: const BorderSide(color: Color(0xFF2A78B8)),
                        backgroundColor: const Color(0xFF12325A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _courseName.toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFD7E4F7),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _OcrMetadataBanner(
            confidence: widget.scorecard.confidence,
            cardType: widget.scorecard.cardType,
            flaggedHoles: widget.scorecard.flaggedHoles,
            issues: widget.scorecard.issues,
          ),
          const SizedBox(height: 14),
          _ScorecardTable(
            scorecard: widget.scorecard,
            parByHole: _currentParByHole,
            scoreForProHole: _scoreForProHole,
            selectedMeProName: _selectedMeProName,
            onMeProToggled: _toggleMePro,
            uploadContext: widget.uploadContext,
            isLoadingGmRegistrations: _isLoadingGmRegistrations,
            dropdownOptionsForPro: _dropdownOptionsForPro,
            assignedRegistrationForPro: _assignedRegistrationForPro,
            onRegistrationAssigned: _assignRegistrationToPro,
            onScoreTap: (pro, hole) => _editScore(
              context: context,
              pro: pro,
              hole: hole,
            ),
            onParTap: (hole) => _editPar(
              context: context,
              hole: hole,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditedHoleKey {
  final String proName;
  final int hole;

  const _EditedHoleKey({required this.proName, required this.hole});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _EditedHoleKey && other.proName == proName && other.hole == hole;
  }

  @override
  int get hashCode => Object.hash(proName, hole);
}

class _ScorecardTable extends StatelessWidget {
  final OcrScorecardResponse scorecard;
  final Map<int, int?> parByHole;
  final int? Function(OcrProScore pro, int hole) scoreForProHole;
  final String? selectedMeProName;
  final ValueChanged<String> onMeProToggled;
  final Future<void> Function(OcrProScore pro, int hole) onScoreTap;
  final Future<void> Function(int hole) onParTap;
  final _UploadSelectionContext? uploadContext;
  final bool isLoadingGmRegistrations;
  final List<TournamentRegistration> Function(String proName) dropdownOptionsForPro;
  final TournamentRegistration? Function(String proName) assignedRegistrationForPro;
  final void Function({required String proName, required String? registrationId}) onRegistrationAssigned;

  const _ScorecardTable({
    required this.scorecard,
    required this.parByHole,
    required this.scoreForProHole,
    required this.selectedMeProName,
    required this.onMeProToggled,
    required this.onScoreTap,
    required this.onParTap,
    required this.uploadContext,
    required this.isLoadingGmRegistrations,
    required this.dropdownOptionsForPro,
    required this.assignedRegistrationForPro,
    required this.onRegistrationAssigned,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < scorecard.pros.length; index++) ...[
          _ProScorecardCard(
            pro: scorecard.pros[index],
            parByHole: parByHole,
            scoreForProHole: scoreForProHole,
            selectedMeProName: selectedMeProName,
            onMeProToggled: onMeProToggled,
            onScoreTap: onScoreTap,
            onParTap: onParTap,
            uploadContext: uploadContext,
            isLoadingGmRegistrations: isLoadingGmRegistrations,
            registrationOptions: dropdownOptionsForPro(scorecard.pros[index].name),
            assignedRegistration: assignedRegistrationForPro(scorecard.pros[index].name),
            onRegistrationAssigned: (registrationId) => onRegistrationAssigned(
              proName: scorecard.pros[index].name,
              registrationId: registrationId,
            ),
          ),
          if (index < scorecard.pros.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  static Widget _holeScoreContent({
    required OcrHoleScore? hole,
    required int? displayScore,
  }) {
    if (displayScore == null) {
      return const Text('-', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6E8CAE)));
    }

    if (hole?.isLowConfidence != true) {
      return Text(
        '$displayScore',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFD6E1F1), fontWeight: FontWeight.w700),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$displayScore',
          style: const TextStyle(
            color: Color(0xFFFFCF66),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.warning_amber_rounded,
          size: 14,
          color: Color(0xFFFFCF66),
        ),
      ],
    );
  }

  static Widget _holeCell({
    required OcrProScore pro,
    required int holeNumber,
    required OcrHoleScore? holeScore,
    required int? displayScore,
    required Future<void> Function(OcrProScore pro, int hole) onScoreTap,
  }) {
    return _VerticalTableCell(
      color: holeScore?.isLowConfidence == true
          ? const Color(0xFF4B3612)
          : const Color(0xFF102447),
      child: InkWell(
        onTap: () => onScoreTap(pro, holeNumber),
        child: _holeScoreContent(hole: holeScore, displayScore: displayScore),
      ),
    );
  }

  static String _sumProScores(
    OcrProScore pro,
    int start,
    int end,
    int? Function(OcrProScore pro, int hole) scoreForProHole,
  ) {
    var hasValue = false;
    var total = 0;
    for (var hole = start; hole <= end; hole++) {
      final value = scoreForProHole(pro, hole);
      if (value != null) {
        hasValue = true;
        total += value;
      }
    }
    return hasValue ? '$total' : '-';
  }

  static String _display(int? value) => value?.toString() ?? '-';

  static String _sum(Map<int, int?> values, int start, int end) {
    var hasValue = false;
    var total = 0;
    for (var hole = start; hole <= end; hole++) {
      final value = values[hole];
      if (value != null) {
        hasValue = true;
        total += value;
      }
    }
    return hasValue ? '$total' : '-';
  }
}

class _ProScorecardCard extends StatelessWidget {
  const _ProScorecardCard({
    required this.pro,
    required this.parByHole,
    required this.scoreForProHole,
    required this.selectedMeProName,
    required this.onMeProToggled,
    required this.onScoreTap,
    required this.onParTap,
    required this.uploadContext,
    required this.isLoadingGmRegistrations,
    required this.registrationOptions,
    required this.assignedRegistration,
    required this.onRegistrationAssigned,
  });

  final OcrProScore pro;
  final Map<int, int?> parByHole;
  final int? Function(OcrProScore pro, int hole) scoreForProHole;
  final String? selectedMeProName;
  final ValueChanged<String> onMeProToggled;
  final Future<void> Function(OcrProScore pro, int hole) onScoreTap;
  final Future<void> Function(int hole) onParTap;
  final _UploadSelectionContext? uploadContext;
  final bool isLoadingGmRegistrations;
  final List<TournamentRegistration> registrationOptions;
  final TournamentRegistration? assignedRegistration;
  final ValueChanged<String?> onRegistrationAssigned;

  @override
  Widget build(BuildContext context) {
    final isMePro = selectedMeProName == pro.name;
    final isGmUpload = uploadContext != null;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF061A36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F4C7B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isGmUpload) ...[
            Text(
              '${pro.name}:',
              style: const TextStyle(
                color: Color(0xFF57C9FF),
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: assignedRegistration?.registrationId,
              decoration: InputDecoration(
                isDense: true,
                labelText: isLoadingGmRegistrations ? 'Loading...' : 'Assign PRO',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: const Color(0xFF112B4E),
              ),
              dropdownColor: const Color(0xFF112B4E),
              style: const TextStyle(color: Color(0xFFD7E4F7), fontWeight: FontWeight.w700),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Unassigned'),
                ),
                ...registrationOptions.map(
                  (registration) => DropdownMenuItem<String>(
                    value: registration.registrationId,
                    child: Text(
                      registration.proName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: isLoadingGmRegistrations ? null : onRegistrationAssigned,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${pro.name}:',
                    style: const TextStyle(
                      color: Color(0xFF57C9FF),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                FilterChip(
                  label: Text(
                    isMePro ? '✓ ME' : 'Me?',
                    style: TextStyle(
                      color: isMePro ? const Color(0xFF8CEB8C) : const Color(0xFF89A2C0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  selected: isMePro,
                  onSelected: (_) => onMeProToggled(pro.name),
                  visualDensity: VisualDensity.compact,
                  selectedColor: const Color(0xFF1A5F1D),
                  backgroundColor: const Color(0xFF112B4E),
                  side: BorderSide(
                    color: isMePro ? const Color(0xFF38A93B) : const Color(0xFF42678F),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _NineHoleTable(
                  sectionLabel: 'Front 9',
                  pro: pro,
                  parByHole: parByHole,
                  startHole: 1,
                  endHole: 9,
                  scoreForProHole: scoreForProHole,
                  onScoreTap: onScoreTap,
                  onParTap: onParTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NineHoleTable(
                  sectionLabel: 'Back 9',
                  pro: pro,
                  parByHole: parByHole,
                  startHole: 10,
                  endHole: 18,
                  scoreForProHole: scoreForProHole,
                  onScoreTap: onScoreTap,
                  onParTap: onParTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ${_ScorecardTable._sumProScores(pro, 1, 18, scoreForProHole)}',
              style: const TextStyle(
                color: Color(0xFF67CC70),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OcrMetadataBanner extends StatelessWidget {
  final String confidence;
  final String cardType;
  final List<OcrFlaggedHole> flaggedHoles;
  final List<String> issues;

  const _OcrMetadataBanner({
    required this.confidence,
    required this.cardType,
    required this.flaggedHoles,
    required this.issues,
  });

  @override
  Widget build(BuildContext context) {
    final confidenceUpper = confidence.toUpperCase();
    final Color confidenceColor;
    final IconData confidenceIcon;
    switch (confidenceUpper) {
      case 'HIGH':
        confidenceColor = const Color(0xFF67CC70);
        confidenceIcon = Icons.check_circle_outline;
      case 'MEDIUM':
        confidenceColor = const Color(0xFFFFCF66);
        confidenceIcon = Icons.info_outline;
      default:
        confidenceColor = const Color(0xFFFF6B6B);
        confidenceIcon = Icons.warning_amber_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _MetadataChip(
              icon: confidenceIcon,
              iconColor: confidenceColor,
              label: 'Confidence: $confidenceUpper',
              labelColor: confidenceColor,
            ),
            if (cardType != 'UNKNOWN')
              _MetadataChip(
                icon: Icons.style_outlined,
                iconColor: const Color(0xFF8FAECC),
                label: cardType.replaceAll('_', ' '),
                labelColor: const Color(0xFFD7E4F7),
              ),
          ],
        ),
        if (flaggedHoles.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A1A0A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF8B4513)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag_rounded, size: 16, color: Color(0xFFFF6B6B)),
                    SizedBox(width: 6),
                    Text(
                      'Flagged Scores',
                      style: TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final flag in flaggedHoles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${flag.pro} hole ${flag.hole}: ${flag.score ?? "?"} — ${flag.reason}',
                      style: const TextStyle(
                        color: Color(0xFFFFAA88),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (issues.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A3A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2B578A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFFFFCF66)),
                    SizedBox(width: 6),
                    Text(
                      'OCR Notes',
                      style: TextStyle(
                        color: Color(0xFFFFCF66),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final issue in issues)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      issue,
                      style: const TextStyle(
                        color: Color(0xFFB0C4DE),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;

  const _MetadataChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2A52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1F4C7B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NineHoleTable extends StatelessWidget {
  const _NineHoleTable({
    required this.sectionLabel,
    required this.pro,
    required this.parByHole,
    required this.startHole,
    required this.endHole,
    required this.scoreForProHole,
    required this.onScoreTap,
    required this.onParTap,
  });

  final String sectionLabel;
  final OcrProScore pro;
  final Map<int, int?> parByHole;
  final int startHole;
  final int endHole;
  final int? Function(OcrProScore pro, int hole) scoreForProHole;
  final Future<void> Function(OcrProScore pro, int hole) onScoreTap;
  final Future<void> Function(int hole) onParTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$sectionLabel:',
          style: const TextStyle(
            color: Color(0xFFD7E4F7),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFF2B578A), width: 1),
            verticalInside: BorderSide(color: Color(0xFF2B578A), width: 1),
            top: BorderSide(color: Color(0xFF2D5A91), width: 1.2),
            left: BorderSide(color: Color(0xFF2D5A91), width: 1.2),
            right: BorderSide(color: Color(0xFF2D5A91), width: 1.2),
            bottom: BorderSide(color: Color(0xFF2D5A91), width: 1.2),
          ),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFF081A35)),
              children: [
                _VerticalTableCell(
                  child: Text(
                    '#',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF8FAECC),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _VerticalTableCell(
                  child: Text(
                    'Par',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFCC2D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _VerticalTableCell(
                  child: Text(
                    'Net',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF57C9FF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            for (var hole = startHole; hole <= endHole; hole++)
              TableRow(
                children: [
                  _VerticalTableCell(
                    color: const Color(0xFF0E2A52),
                    child: Text(
                      '$hole',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD6E1F1),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _VerticalTableCell(
                    color: const Color(0xFF0A1D3C),
                    child: InkWell(
                      onTap: () => onParTap(hole),
                      child: Text(
                        _ScorecardTable._display(parByHole[hole]),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFCC2D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  _ScorecardTable._holeCell(
                    pro: pro,
                    holeNumber: hole,
                    holeScore: pro.holes[hole],
                    displayScore: scoreForProHole(pro, hole),
                    onScoreTap: onScoreTap,
                  ),
                ],
              ),
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF0D2A1A)),
              children: [
                _VerticalTableCell(
                  child: Text(
                    sectionLabel == 'Front 9' ? 'OUT' : 'IN',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF67CC70),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _VerticalTableCell(
                  child: Text(
                    _ScorecardTable._sum(parByHole, startHole, endHole),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFCC2D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _VerticalTableCell(
                  child: Text(
                    _ScorecardTable._sumProScores(
                      pro,
                      startHole,
                      endHole,
                      scoreForProHole,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF67CC70),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _VerticalTableCell extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _VerticalTableCell({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? const Color(0xFF102447),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      alignment: Alignment.center,
      child: child,
    );
  }
}
