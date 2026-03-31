import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Guide rect proportions — shared between overlay and crop logic.
// Narrower width to match a typical scorecard with minimal side padding.
const double _guideWidthFraction = 0.62;
const double _guideHeightFraction = 0.70;
const double _guideVerticalOffset = -20;

class ScorecardCameraScreen extends StatefulWidget {
  const ScorecardCameraScreen({super.key});

  @override
  State<ScorecardCameraScreen> createState() => _ScorecardCameraScreenState();
}

class _ScorecardCameraScreenState extends State<ScorecardCameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
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
    if (_controller!.value.isTakingPicture || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final xFile = await _controller!.takePicture();
      final bytes = await xFile.readAsBytes();
      final cropped = await _cropToGuideRegion(bytes);
      if (mounted) {
        Navigator.of(context).pop(cropped);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture: $e')),
        );
      }
    }
  }

  Future<Uint8List> _cropToGuideRegion(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    final screen = MediaQuery.of(context).size;
    final cameraAR = _controller!.value.aspectRatio;

    // The preview fills the screen width; its height is determined by the
    // camera aspect ratio (portrait = 1 / cameraAR).
    final previewW = screen.width;
    final previewH = screen.width * cameraAR;
    final previewY = (screen.height - previewH) / 2;

    // Guide rect on screen (same maths as _ScorecardGuideOverlay).
    final guideW = screen.width * _guideWidthFraction;
    final guideH = screen.height * _guideHeightFraction;
    final guideX = (screen.width - guideW) / 2;
    final guideY = (screen.height - guideH) / 2 + _guideVerticalOffset;

    // Express guide rect as fractions of the preview area.
    final fX = (guideX / previewW).clamp(0.0, 1.0);
    final fY = ((guideY - previewY) / previewH).clamp(0.0, 1.0);
    final fW = (guideW / previewW).clamp(0.0, 1.0 - fX);
    final fH = (guideH / previewH).clamp(0.0, 1.0 - fY);

    // Map fractions to actual image pixels.
    final cropRect = Rect.fromLTWH(
      fX * imgW,
      fY * imgH,
      fW * imgW,
      fH * imgH,
    );

    // Draw the cropped region onto a new image.
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      cropRect,
      Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
      Paint(),
    );
    final croppedImage = await recorder
        .endRecording()
        .toImage(cropRect.width.round(), cropRect.height.round());
    final pngBytes =
        await croppedImage.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    croppedImage.dispose();

    return pngBytes!.buffer.asUint8List();
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

          // Dimmed overlay outside the guide area.
          if (_isInitialized)
            const _ScorecardGuideOverlay(),

          // Instruction text.
          if (_isInitialized)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: const Text(
                'Align scorecard within the frame',
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
                    onTap: _isInitialized && !_isCapturing ? _capturePhoto : null,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing ? Colors.grey : Colors.white,
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
        final guideWidth = constraints.maxWidth * _guideWidthFraction;
        final guideHeight = constraints.maxHeight * _guideHeightFraction;

        final left = (constraints.maxWidth - guideWidth) / 2;
        final top =
            (constraints.maxHeight - guideHeight) / 2 + _guideVerticalOffset;

        final guideRect = Rect.fromLTWH(left, top, guideWidth, guideHeight);

        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _DimmedOverlayPainter(guideRect: guideRect),
        );
      },
    );
  }
}

/// Paints a semi-transparent dark layer over the entire screen with a clear
/// cutout for the guide rectangle, so the scorecard area stays bright.
class _DimmedOverlayPainter extends CustomPainter {
  _DimmedOverlayPainter({required this.guideRect});

  final Rect guideRect;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);

    // Draw the dimmed region by subtracting the guide cutout.
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(
        RRect.fromRectAndRadius(guideRect, const Radius.circular(8)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, dimPaint);

    // Thin white border around the guide area.
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(guideRect, const Radius.circular(8)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_DimmedOverlayPainter oldDelegate) =>
      guideRect != oldDelegate.guideRect;
}
