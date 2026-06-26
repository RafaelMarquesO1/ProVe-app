import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareImageService {
  static Future<void> showSharePreview({
    required BuildContext context,
    required Widget card,
    required String shareText,
  }) {
    final key = GlobalKey();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Compartilhar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: RepaintBoundary(
                  key: key,
                  child: card,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async => _captureAndShare(key, shareText),
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: const Text(
                    'Compartilhar Imagem',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _captureAndShare(
    GlobalKey key,
    String text,
  ) async {
    try {
      final boundary = key.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/prove_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      debugPrint('[ShareImageService] Erro ao compartilhar: $e');
    }
  }
}
