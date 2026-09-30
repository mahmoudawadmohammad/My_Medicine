// ============================================================
// ملف: category.dart
// المسار: lib/models/category.dart
// الوصف: نموذج بيانات التصنيف (Category)
//         ✅ يدعم عزل البيانات لكل مستخدم (userId)
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';

// 📂 Category: نموذج بيانات يمثل تصنيفاً واحداً
class Category {
  // ==========================================================
  // خصائص التصنيف الأساسية
  // ==========================================================

  int? id;

  /// ✅ معرف المستخدم المالك لهذا التصنيف
  String? userId;

  String name;
  int colorValue;
  int iconCode;
  DateTime createdAt;

  // ==========================================================
  // Constructor
  // ==========================================================
  Category({
    this.id,
    this.userId,                  // ✅ جديد
    required this.name,
    required this.colorValue,
    required this.iconCode,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ==========================================================
  // toMap
  // ==========================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,           // ✅ جديد
      'name': name,
      'colorValue': colorValue,
      'iconCode': iconCode,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ==========================================================
  // fromMap
  // ==========================================================
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      userId: map['userId'] as String?,   // ✅ جديد
      name: map['name'] as String,
      colorValue: map['colorValue'] as int? ?? 0xFF1B7B6E,
      iconCode: map['iconCode'] as int? ?? 0xe1d5,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  // ==========================================================
  // copyWith
  // ==========================================================
  Category copyWith({
    int? id,
    String? userId,               // ✅ جديد
    String? name,
    int? colorValue,
    int? iconCode,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,   // ✅ جديد
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ==========================================================
  // دوال مساعدة للعرض (بدون تغيير)
  // ==========================================================

  Color get color => Color(colorValue);

  IconData get icon => IconData(
    iconCode,
    fontFamily: 'MaterialIcons',
  );

  String get formattedDate {
    final String day = createdAt.day.toString().padLeft(2, '0');
    final String month = createdAt.month.toString().padLeft(2, '0');
    final String year = createdAt.year.toString();
    return '$day/$month/$year';
  }
}