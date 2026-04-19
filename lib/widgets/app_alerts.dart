import 'package:flutter/material.dart';

enum AppAlertType { success, error, warning, info }

class AppAlerts {
  static void showSnackBar(
    BuildContext context, {
    required String message,
    AppAlertType type = AppAlertType.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final (Color bg, IconData icon) = switch (type) {
      AppAlertType.success => (const Color(0xFF2E7D32), Icons.check_circle_rounded),
      AppAlertType.error => (const Color(0xFFC62828), Icons.error_rounded),
      AppAlertType.warning => (const Color(0xFFEF6C00), Icons.warning_amber_rounded),
      AppAlertType.info => (const Color(0xFF455A64), Icons.info_rounded),
    };

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
