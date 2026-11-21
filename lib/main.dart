// ============================================================
// ملف: main.dart
// المسار: lib/main.dart
// الوصف: نقطة بداية تشغيل التطبيق - أول ملف يتم تنفيذه
//         يدعم: اللغة حسب النظام + الوضع حسب النظام
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:smart_pillbox/services/auth_service.dart';
import 'package:smart_pillbox/services/background_task.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 👈 ضفت هاد الاستيراد
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'controllers/category_controller.dart';
import 'controllers/medicine_controller.dart';
import 'core/utils/notification_helper.dart';
import 'controllers/theme_controller.dart';
import 'controllers/language_controller.dart';
import 'core/constants/app_theme.dart';
import 'core/localization/app_translations.dart';
import 'firebase_options.dart';

// 🚀 دالة main
void main() async {
  // ===== تهيئة Flutter =====
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ تم تهيئة Firebase');
  } catch (e) {
    debugPrint('❌ خطأ في تهيئة Firebase: $e');
  }

  // ===== الحفاظ على شاشة البداية =====
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ===== تهيئة المناطق الزمنية =====
  tz.initializeTimeZones();

  // ✅ تهيئة المتحكمات
  Get.put(ThemeController());
  Get.put(LanguageController());
  Get.put(AuthService());
  Get.put(MedicineController());
  Get.put(CategoryController());

  // ✅ تهيئة الإشعارات (FCM + Local Notifications)
  try {
    // 1. تهيئة FCM للخلفية (عشان الرسائل توصل لو التطبيق مسكر)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. طلب صلاحيات الإشعارات من المستخدم
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. جلب التوكن وطباعته (عشان تشوفه باللوج وتتأكد إنه شغال)
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint('📱 FCM Token: $token');

    // 4. تهيئة الإشعارات المحلية والعرض
    final NotificationHelper notificationHelper = NotificationHelper();
    await notificationHelper.initialize();
    debugPrint('✅ تم تهيئة الإشعارات (FCM + Local)');
  } catch (e) {
    debugPrint('❌ خطأ في تهيئة الإشعارات: $e');
  }

  try {
    // ✅ تهيئة WorkManager
    await Workmanager().initialize(
      callbackDispatcher,
    );
    debugPrint('✅ تم تهيئة Workmanager');
  } catch (e) {
    debugPrint('❌ خطأ في تهيئة Workmanager: $e');
  }

  // ===== تشغيل التطبيق =====
  runApp(const MyApp());
}

// ============================================================
// 🏠 MyApp
// ============================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ الحصول على المتحكمات
    final ThemeController themeController = Get.find<ThemeController>();
    final LanguageController languageController = Get.find<LanguageController>();

    // ✅ Obx لمراقبة تغيرات الثيم واللغة
    return Obx(() {
      return GetMaterialApp(
        // عنوان التطبيق
        title: 'app_name'.tr,

        // إخفاء شعار Debug
        debugShowCheckedModeBanner: false,

        // ===== ✅ إعدادات اللغة =====
        // نستخدم locale getter الجديد من LanguageController
        locale: languageController.locale,
        translations: AppTranslations(),
        fallbackLocale: const Locale('ar'),

        // ===== الثيمات =====
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,

        // ✅ نستخدم themeMode getter الجديد من ThemeController
        //    يدعم: ThemeMode.system | ThemeMode.light | ThemeMode.dark
        themeMode: themeController.themeMode,

        // ===== الصفحة الرئيسية =====
        home: const App(),
      );
    });
  }
}