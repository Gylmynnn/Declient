import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_theme.dart';

/// Pilihan font UI + mono. Disimpan persisten, diterapkan live via Get.changeTheme.
class SettingsController extends GetxController {
  static const _kUiFont = 'ui_font';
  static const _kMonoFont = 'mono_font';
  static const _kUiScale = 'ui_scale';
  static const _kCodeSize = 'code_size';

  static const String system = 'System';
  static const String jetbrains = 'JetBrainsMono';
  static const String iosevka = 'Iosevka';

  static const List<String> fontOptions = [system, jetbrains, iosevka];

  final RxString uiFont = system.obs;
  final RxString monoFont = jetbrains.obs;

  /// Skala font seluruh UI (0.85 - 1.3).
  final RxDouble uiScale = 1.0.obs;

  /// Ukuran font area kode dalam px (10 - 18).
  final RxDouble codeSize = 12.0.obs;
  final RxBool loaded = false.obs;

  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    _prefs ??= await SharedPreferences.getInstance();
    uiFont.value = _prefs!.getString(_kUiFont) ?? system;
    monoFont.value = _prefs!.getString(_kMonoFont) ?? jetbrains;
    uiScale.value = (_prefs!.getDouble(_kUiScale) ?? 1.0).clamp(0.85, 1.3);
    codeSize.value = (_prefs!.getDouble(_kCodeSize) ?? 12.0).clamp(10.0, 18.0);
    loaded.value = true;
    apply();
  }

  Future<void> setUiFont(String v) async {
    uiFont.value = v;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_kUiFont, v);
    apply();
  }

  Future<void> setMonoFont(String v) async {
    monoFont.value = v;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_kMonoFont, v);
    apply();
  }

  Future<void> setUiScale(double v) async {
    uiScale.value = v.clamp(0.85, 1.3);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble(_kUiScale, uiScale.value);
  }

  Future<void> setCodeSize(double v) async {
    codeSize.value = v.clamp(10.0, 18.0);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble(_kCodeSize, codeSize.value);
  }

  /// Terapkan font ke theme aktif. Aman dipanggil berkali-kali.
  void apply() {
    Get.changeTheme(AppTheme.darkTheme(fontFamily: _familyOrNull(uiFont.value)));
  }

  static String? _familyOrNull(String v) => v == system ? null : v;
}
