// ============================================================
// ملف: background_task.dart
// المسار: lib/core/utils/background_task.dart
// الوصف: المهام الخلفية (Background Tasks)
//         ✅ يدعم عزل البيانات لكل مستخدم (userId)
//         ✅ يسجل الأحداث في medicine_logs
//         ✅ يزامن البيانات مع Firestore (pillCount, processedTimes)
//         ✅ تمت إزالة إعادة الجدولة (لأن WorkManager الدوري في notification_helper مسؤول عنها)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_pillbox/firebase_options.dart';

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
      // 🔥 تهيئة Firebase داخل الـ Isolate
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

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
// ✅ معالجة جرعة الدواء (مع userId + تسجيل الحدث + Firestore)
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

  // ✅ تحديث قاعدة البيانات المحلية (مع userId)
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

  debugPrint('✅ تم إنقاص حبة محلياً. المتبقي: $pillCount');

  // ========================================================
  // 🔥 التزامن مع Firestore
  // ========================================================
  await _syncWithFirestore(
    userId: userId,
    medicineId: medicineId,
    pillCount: pillCount,
    lastProcessedDate: now,
    processedTimes: processedTimes,
  );

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

  // ❌ تمت إزالة إعادة الجدولة (لأن WorkManager الدوري في notification_helper مسؤول عنها)
  // await _rescheduleNextDose(medicineId, doseNumber, userId, medicineMap);
}

// ==========================================================
// 🔥 مزامنة البيانات مع Firestore
// ==========================================================
Future<void> _syncWithFirestore({
  required String userId,
  required int medicineId,
  required int pillCount,
  required DateTime lastProcessedDate,
  required List<int> processedTimes,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .doc(medicineId.toString())
        .set({
      'pillCount': pillCount,
      'lastProcessedDate': lastProcessedDate.toIso8601String(),
      'processedTimes': processedTimes,
      'lastSyncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('✅ تمت مزامنة البيانات مع Firestore');
  } catch (e) {
    debugPrint('⚠️ فشل التزامن مع Firestore (سيتم لاحقاً): $e');
  }
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
// ✅ فتح قاعدة البيانات
// ==========================================================
Future<Database> _openDatabase() async {
  final String path = join(await getDatabasesPath(), _dbName);
  return await openDatabase(path);
}