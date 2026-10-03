// ============================================================
// ملف: background_task.dart
// المسار: lib/core/utils/background_task.dart
// الوصف: المهام الخلفية (Background Tasks)
//         ✅ يدعم عزل البيانات لكل مستخدم (userId)
//         ✅ يسجل الأحداث في medicine_logs
//         ✅ لا يعرض إشعار (الإشعار المجدول يكفي)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:workmanager/workmanager.dart';

// ==========================================================
// ✅ اسم المهمة (فريد)
// ==========================================================
const String medicineDoseTask = "com.dawaei.app.medicineDose";

// ==========================================================
// ✅ اسم قاعدة البيانات
// ==========================================================
const String _dbName = 'dawaei.db';

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

  // ❌ تم حذف عرض الإشعار
  // await _showNotification(medicineMap, doseNumber, pillCount);
  // السبب: الإشعار المجدول (zonedSchedule) يعرض الإشعار أصلاً
  //        عرض إشعار آخر بنفس المعرف يستبدل الإشعار الأصلي

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
      existingWorkPolicy: ExistingWorkPolicy.keep,
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

  // ✅✅✅ إصلاح: نبدأ من الغد
  for (int daysToAdd = 1; daysToAdd < 30; daysToAdd++) {
    final DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day + daysToAdd,
      hour,
      minute,
    );

    // ✅✅✅ إذا كل الأيام: نرجع الغد مباشرة (بدون شروط)
    if (selectedDays.isEmpty) {
      debugPrint('📅 كل الأيام → الغد: $candidate');
      return candidate;
    }

    final int flutterWeekday = candidate.weekday;
    int ourDayValue;
    switch (flutterWeekday) {
      case 6:
        ourDayValue = 1; // السبت
        break;
      case 7:
        ourDayValue = 2; // الأحد
        break;
      case 1:
        ourDayValue = 3; // الاثنين
        break;
      case 2:
        ourDayValue = 4; // الثلاثاء
        break;
      case 3:
        ourDayValue = 5; // الأربعاء
        break;
      case 4:
        ourDayValue = 6; // الخميس
        break;
      case 5:
        ourDayValue = 7; // الجمعة
        break;
      default:
        ourDayValue = 0;
    }

    if (selectedDays.contains(ourDayValue)) {
      debugPrint('📅 يوم مطابق: $candidate (يوم $ourDayValue)');
      return candidate;
    }
  }

  debugPrint('⚠️ لا يوجد يوم مطابق خلال 30 يوم');
  return null;
}

// ==========================================================
// ✅ فتح قاعدة البيانات
// ==========================================================
Future<Database> _openDatabase() async {
  final String path = join(await getDatabasesPath(), _dbName);
  return await openDatabase(path);
}