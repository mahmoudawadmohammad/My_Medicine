// ============================================================
// ملف: language_controller.dart
// المسار: lib/controllers/language_controller.dart
// الوصف: متحكم اللغة - يدعم 3 أوضاع:
//        1. system (حسب النظام) - الافتراضي
//        2. ar (العربية)
//        3. en (English)
// ============================================================

import 'dart:io';                                    // للوصول لـ Platform.localeName
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  // ===== مفتاح التخزين =====
  static const String _languageKey = 'app_language';

  // ===== اللغات المدعومة =====
  static const List<Map<String, dynamic>> supportedLanguages = [
    {
      'code': 'ar',
      'name': 'العربية',
      'flag': '🇸🇦',
      'direction': TextDirection.rtl,
    },
    {
      'code': 'en',
      'name': 'English',
      'flag': '🇺🇸',
      'direction': TextDirection.ltr,
    },
  ];

  // ==========================================================
  // اللغة الحالية
  // القيم الممكنة: 'system', 'ar', 'en'
  // ==========================================================
  final RxString currentLanguage = 'system'.obs;

  // ==========================================================
  // Getter: اللغة الفعلية (بعد حل 'system')
  // ==========================================================
  String get effectiveLanguage {
    if (currentLanguage.value == 'system') {
      return _getSystemLanguage();
    }
    return currentLanguage.value;
  }

  // ==========================================================
  // Getter: Locale للتطبيق
  // ==========================================================
  Locale get locale => Locale(effectiveLanguage);

  // ==========================================================
  // Getter: الاتجاه (RTL/LTR)
  // ==========================================================
  TextDirection get currentDirection {
    final lang = supportedLanguages.firstWhere(
          (l) => l['code'] == effectiveLanguage,
      orElse: () => supportedLanguages.first,
    );
    return lang['direction'] as TextDirection;
  }

  // ==========================================================
  // Getter: اسم اللغة
  // ==========================================================
  String get currentLanguageName {
    if (currentLanguage.value == 'system') {
      // نرجع اسم اللغة الفعلية + "(النظام)"
      final lang = supportedLanguages.firstWhere(
            (l) => l['code'] == effectiveLanguage,
        orElse: () => supportedLanguages.first,
      );
      return '${lang['name']} (${'system'.tr})';
    }

    final lang = supportedLanguages.firstWhere(
          (l) => l['code'] == currentLanguage.value,
      orElse: () => supportedLanguages.first,
    );
    return lang['name'] as String;
  }

  // ==========================================================
  // Getter: نص الوضع الحالي
  // ==========================================================
  String get languageModeString => currentLanguage.value;

  // ==========================================================
  // دورة الحياة
  // ==========================================================
  @override
  void onInit() {
    super.onInit();
    _loadLanguage();
  }

  // ==========================================================
  // تحميل اللغة من الذاكرة
  // ==========================================================
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // القيمة الافتراضية: 'system' (حسب النظام)
      final savedLang = prefs.getString(_languageKey) ?? 'system';
      currentLanguage.value = savedLang;
      _applyLanguage();
      debugPrint('📂 Language loaded: $savedLang (effective: $effectiveLanguage)');
    } catch (e) {
      debugPrint('❌ Error loading language: $e');
    }
  }

  // ==========================================================
  // ✅ قراءة لغة النظام
  // ==========================================================
  String _getSystemLanguage() {
    try {
      // Platform.localeName يرجع شيء مثل: 'ar_SA', 'en_US'
      final systemLocale = Platform.localeName;
      final langCode = systemLocale.split('_').first.toLowerCase();

      debugPrint('🌐 System locale: $systemLocale → $langCode');

      // ✅ إذا كانت اللغة مدعومة، استخدمها
      if (['ar', 'en'].contains(langCode)) {
        return langCode;
      }

      // ✅ اللغة الافتراضية: عربي
      return 'ar';
    } catch (e) {
      debugPrint('❌ Error getting system language: $e');
      return 'ar';
    }
  }

  // ==========================================================
  // تعيين وضع اللغة
  // [mode]: 'system' | 'ar' | 'en'
  // ==========================================================
  Future<void> changeLanguage(String mode) async {
    if (!['system', 'ar', 'en'].contains(mode)) {
      debugPrint('⚠️ Invalid language mode: $mode');
      return;
    }

    if (currentLanguage.value == mode) return;

    currentLanguage.value = mode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, mode);
      debugPrint('💾 Language saved: $mode');
    } catch (e) {
      debugPrint('❌ Error saving language: $e');
    }

    _applyLanguage();
  }

  // ==========================================================
  // تطبيق اللغة على التطبيق
  // ==========================================================
  void _applyLanguage() {
    Get.updateLocale(locale);
    debugPrint('🎨 Language applied: ${locale.languageCode}');
  }

  // ==========================================================
  // التبديل بين العربية والإنجليزية
  // ==========================================================
  Future<void> toggleLanguage() async {
    final newLang = effectiveLanguage == 'ar' ? 'en' : 'ar';
    await changeLanguage(newLang);
  }
}