import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppToast {
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
  }) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF2E7D32),
    );
  }

  static void showError(BuildContext context, String message, {String? title}) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFC62828),
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
  }) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.warning_amber_rounded,
      backgroundColor: const Color(0xFFE65100),
    );
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppColors.navyDark,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    String? title,
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12.5,
                      fontWeight: title != null
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
