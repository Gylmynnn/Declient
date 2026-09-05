import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'app_colors.dart';

/// Snackbar terpusat dengan accent Everblush yang jelas.
///
/// Semua snackbar memakai background gelap yang sama, border + ikon + judul
/// berwarna sesuai jenis pesan sehingga status langsung terbaca:
/// - success -> hijau, error -> merah, info -> biru, warning -> kuning.
class AppSnack {
  AppSnack._();

  static void _show({
    required String title,
    required String message,
    required Color accent,
    required IconData icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      maxWidth: 460,
      backgroundColor: _tinted(AppColors.backgroundDark, accent, 0.12),
      borderColor: accent,
      borderWidth: 1.2,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: accent.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 0),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: accent, size: 18),
      ),
      shouldIconPulse: false,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      titleText: Text(
        title,
        style: TextStyle(
          color: accent,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: AppColors.foreground,
          fontSize: 12.5,
        ),
      ),
      snackStyle: SnackStyle.FLOATING,
    );
  }

  static Color _tinted(Color base, Color accent, double t) {
    return Color.lerp(base, accent, t) ?? base;
  }

  static void success(String message,
      {String title = 'Sukses', Duration duration = const Duration(seconds: 2)}) {
    _show(title: title, message: message, accent: AppColors.green, icon: LucideIcons.checkCircle2, duration: duration);
  }

  static void error(String message,
      {String title = 'Error', Duration duration = const Duration(seconds: 3)}) {
    _show(title: title, message: message, accent: AppColors.red, icon: LucideIcons.alertCircle, duration: duration);
  }

  static void info(String message,
      {String title = 'Info', Duration duration = const Duration(seconds: 2)}) {
    _show(title: title, message: message, accent: AppColors.blue, icon: LucideIcons.info, duration: duration);
  }

  static void warning(String message,
      {String title = 'Validasi', Duration duration = const Duration(seconds: 2)}) {
    _show(title: title, message: message, accent: AppColors.yellow, icon: LucideIcons.alertTriangle, duration: duration);
  }
}
