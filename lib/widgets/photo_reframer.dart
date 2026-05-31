import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myapp/widgets/bounce_button.dart';

class PhotoReframer extends StatefulWidget {
  final File imageFile;

  const PhotoReframer({super.key, required this.imageFile});

  static Future<File?> reframe({
    required BuildContext context,
    required File imageFile,
  }) {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoReframer(imageFile: imageFile),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<PhotoReframer> createState() => _PhotoReframerState();
}

class _PhotoReframerState extends State<PhotoReframer> {
  final GlobalKey _boundaryKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  double _zoomScale = 1.0;
  bool _isProcessing = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    // Sync slider value with InteractiveViewer scale
    final Matrix4 matrix = _transformationController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    setState(() {
      _zoomScale = scale.clamp(1.0, 4.0);
    });
  }

  void _updateZoom(double value) {
    setState(() {
      _zoomScale = value;
    });
    // Reconstruct matrix keeping current translation but changing scale
    final Matrix4 matrix = _transformationController.value;
    final double currentScale = matrix.getMaxScaleOnAxis();
    if (currentScale != 0) {
      final double ratio = value / currentScale;
      matrix.scale(ratio, ratio);
      _transformationController.value = matrix;
    }
  }

  Future<void> _confirmCrop() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Small delay to ensure render tree is stabilized
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final RenderRepaintBoundary? boundary =
          _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        throw Exception("RenderRepaintBoundary not found");
      }

      // Capture image with high density for sharp avatars
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception("Could not convert image to bytes");
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png';
      
      final File croppedFile = File(filePath);
      await croppedFile.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.pop(context, croppedFile);
      }
    } catch (e) {
      debugPrint("Erro ao reenquadrar foto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Não foi possível reenquadrar a foto. Tente novamente."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const double cropSize = 250.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Text(
          'Reenquadrar Foto',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Render target wrapped in RepaintBoundary
                RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(
                    width: cropSize,
                    height: cropSize,
                    color: Colors.black,
                    child: ClipOval(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: InteractiveViewer(
                              transformationController: _transformationController,
                              minScale: 1.0,
                              maxScale: 4.0,
                              boundaryMargin: EdgeInsets.zero,
                              onInteractionUpdate: (_) => _onTransformationChanged(),
                              child: Image.file(
                                widget.imageFile,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Dimmed Overlay masking outside the crop circle
                IgnorePointer(
                  child: Stack(
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.75),
                          BlendMode.srcOut,
                        ),
                        child: Stack(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                backgroundBlendMode: BlendMode.dstOut,
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                width: cropSize,
                                height: cropSize,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Circle Outline
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: cropSize,
                          height: cropSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF121212)
                  : Colors.grey.shade900,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom slider
                  Row(
                    children: [
                      const Icon(Icons.zoom_out_rounded, color: Colors.white70),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: colorScheme.primary,
                            overlayColor: colorScheme.primary.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _zoomScale,
                            min: 1.0,
                            max: 4.0,
                            onChanged: _updateZoom,
                          ),
                        ),
                      ),
                      const Icon(Icons.zoom_in_rounded, color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arraste e aproxime a foto para ajustar',
                    style: GoogleFonts.lato(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Actions buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, null),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BounceButton(
                          onTap: _confirmCrop,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  const Color(0xFFD65108),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: _isProcessing
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Confirmar',
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
