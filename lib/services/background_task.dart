// ============================================================
// ملف: background_task.dart
// المسار: lib/core/utils/background_task.dart
// الوصف: المهام الخلفية (Background Tasks)
//         ✅ يدعم عزل البيانات لكل مستخدم (userId)
//         ✅ يدعم اللغتين (عربي/إنجليزي) بدون GetX
//         ✅ يسجل الأحداث في medicine_logs
// ============================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

// ==========================================================
// ✅ اسم المهمة (فريد)
// ==========================================================
const String medicineDoseTask = "com.dawaei.app.medicineDose";

// ==========================================================
// ✅ اسم قاعدة البيانات
// ==========================================================
const String _dbName = 'dawaei.db';

// ==========================================================
// ✅ قاموس النصوص - عربي
// ==========================================================
const Map<String, String> _arTexts = {
  'notification_medicine': 'موعد الدواء',
  'first_dose': 'الجرعة الأولى',
  'second_dose': 'الجرعة الثانية',
  'third_dose': 'الجرعة الثالثة',
  'remaining_colon': 'المتبقي',
  'pill': 'حبة',
  'out_of_pills_need_refill': '🚫 نفذت الحبات - يحتاج إعادة تعبئة',
  'notification_low_stock': '⚠️ المخزون منخفض - يُنصح بإعادة التعبئة',
  'summary_medicine': 'دواء',
};

// ==========================================================
// ✅ قاموس النصوص - إنجليزي
// ==========================================================
const Map<String, String> _enTexts = {
  'notification_medicine': 'Medicine Time',
  'first_dose': 'First Dose',
  'second_dose': 'Second Dose',
  'third_dose': 'Third Dose',
  'remaining_colon': 'Remaining',
  'pill': 'pill',
  'out_of_pills_need_refill': '🚫 Out of pills - Refill needed',
  'notification_low_stock': '⚠️ Low stock - Refill recommended',
  'summary_medicine': 'Medicine',
};

// ==========================================================
// ✅ دالة قراءة اللغة الفعلية
// ==========================================================
Future<String> _getEffectiveLanguage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language') ?? 'system';

    if (savedLang == 'system') {
      final systemLocale = Platform.localeName;
      final langCode = systemLocale.split('_').first.toLowerCase();

      if (['ar', 'en'].contains(langCode)) {
        return langCode;
      }
      return 'ar';
    }

    if (['ar', 'en'].contains(savedLang)) {
      return savedLang;
    }

    return 'ar';
  } catch (e) {
    debugPrint('❌ خطأ في قراءة اللغة: $e');
    return 'ar';
  }
}

// ==========================================================
// ✅ دالة الحصول على نص مترجم
// ==========================================================
Future<String> _getText(String key) async {
  final lang = await _getEffectiveLanguage();
  if (lang == 'ar') {
    return _arTexts[key] ?? key;
  } else {
    return _enTexts[key] ?? key;
  }
}

// ==========================================================
// ✅ دالة الـ Callback (تنفذ في Isolate منفصل)
// ==========================================================
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 Background Task: $task');
    debugPrint('📦 Input Data: $inputData');

    try {
      if (task == medicineDoseTask) {
        await _handleMedicineDose(inputData!);
      }
    } catch (e) {
      debugPrint('❌ خطأ في Background Task: $e');
    }

    return true;
  });
}

