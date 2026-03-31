import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScorecardCameraScreen extends StatefulWidget {
  const ScorecardCameraScreen({super.key});

  @override
  State<ScorecardCameraScreen> createState() => _ScorecardCameraScreenState();
}

class _ScorecardCameraScreenState extends State<ScorecardCameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No cameras available');
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Camera error: $e');
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final xFile = await _controller!.takePicture();
      final bytes = await xFile.readAsBytes();
      if (mounted) {
        Navigator.of(context).pop(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview.
          if (_isInitialized && _controller != null)
            Center(child: CameraPreview(_controller!))
          else if (_error != null)
            Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Corner guide overlay.
          if (_isInitialized)
            const _ScorecardGuideOverlay(),

          // Instruction text.
          if (_isInitialized)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: const Text(
                'Align scorecard within the guides',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black),
                  ],
                ),
              ),
            ),

          // Bottom controls.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                top: 24,
              ),
              color: Colors.black54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button.
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  ),
                  // Shutter button.
                  GestureDetector(
                    onTap: _isInitialized ? _capturePhoto : null,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Spacer to balance the row.
                  const SizedBox(width: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorecardGuideOverlay extends StatelessWidget {
  const _ScorecardGuideOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Landscape-oriented rectangle: wider than tall.
        final guideWidth = constraints.maxWidth * 0.90;
        final guideHeight = guideWidth * 0.55;

        final left = (constraints.maxWidth - guideWidth) / 2;
        final top = (constraints.maxHeight - guideHeight) / 2 - 30;

        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _CornerGuidePainter(
            rect: Rect.fromLTWH(left, top, guideWidth, guideHeight),
          ),
        );
      },
    );
  }
}

class _CornerGuidePainter extends CustomPainter {
  _CornerGuidePainter({required this.rect});

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Top-left corner.
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.top + cornerLength),
      paint,
    );

    // Top-right corner.
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right - cornerLength, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      paint,
    );

    // Bottom-left corner.
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left, rect.bottom - cornerLength),
      paint,
    );

    // Bottom-right corner.
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right - cornerLength, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      paint,
    );

    // Dim area outside the guide rectangle.
    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(fullRect),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8))),
      ),
      dimPaint,
    );
  }

  @override
  bool shouldRepaint(_CornerGuidePainter oldDelegate) => rect != oldDelegate.rect;
}
