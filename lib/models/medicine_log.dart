// ============================================================
// ملف: medicine_log.dart
// المسار: lib/models/medicine_log.dart
// الوصف: نموذج سجل الدواء - يسجل أحداث التناول والتعبئة
//         ✅ يدعم عزل البيانات لكل مستخدم (userId)
// ============================================================

import 'package:flutter/material.dart';

// 📝 MedicineLog: نموذج بيانات يمثل حدثاً واحداً
// أنواع الأحداث:
// - 'taken'  = تم تناول حبة
// - 'refill' = تمت إعادة تعبئة
class MedicineLog {
  // ==========================================================
  // الخصائص الأساسية
  // ==========================================================

  /// معرف السجل في قاعدة البيانات
  int? id;

  /// معرف المستخدم (للعزل)
  String userId;

  /// معرف الدواء
  int medicineId;

  /// اسم الدواء (محفوظ للتاريخ حتى لو حُذف الدواء)
  String medicineName;

  /// معرف التصنيف (اختياري - للتحليلات)
  int? categoryId;

  /// نوع الحدث: 'taken' | 'refill'
  String actionType;

  /// رقم الجرعة (1، 2، 3) - للـ 'taken' فقط
  int? doseNumber;

  /// وقت الجرعة المجدول (HH:mm) - للـ 'taken' فقط
  String? scheduledTime;

  /// وقت التنفيذ الفعلي
  DateTime actionTime;

  /// عدد الحبات قبل الحدث
  int pillCountBefore;

  /// عدد الحبات بعد الحدث
  int pillCountAfter;

  /// ملاحظات إضافية (اختياري)
  String? notes;

  // ==========================================================
  // Constructor
  // ==========================================================
  MedicineLog({
    this.id,
    required this.userId,
    required this.medicineId,
    required this.medicineName,
    this.categoryId,
    required this.actionType,
    this.doseNumber,
    this.scheduledTime,
    required this.actionTime,
    required this.pillCountBefore,
    required this.pillCountAfter,
    this.notes,
  });

  // ==========================================================
  // toMap - للتحويل للتخزين في SQLite
  // ==========================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'categoryId': categoryId,
      'actionType': actionType,
      'doseNumber': doseNumber,
      'scheduledTime': scheduledTime,
      'actionTime': actionTime.toIso8601String(),
      'pillCountBefore': pillCountBefore,
      'pillCountAfter': pillCountAfter,
      'notes': notes,
    };
  }

  // ==========================================================
  // fromMap - للتحويل من التخزين
  // ==========================================================
  factory MedicineLog.fromMap(Map<String, dynamic> map) {
    return MedicineLog(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      medicineId: map['medicineId'] as int,
      medicineName: map['medicineName'] as String,
      categoryId: map['categoryId'] as int?,
      actionType: map['actionType'] as String,
      doseNumber: map['doseNumber'] as int?,
      scheduledTime: map['scheduledTime'] as String?,
      actionTime: DateTime.parse(map['actionTime'] as String),
      pillCountBefore: map['pillCountBefore'] as int? ?? 0,
      pillCountAfter: map['pillCountAfter'] as int? ?? 0,
      notes: map['notes'] as String?,
    );
  }

  // ==========================================================
  // copyWith
  // ==========================================================
  MedicineLog copyWith({
    int? id,
    String? userId,
    int? medicineId,
    String? medicineName,
    int? categoryId,
    String? actionType,
    int? doseNumber,
    String? scheduledTime,
    DateTime? actionTime,
    int? pillCountBefore,
    int? pillCountAfter,
    String? notes,
  }) {
    return MedicineLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      categoryId: categoryId ?? this.categoryId,
      actionType: actionType ?? this.actionType,
      doseNumber: doseNumber ?? this.doseNumber,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actionTime: actionTime ?? this.actionTime,
      pillCountBefore: pillCountBefore ?? this.pillCountBefore,
      pillCountAfter: pillCountAfter ?? this.pillCountAfter,
      notes: notes ?? this.notes,
    );
  }

  // ==========================================================
  // دوال مساعدة
  // ==========================================================

  /// هل الحدث هو تناول؟
  bool get isTaken => actionType == 'taken';

  /// هل الحدث هو تعبئة؟
  bool get isRefill => actionType == 'refill';

  /// نص وصفي للحدث
  String get actionTypeText {
    if (actionType == 'taken') {
      if (doseNumber == 1) return 'first_dose';
      if (doseNumber == 2) return 'second_dose';
      if (doseNumber == 3) return 'third_dose';
      return 'taken_dose';
    } else if (actionType == 'refill') {
      return 'refilled';
    }
    return actionType;
  }

  /// كمية التغيير (موجب = إضافة، سالب = إنقاص)
  int get changeAmount => pillCountAfter - pillCountBefore;

  /// وقت الحدث منسق
  String get formattedTime {
    final h = actionTime.hour.toString().padLeft(2, '0');
    final m = actionTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// تاريخ الحدث منسق
  String get formattedDate {
    final d = actionTime.day.toString().padLeft(2, '0');
    final mo = actionTime.month.toString().padLeft(2, '0');
    final y = actionTime.year.toString();
    return '$y/$mo/$d';
  }

  /// تاريخ ووقت الحدث
  String get formattedDateTime => '$formattedDate $formattedTime';
}