// ==========================================================
// ✅ معالجة جرعة الدواء (مع userId + تسجيل الحدث)
// ==========================================================
Future<void> _handleMedicineDose(Map<String, dynamic> inputData) async {
  final int medicineId = inputData['medicineId'];
  final int doseNumber = inputData['doseNumber'];
  final String userId = inputData['userId'] ?? '';

  if (userId.isEmpty) {
    debugPrint('❌ userId مفقود من inputData');
    return;
  }

  debugPrint('💊 معالجة الجرعة $doseNumber للدواء $medicineId (المستخدم: $userId)');

  final Database db = await _openDatabase();

  // ✅ فلترة حسب userId
  final List<Map<String, dynamic>> maps = await db.query(
    'medicines',
    where: 'id = ? AND userId = ?',
    whereArgs: [medicineId, userId],
  );

  if (maps.isEmpty) {
    debugPrint('❌ الدواء غير موجود: $medicineId للمستخدم $userId');
    return;
  }

  final Map<String, dynamic> medicineMap = maps.first;
  int pillCount = medicineMap['pillCount'] ?? 0;

  if (pillCount <= 0) {
    debugPrint('⚠️ لا توجد حبات');
    return;
  }

  // ✅ حفظ عدد الحبات قبل الإنقاص
  final int pillCountBefore = pillCount;

  pillCount--;

  // ✅ تحديث processedTimes
  final String? processedTimesStr = medicineMap['processedTimes'] as String?;
  List<int> processedTimes = processedTimesStr != null && processedTimesStr.isNotEmpty
      ? processedTimesStr.split(',').map((e) => int.parse(e.trim())).toList()
      : [];

  // ✅ التحقق من اليوم
  final String? lastProcessedDateStr = medicineMap['lastProcessedDate'] as String?;
  final DateTime now = DateTime.now();
  bool isSameDay = false;

  if (lastProcessedDateStr != null) {
    final DateTime lastProcessed = DateTime.parse(lastProcessedDateStr);
    isSameDay = lastProcessed.year == now.year &&
        lastProcessed.month == now.month &&
        lastProcessed.day == now.day;
  }

  if (!isSameDay) {
    processedTimes = [];
  }

  if (!processedTimes.contains(doseNumber)) {
    processedTimes.add(doseNumber);
  }

  // ✅ تحديث قاعدة البيانات (مع userId)
  await db.update(
    'medicines',
    {
      'pillCount': pillCount,
      'lastProcessedDate': now.toIso8601String(),
      'processedTimes': processedTimes.join(','),
    },
    where: 'id = ? AND userId = ?',
    whereArgs: [medicineId, userId],
  );

  debugPrint('✅ تم إنقاص حبة. المتبقي: $pillCount');

  // ✅ تسجيل الحدث في medicine_logs
  int? scheduledHour;
  int? scheduledMinute;
  if (doseNumber == 1) {
    scheduledHour = medicineMap['hour'];
    scheduledMinute = medicineMap['minute'];
  } else if (doseNumber == 2) {
    scheduledHour = medicineMap['hour2'];
    scheduledMinute = medicineMap['minute2'];
  } else if (doseNumber == 3) {
    scheduledHour = medicineMap['hour3'];
    scheduledMinute = medicineMap['minute3'];
  }

  await _logTakenInBackground(
    db: db,
    userId: userId,
    medicineId: medicineId,
    medicineName: medicineMap['name'] ?? '',
    categoryId: medicineMap['categoryId'],
    doseNumber: doseNumber,
    scheduledHour: scheduledHour,
    scheduledMinute: scheduledMinute,
    pillCountBefore: pillCountBefore,
    pillCountAfter: pillCount,
  );

  // ✅ عرض الإشعار
  await _showNotification(medicineMap, doseNumber, pillCount);

  // ✅ إعادة جدولة الجرعة القادمة (مع userId)
  await _rescheduleNextDose(medicineId, doseNumber, userId, medicineMap);
}

// ==========================================================
// ✅ تسجيل حدث "تناول" في background
// ==========================================================
Future<void> _logTakenInBackground({
  required Database db,
  required String userId,
  required int medicineId,
  required String medicineName,
  required int? categoryId,
  required int doseNumber,
  required int? scheduledHour,
  required int? scheduledMinute,
  required int pillCountBefore,
  required int pillCountAfter,
}) async {
  try {
    // ✅ تنسيق الوقت المجدول
    String? scheduledTime;
    if (scheduledHour != null && scheduledMinute != null) {
      final h = scheduledHour.toString().padLeft(2, '0');
      final m = scheduledMinute.toString().padLeft(2, '0');
      scheduledTime = '$h:$m';
    }

    await db.insert('medicine_logs', {
      'userId': userId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'categoryId': categoryId,
      'actionType': 'taken',
      'doseNumber': doseNumber,
      'scheduledTime': scheduledTime,
      'actionTime': DateTime.now().toIso8601String(),
      'pillCountBefore': pillCountBefore,
      'pillCountAfter': pillCountAfter,
    });

    debugPrint('📝 تم تسجيل: taken ($medicineName - جرعة $doseNumber)');
  } catch (e) {
    debugPrint('❌ خطأ في تسجيل الحدث: $e');
  }
}

