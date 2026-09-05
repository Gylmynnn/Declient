import 'package:get/get.dart';
import '../../modules/settings/controllers/settings_controller.dart';

/// Font-family mono aktif untuk area kode (URL, body, response, snippet).
/// Dibaca dinamis (non-const) agar ikut berubah saat settings diganti.
class AppFonts {
  AppFonts._();

  static String? get mono {
    try {
      final c = Get.find<SettingsController>();
      final v = c.monoFont.value;
      return v == SettingsController.system ? null : v;
    } catch (_) {
      return 'JetBrainsMono';
    }
  }

  /// Ukuran font area kode (px). Default 12.
  static double get monoSize {
    try {
      return Get.find<SettingsController>().codeSize.value;
    } catch (_) {
      return 12.0;
    }
  }
}
