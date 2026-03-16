import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/footer_link.dart';
import '../widgets/menu_card.dart';
import 'player_home_page.dart';
import 'tournament_results_page.dart';

class SignInHomePage extends StatefulWidget {
  const SignInHomePage({super.key});

  @override
  State<SignInHomePage> createState() => _SignInHomePageState();
}

class _SignInHomePageState extends State<SignInHomePage> {
  static const double _headerBarHeight = 64;

  void _showMenuSelection(BuildContext context, String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$value selected'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Route<void> _buildSlideFromLeftRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1, 0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  Future<void> _openUploadCameraFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _DirectorCameraFlowPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: _headerBarHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A2E44), Color(0xFF223F5E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: const Color(0xFF355C84)),
                      ),
                      child: const Text(
                        'WORLDSCORE AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    tooltip: 'Open menu',
                    onSelected: (value) => _showMenuSelection(context, value),
                    color: const Color(0xFF142234),
                    position: PopupMenuPosition.under,
                    offset: const Offset(0, 8),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'Account',
                        child: Text('Account', style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 'Who We Are',
                        child: Text('Who We Are', style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 'FAQ',
                        child: Text('FAQ', style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 'Settings',
                        child: Text('Settings', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    child: Container(
                      height: _headerBarHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF294B6D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: const Icon(Icons.menu, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome back, Director',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFB8C7D6),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _DirectorOverviewCard(),
                      const SizedBox(height: 20),
                      MenuCard(
                        label: 'Leaderboard',
                        subtitle: 'View current and former tournament leaderboards.',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TournamentResultsPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      const MenuCard(
                        label: 'Round History',
                        subtitle: 'Review uploaded scorecards and round history.',
                      ),
                      const SizedBox(height: 14),
                      MenuCard(
                        label: 'Upload',
                        subtitle: 'Scan and upload scorecards as players finish each day.',
                        onTap: _openUploadCameraFlow,
                      ),
                      const SizedBox(height: 14),
                      const MenuCard(
                        label: 'Admin',
                        subtitle: 'Create, adjust and manage tournament paramaters.',
                      ),
                      const SizedBox(height: 16),
                      _ProfileSwitchCard(
                        selectedRole: 'Director',
                        onRoleChanged: (role) {
                          if (role == 'Player') {
                            Navigator.of(context).pushReplacement(
                              _buildSlideFromLeftRoute(const PlayerSignInHomePage()),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FooterLink(label: 'How It Works', onTap: () {}),
                          FooterLink(label: 'Help & Support', onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectorCameraFlowPage extends StatefulWidget {
  const _DirectorCameraFlowPage();

  @override
  State<_DirectorCameraFlowPage> createState() => _DirectorCameraFlowPageState();
}

class _DirectorCameraFlowPageState extends State<_DirectorCameraFlowPage> {
  final ImagePicker _picker = ImagePicker();

  XFile? _capturedImage;
  bool _isCapturing = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _capturePhoto();
    });
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || _isUploading) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (!mounted) {
        return;
      }

      setState(() {
        _capturedImage = image;
      });

      if (image == null) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Camera unavailable: $error')),
        );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _confirmAndUpload() async {
    final image = _capturedImage;
    if (image == null || _isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final path = 'director_uploads/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(path);

      await ref.putFile(File(image.path));
      await ref.getDownloadURL();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Scorecard uploaded successfully.')),
        );
      Navigator.of(context).pop();
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
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _capturedImage;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Close camera',
            onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: _isCapturing && image == null
            ? const CircularProgressIndicator()
            : image == null
                ? const Text(
                    'No photo captured.',
                    style: TextStyle(color: Colors.white),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(image.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isUploading ? null : _capturePhoto,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF4FC3F7)),
                                ),
                                child: const Text('Retake'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isUploading ? null : _confirmAndUpload,
                                child: _isUploading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Confirm'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _ProfileSwitchCard extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const _ProfileSwitchCard({
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF142234),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F3A56)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Switch Profile View',
            style: TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use this toggle if you have both player and director profiles.',
            style: TextStyle(
              color: Color(0xFF9FB3C8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: 'Player', label: Text('Player')),
              ButtonSegment<String>(value: 'Director', label: Text('Director')),
            ],
            selected: {selectedRole},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onRoleChanged(selection.first),
          ),
        ],
      ),
    );
  }
}

class _DirectorOverviewCard extends StatelessWidget {
  const _DirectorOverviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF142234),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F3A56)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Director Overview',
            style: TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          _DirectorInfoRow(label: 'Name', value: 'Dalton Stout'),
          SizedBox(height: 8),
          _DirectorInfoRow(label: 'Club', value: 'Club Campestre el Rodeo'),
          SizedBox(height: 8),
          _DirectorInfoRow(label: 'Association', value: 'Federación Colombiana de Golf'),
        ],
      ),
    );
  }
}

class _DirectorInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DirectorInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Color(0xFF9FB3C8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
