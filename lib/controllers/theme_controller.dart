// ============================================================
// ملف: theme_controller.dart
// المسار: lib/controllers/theme_controller.dart
// الوصف: متحكم الثيم - يدعم 3 أوضاع:
//        1. system (حسب النظام) - الافتراضي
//        2. light (فاتح)
//        3. dark (داكن)
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  // ===== مفتاح التخزين =====
  static const String _themeModeKey = 'theme_mode';

  // ===== المتغير التفاعلي =====
  // القيم الممكنة: 'system', 'light', 'dark'
  final RxString _themeModeString = 'system'.obs;

  // ===== Getter: ThemeMode =====
  ThemeMode get themeMode {
    switch (_themeModeString.value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  // ===== Getter: هل الوضع الداكن؟ =====
  // (يُستخدم للعرض في الإعدادات)
  bool get isDarkMode {
    if (_themeModeString.value == 'dark') return true;
    if (_themeModeString.value == 'light') return false;
    // system: نرجع حسب إعدادات النظام الحالية
    return Get.isPlatformDarkMode;
  }

  // ===== Getter: نص الحالة =====
  String get themeModeString => _themeModeString.value;

  // ==========================================================
  // دورة الحياة
  // ==========================================================
  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  // ==========================================================
  // تحميل الثيم من الذاكرة
  // ==========================================================
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // القيمة الافتراضية: 'system' (حسب النظام)
      _themeModeString.value = prefs.getString(_themeModeKey) ?? 'system';
      debugPrint('📂 Theme loaded: ${_themeModeString.value}');
    } catch (e) {
      debugPrint('❌ Error loading theme: $e');
    }
  }

  // ==========================================================
  // تعيين وضع الثيم
  // [mode]: 'system' | 'light' | 'dark'
  // ==========================================================
  Future<void> setThemeMode(String mode) async {
    if (!['system', 'light', 'dark'].contains(mode)) {
      debugPrint('⚠️ Invalid theme mode: $mode');
      return;
    }

    _themeModeString.value = mode;
    debugPrint('🎨 Theme mode set to: $mode');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode);
    } catch (e) {
      debugPrint('❌ Error saving theme: $e');
    }
  }

  // ==========================================================
  // ✅ للتوافق مع الكود القديم
  // ==========================================================
  Future<void> setDarkMode(bool value) async {
    await setThemeMode(value ? 'dark' : 'light');
  }
}