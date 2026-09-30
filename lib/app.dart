// ============================================================
// ملف: app.dart
// الوصف: يحدد الصفحة الأولى التي تظهر للمستخدم
//         (شاشة Onboarding أو تسجيل الدخول أو الصفحة الرئيسية)
// ============================================================

import 'package:flutter/material.dart'; // مكتبة واجهات Flutter
import 'package:flutter_native_splash/flutter_native_splash.dart'; // شاشة البداية
import 'package:get/get.dart'; // مكتبة GetX
import 'package:shared_preferences/shared_preferences.dart'; // تخزين الإعدادات المحلية
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Firebase Auth للتحقق من حالة تسجيل الدخول
import 'package:smart_pillbox/views/splash_screen.dart'; // شاشة التحميل
import 'views/onboarding_screen.dart'; // شاشة التعريف الأولى
import 'views/home_screen.dart'; // الصفحة الرئيسية
import 'views/login_screen.dart'; // ✅ شاشة تسجيل الدخول

// 🎛️ App: ويدجت يتحكم في أي صفحة تظهر أولاً
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // ===== متغيرات الحالة =====
  bool _isFirstTime = true; // هل هذه أول مرة يفتح فيها المستخدم التطبيق؟
  bool _isLoading = true; // هل ما زلنا نحمّل البيانات؟

  @override
  void initState() {
    super.initState(); // استدعاء initState الأصلي
    _checkFirstTime(); // التحقق من حالة أول استخدام
  }

  // 🔍 دالة التحقق من أول استخدام للتطبيق
  Future<void> _checkFirstTime() async {
    // ===== الحصول على نسخة من SharedPreferences =====
    // SharedPreferences: تخزين بيانات بسيطة على شكل مفتاح-قيمة
    final prefs = await SharedPreferences.getInstance();

    // ===== قراءة قيمة 'isFirstTime' =====
    // getBool: يسترجع قيمة Boolean من التخزين
    // ?? true: إذا كانت القيمة null (غير موجودة) نعيد true
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    // ===== تحديث واجهة المستخدم =====
    // setState: يخبر Flutter بإعادة رسم الويدجت
    setState(() {
      _isFirstTime = isFirstTime; // تحديث متغير أول استخدام
      _isLoading = false; // انتهى التحميل
    });

    // ===== إخفاء شاشة البداية الأصلية =====
    // remove(): يزيل شاشة البداية الأصلية تدريجياً
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    // ===== عرض شاشة التحميل أثناء التحقق =====
    if (_isLoading) {
      return const SplashScreen(); // شاشة تحميل جميلة
    }

    // ===== إذا كانت أول مرة: عرض Onboarding =====
    if (_isFirstTime) {
      return const OnboardingScreen();
    }

    // ===== إذا لم تكن أول مرة: التحقق من حالة تسجيل الدخول =====
    // ✅ StreamBuilder: يستمع لتغييرات حالة المستخدم في Firebase
    // عندما يسجّل المستخدم دخوله أو خروجه، يعيد بناء نفسه تلقائياً
    return StreamBuilder<User?>(
      // authStateChanges(): Stream يرصد حالة تسجيل الدخول
      // - User: إذا كان المستخدم مسجّلاً
      // - null: إذا لم يكن مسجّلاً
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {
        // ===== أثناء انتظار البيانات =====
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // ===== إذا كان المستخدم مسجّل دخول =====
        // snapshot.hasData: true إذا كان هناك مستخدم
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // ===== إذا لم يكن مسجّل دخول =====
        return const LoginScreen();
      },
    );
  }
}