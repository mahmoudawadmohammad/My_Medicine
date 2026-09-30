// ============================================================
// ملف: app_colors.dart
// الوصف: تعريف ألوان التطبيق في مكان واحد لتسهيل التعديل
// ============================================================

import 'package:flutter/material.dart'; // مكتبة Flutter للألوان

// 🎨 AppColors: فئة تحتوي على جميع ألوان التطبيق
class AppColors {
  AppColors._(); // Constructor خاص لمنع إنشاء نسخة من الفئة

  // ===== الألوان الرئيسية =====
  static const Color primary = Color(0xFF1B7B6E); // اللون الرئيسي - أخضر داكن
  static const Color primaryLight = Color(0xFF20B2AA); // اللون الرئيسي الفاتح
  static const Color secondary = Color(0xFF2E8B57); // اللون الثانوي - أخضر بحري
  static const Color accent = Color(0xFF3CB371); // لون تمييز - أخضر متوسط

  // ===== ألوان الأدراج =====
  static const Color drawerAvailable = Colors.green; // الدرج جاهز
  static const Color drawerAlert = Colors.red; // الدرج يحتاج فتح (دواء مستحق)
  static const Color drawerEmpty = Colors.grey; // الدرج فارغ/غير نشط

  // ===== ألوان النصوص =====
  static const Color textPrimary = Color(0xFF333333); // لون النص الرئيسي
  static const Color textSecondary = Color(0xFF666666); // لون النص الثانوي
  static const Color textLight = Colors.white; // لون النص الفاتح

  // ===== ألوان الخلفيات =====
  static const Color background = Colors.white; // لون الخلفية الرئيسي
  static const Color surface = Color(0xFFF5F5F5); // لون سطح العناصر

  // ===== ألوان الحالة =====
  static const Color success = Color(0xFF4CAF50); // نجاح - أخضر
  static const Color error = Color(0xFFE53935); // خطأ - أحمر
  static const Color warning = Color(0xFFFFA726); // تحذير - برتقالي
  static const Color info = Color(0xFF29B6F6); // معلومات - أزرق
}