// ==========================================================
// ✅ عرض الإشعار (مع دعم اللغتين)
// ==========================================================
Future<void> _showNotification(
    Map<String, dynamic> medicineMap,
    int doseNumber,
    int remainingPills,
    ) async {
  try {
    tz_data.initializeTimeZones();

    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await plugin.initialize(initSettings);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pillbox_medicine_channel_v2',
      'تنبيهات مواعيد الأدوية',
      channelDescription: 'إشعارات عند موعد تناول الدواء',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF1B7B6E),
      colorized: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // ✅ قراءة النصوص من القواميس (حسب اللغة)
    final String notificationMedicine = await _getText('notification_medicine');
    final String firstDose = await _getText('first_dose');
    final String secondDose = await _getText('second_dose');
    final String thirdDose = await _getText('third_dose');
    final String remainingColon = await _getText('remaining_colon');
    final String pill = await _getText('pill');
    final String outOfPills = await _getText('out_of_pills_need_refill');
    final String lowStock = await _getText('notification_low_stock');
    final String summaryMedicine = await _getText('summary_medicine');

    final String name = medicineMap['name'] ?? summaryMedicine;
    final int id = medicineMap['id'] ?? 0;

    // ✅ بناء doseLabel
    String doseLabel = '';
    if (doseNumber == 1) {
      doseLabel = '($firstDose)';
    } else if (doseNumber == 2) {
      doseLabel = '($secondDose)';
    } else if (doseNumber == 3) {
      doseLabel = '($thirdDose)';
    }

    // ✅ بناء النص
    String title = '🔔 $notificationMedicine: $name $doseLabel';
    String body = '💊 $remainingColon: $remainingPills $pill.';

    if (remainingPills == 0) {
      body += '\n$outOfPills';
    } else if (remainingPills <= 3) {
      body += '\n$lowStock';
    }

    // ✅ عرض الإشعار
    await plugin.show(
      id * 10 + doseNumber,
      title,
      body,
      details,
      payload: 'medicine_${id}_$doseNumber',
    );

    debugPrint('🔔 تم إرسال الإشعار: $title');
  } catch (e) {
    debugPrint('❌ خطأ في عرض الإشعار: $e');
  }
}

// ==========================================================
// ✅ إعادة جدولة الجرعة القادمة (مع userId)
// ==========================================================
Future<void> _rescheduleNextDose(
    int medicineId,
    int doseNumber,
    String userId,
    Map<String, dynamic> medicineMap,
    ) async {
  try {
    int? hour;
    int? minute;

    if (doseNumber == 1) {
      hour = medicineMap['hour'];
      minute = medicineMap['minute'];
    } else if (doseNumber == 2) {
      hour = medicineMap['hour2'];
      minute = medicineMap['minute2'];
    } else if (doseNumber == 3) {
      hour = medicineMap['hour3'];
      minute = medicineMap['minute3'];
    }

    if (hour == null || minute == null) {
      debugPrint('⚠️ وقت الجرعة غير موجود');
      return;
    }

    final String? selectedDaysStr = medicineMap['selectedDays'] as String?;
    final List<int> selectedDays = selectedDaysStr != null && selectedDaysStr.isNotEmpty
        ? selectedDaysStr.split(',').map((e) => int.parse(e.trim())).toList()
        : [];

    final DateTime? nextDate = _calculateNextDate(hour, minute, selectedDays);
    if (nextDate == null) {
      debugPrint('⚠️ لا يوجد يوم مطابق');
      return;
    }

    final Duration delay = nextDate.difference(DateTime.now());
    if (delay.isNegative) {
      debugPrint('⚠️ التأخير سالب');
      return;
    }

    await Workmanager().registerOneOffTask(
      "medicine_${medicineId}_$doseNumber",
      medicineDoseTask,
      initialDelay: delay,
      inputData: {
        'medicineId': medicineId,
        'doseNumber': doseNumber,
        'userId': userId,
      },
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    debugPrint('✅ تمت إعادة جدولة الجرعة $doseNumber في $nextDate (المستخدم: $userId)');
  } catch (e) {
    debugPrint('❌ خطأ في إعادة الجدولة: $e');
  }
}

// ==========================================================
// ✅ حساب أقرب يوم مطابق
// ==========================================================
DateTime? _calculateNextDate(int hour, int minute, List<int> selectedDays) {
  final DateTime now = DateTime.now();

  for (int daysToAdd = 1; daysToAdd < 30; daysToAdd++) {
    final DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day + daysToAdd,
      hour,
      minute,
    );

    if (selectedDays.isEmpty) {
      return candidate;
    }

    final int flutterWeekday = candidate.weekday;
    int ourDayValue;
    switch (flutterWeekday) {
      case 6:
        ourDayValue = 1;
        break;
      case 7:
        ourDayValue = 2;
        break;
      case 1:
        ourDayValue = 3;
        break;
      case 2:
        ourDayValue = 4;
        break;
      case 3:
        ourDayValue = 5;
        break;
      case 4:
        ourDayValue = 6;
        break;
      case 5:
        ourDayValue = 7;
        break;
      default:
        ourDayValue = 0;
    }

    if (selectedDays.contains(ourDayValue)) {
      return candidate;
    }
  }

  return null;
}

// ==========================================================
// ✅ فتح قاعدة البيانات
// ==========================================================
Future<Database> _openDatabase() async {
  final String path = join(await getDatabasesPath(), _dbName);
  return await openDatabase(path);
}