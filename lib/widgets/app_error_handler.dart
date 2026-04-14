// widgets/app_error_handler.dart
// Centralized error display utility used across all screens.

import 'package:flutter/material.dart';

class AppErrorHandler {
  AppErrorHandler._();

  /// Show a modal dialog for non-recoverable errors.
  static Future<void> showError(BuildContext context, String message,
      {String title = 'Error'}) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a non-blocking snackbar for recoverable warnings.
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a success snackbar.
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Safely execute an async operation and display any error.
  static Future<void> runSafe(
    BuildContext context,
    Future<void> Function() action, {
    String errorTitle = 'Error',
  }) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        await showError(context, e.toString(), title: errorTitle);
      }
    }
  }
}
