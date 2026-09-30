// ============================================================
// ملف: database_helper.dart
// المسار: lib/core/database/database_helper.dart
// الوصف: إدارة قاعدة بيانات SQLite
//         يحتوي على جدولين: categories و medicines
//         ✅ يدعم عزل البيانات لكل مستخدم (userId)
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/medicine.dart';
import '../../models/category.dart';
import '../../models/medicine_log.dart';

// 🗄️ DatabaseHelper: فئة Singleton لإدارة قاعدة البيانات
class DatabaseHelper {
  // ===== Singleton Pattern =====
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // ===== اسم قاعدة البيانات والإصدار =====
  static const String _databaseName = 'dawaei.db';
  static const int _databaseVersion = 11; // ✅ إصدار جديد (userId)

  // ===== أسماء الجداول =====
  static const String _tableCategories = 'categories';
  static const String _tableMedicines = 'medicines';
  static const String _tableLogs = 'medicine_logs';

  // ===== متغيرات قاعدة البيانات =====
  static Database? _database;

  // ==========================================================
  // ✅ Getter للحصول على قاعدة البيانات
  // ==========================================================
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ==========================================================
  // ✅ دالة تهيئة قاعدة البيانات
  // ==========================================================
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    debugPrint('📂 مسار قاعدة البيانات: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        debugPrint('✅ تم تفعيل Foreign Keys');
      },
    );
  }

  // ==========================================================
  // دالة إنشاء الجداول (للتركيب الجديد فقط)
  // ==========================================================
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🆕 إنشاء قاعدة بيانات جديدة - الإصدار $version');

    // ✅ جدول التصنيفات مع userId
    await db.execute('''
      CREATE TABLE $_tableCategories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        iconCode INTEGER NOT NULL,
        createdAt TEXT
      )
    ''');

    // ✅ جدول الأدوية مع userId
    await db.execute('''
      CREATE TABLE $_tableMedicines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        pillCount INTEGER NOT NULL DEFAULT 0,
        categoryId INTEGER,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        hour2 INTEGER,
        minute2 INTEGER,
        hour3 INTEGER,
        minute3 INTEGER,
        isActive INTEGER NOT NULL DEFAULT 1,
        lastProcessedDate TEXT,
        lastRefillDate TEXT,
        selectedDays TEXT,
        processedTimes TEXT,
        FOREIGN KEY (categoryId) REFERENCES $_tableCategories (id) ON DELETE CASCADE
      )
    ''');
    // ✅ جدول سجلات الأدوية
    await db.execute('''
  CREATE TABLE $_tableLogs(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId TEXT NOT NULL,
    medicineId INTEGER NOT NULL,
    medicineName TEXT NOT NULL,
    categoryId INTEGER,
    actionType TEXT NOT NULL,
    doseNumber INTEGER,
    scheduledTime TEXT,
    actionTime TEXT NOT NULL,
    pillCountBefore INTEGER NOT NULL DEFAULT 0,
    pillCountAfter INTEGER NOT NULL DEFAULT 0,
    notes TEXT
  )
''');

// ✅ فهرس على userId (للفلترة السريعة)
    await db.execute('CREATE INDEX idx_logs_user_id ON $_tableLogs(userId)');
// ✅ فهرس على medicineId (للتقارير لكل دواء)
    await db.execute('CREATE INDEX idx_logs_medicine_id ON $_tableLogs(medicineId)');
// ✅ فهرس على actionTime (للفلترة بالتاريخ)
    await db.execute('CREATE INDEX idx_logs_action_time ON $_tableLogs(actionTime)');

    // ===== الفهارس =====
    await db.execute('CREATE INDEX idx_category_id ON $_tableMedicines(categoryId)');
    await db.execute('CREATE INDEX idx_is_active ON $_tableMedicines(isActive)');
    await db.execute('CREATE INDEX idx_user_id_medicine ON $_tableMedicines(userId)');
    await db.execute('CREATE INDEX idx_user_id_category ON $_tableCategories(userId)');

    debugPrint('✅ تم إنشاء قاعدة البيانات بنجاح');
  }

  // ==========================================================
  // ✅ دالة ترقية قاعدة البيانات
  // ==========================================================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 ترقية قاعدة البيانات من $oldVersion إلى $newVersion');

    // ==========================================================
    // الترقية إلى الإصدار 10: إضافة userId (إعادة هيكلة)
    // ==========================================================
    if (oldVersion < 11) {
      debugPrint('📦 ترقية v10: إعادة هيكلة كاملة مع userId');
      debugPrint('  ⚠️ سيتم حذف البيانات القديمة لعدم وجود userId');

      // حذف الجداول القديمة
      await db.execute('DROP TABLE IF EXISTS $_tableMedicines');
      await db.execute('DROP TABLE IF EXISTS $_tableCategories');

      // إنشاء الجداول الجديدة
      await db.execute('''
        CREATE TABLE $_tableCategories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          name TEXT NOT NULL,
          colorValue INTEGER NOT NULL,
          iconCode INTEGER NOT NULL,
          createdAt TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE $_tableMedicines(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          name TEXT NOT NULL,
          pillCount INTEGER NOT NULL DEFAULT 0,
          categoryId INTEGER,
          hour INTEGER NOT NULL,
          minute INTEGER NOT NULL,
          hour2 INTEGER,
          minute2 INTEGER,
          hour3 INTEGER,
          minute3 INTEGER,
          isActive INTEGER NOT NULL DEFAULT 1,
          lastProcessedDate TEXT,
          lastRefillDate TEXT,
          selectedDays TEXT,
          processedTimes TEXT,
          FOREIGN KEY (categoryId) REFERENCES $_tableCategories (id) ON DELETE CASCADE
        )
      ''');


      try {
        // ✅ إنشاء جدول السجلات (لا نحذف بيانات قديمة)
        await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableLogs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        medicineId INTEGER NOT NULL,
        medicineName TEXT NOT NULL,
        categoryId INTEGER,
        actionType TEXT NOT NULL,
        doseNumber INTEGER,
        scheduledTime TEXT,
        actionTime TEXT NOT NULL,
        pillCountBefore INTEGER NOT NULL DEFAULT 0,
        pillCountAfter INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');

        await db.execute('CREATE INDEX IF NOT EXISTS idx_logs_user_id ON $_tableLogs(userId)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_logs_medicine_id ON $_tableLogs(medicineId)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_logs_action_time ON $_tableLogs(actionTime)');

        debugPrint('  ✅ تم إضافة جدول medicine_logs');
      } catch (e) {
        debugPrint('  ⚠️ خطأ في إضافة الجدول: $e');
      }

      await db.execute('CREATE INDEX idx_category_id ON $_tableMedicines(categoryId)');
      await db.execute('CREATE INDEX idx_is_active ON $_tableMedicines(isActive)');
      await db.execute('CREATE INDEX idx_user_id_medicine ON $_tableMedicines(userId)');
      await db.execute('CREATE INDEX idx_user_id_category ON $_tableCategories(userId)');

      debugPrint('✅ تمت الترقية إلى v10 بنجاح');
    }
  }

  // ==========================================================
  // ✅ عمليات جدول التصنيفات (مع userId)
  // ==========================================================

  /// إضافة تصنيف جديد لمستخدم معين
  Future<int> insertCategory(Category category, String userId) async {
    final db = await database;
    final Map<String, dynamic> data = category.toMap();
    data['userId'] = userId; // ✅ إضافة userId
    return await db.insert(_tableCategories, data);
  }

  /// جلب تصنيفات مستخدم معين
  Future<List<Category>> getCategories(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableCategories,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  /// جلب تصنيف بالمعرف (مع التحقق من المستخدم)
  Future<Category?> getCategoryById(int id, String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableCategories,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  /// تحديث تصنيف (مع التحقق من المستخدم)
  Future<int> updateCategory(Category category, String userId) async {
    final db = await database;
    final Map<String, dynamic> data = category.toMap();
    data['userId'] = userId;
    return await db.update(
      _tableCategories,
      data,
      where: 'id = ? AND userId = ?',
      whereArgs: [category.id, userId],
    );
  }

  /// حذف تصنيف (مع التحقق من المستخدم)
  Future<int> deleteCategory(int id, String userId) async {
    final db = await database;
    return await db.delete(
      _tableCategories,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  // ==========================================================
  // ✅ عمليات جدول الأدوية (مع userId)
  // ==========================================================

  /// إضافة دواء جديد لمستخدم معين
  Future<int> insertMedicine(Medicine medicine, String userId) async {
    final db = await database;
    final Map<String, dynamic> data = medicine.toMap();
    data['userId'] = userId; // ✅ إضافة userId
    return await db.insert(_tableMedicines, data);
  }

  /// جلب أدوية مستخدم معين (مرتبة حسب الوقت)
  Future<List<Medicine>> getMedicines(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableMedicines,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: '''
        COALESCE(hour, 24) ASC, 
        COALESCE(minute, 60) ASC
      ''',
    );
    return List.generate(maps.length, (i) => Medicine.fromMap(maps[i]));
  }

  /// جلب الأدوية النشطة لمستخدم معين
  Future<List<Medicine>> getActiveMedicines(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableMedicines,
      where: 'isActive = 1 AND userId = ?',
      whereArgs: [userId],
      orderBy: 'hour ASC, minute ASC',
    );
    return List.generate(maps.length, (i) => Medicine.fromMap(maps[i]));
  }

  /// جلب أدوية تصنيف معين (مع التحقق من المستخدم)
  Future<List<Medicine>> getMedicinesByCategory(int categoryId, String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableMedicines,
      where: 'categoryId = ? AND userId = ?',
      whereArgs: [categoryId, userId],
      orderBy: 'hour ASC, minute ASC',
    );
    return List.generate(maps.length, (i) => Medicine.fromMap(maps[i]));
  }

  /// جلب الأدوية بدون تصنيف لمستخدم معين
  Future<List<Medicine>> getUncategorizedMedicines(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableMedicines,
      where: 'categoryId IS NULL AND userId = ?',
      whereArgs: [userId],
      orderBy: 'hour ASC, minute ASC',
    );
    return List.generate(maps.length, (i) => Medicine.fromMap(maps[i]));
  }

  /// تحديث دواء (مع التحقق من المستخدم)
  Future<int> updateMedicine(Medicine medicine, String userId) async {
    final db = await database;
    final Map<String, dynamic> data = medicine.toMap();
    data['userId'] = userId;
    return await db.update(
      _tableMedicines,
      data,
      where: 'id = ? AND userId = ?',
      whereArgs: [medicine.id, userId],
    );
  }

  /// حذف دواء (مع التحقق من المستخدم)
  Future<int> deleteMedicine(int id, String userId) async {
    final db = await database;
    return await db.delete(
      _tableMedicines,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  /// حذف أدوية تصنيف معين (مع التحقق من المستخدم)
  Future<int> deleteMedicinesByCategory(int categoryId, String userId) async {
    final db = await database;
    return await db.delete(
      _tableMedicines,
      where: 'categoryId = ? AND userId = ?',
      whereArgs: [categoryId, userId],
    );
  }

  /// ✅ حذف جميع أدوية مستخدم معين
  Future<int> deleteAllMedicines(String userId) async {
    final db = await database;
    return await db.delete(
      _tableMedicines,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  /// ✅ حذف جميع تصنيفات مستخدم معين
  Future<int> deleteAllCategories(String userId) async {
    final db = await database;
    return await db.delete(
      _tableCategories,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  /// ✅ حذف كل بيانات مستخدم معين (أدوية + تصنيفات)
  Future<void> deleteAllUserData(String userId) async {
    final db = await database;
    await db.delete(_tableMedicines, where: 'userId = ?', whereArgs: [userId]);
    await db.delete(_tableCategories, where: 'userId = ?', whereArgs: [userId]);
    await db.delete(_tableLogs, where: 'userId = ?', whereArgs: [userId]);
    debugPrint('🗑️ تم حذف جميع بيانات المستخدم: $userId');
  }

  // ==========================================================
  // ✅ دوال إحصائية (مع userId)
  // ==========================================================

  /// عدد الأدوية في تصنيف معين
  Future<int> getMedicinesCountByCategory(int categoryId, String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableMedicines WHERE categoryId = ? AND userId = ?',
      [categoryId, userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// عدد الأدوية غير المصنفة
  Future<int> getUncategorizedCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableMedicines WHERE categoryId IS NULL AND userId = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// إجمالي عدد الحبات النشطة
  Future<int> getTotalPillCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(pillCount) as total FROM $_tableMedicines WHERE isActive = 1 AND userId = ?',
      [userId],
    );
    return result.first['total'] as int? ?? 0;
  }

  /// إجمالي عدد الأدوية
  Future<int> getTotalMedicinesCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableMedicines WHERE userId = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==========================================================
  // ✅ دوال تشخيصية
  // ==========================================================

  /// حذف كل شيء (للتشخيص فقط!)
  Future<void> deleteAll() async {
    final db = await database;
    await db.delete(_tableMedicines);
    await db.delete(_tableCategories);
    await db.delete(_tableLogs);
    debugPrint('🗑️ تم حذف جميع البيانات');
  }

  // ==========================================================
// ✅ عمليات جدول السجلات (Medicine Logs)
// ==========================================================

  /// إضافة سجل جديد
  Future<int> insertLog(MedicineLog log) async {
    final db = await database;
    return await db.insert(_tableLogs, log.toMap());
  }

  /// جلب سجلات مستخدم معين (مع فلترة اختيارية)
  Future<List<MedicineLog>> getLogs({
    required String userId,
    DateTime? fromDate,
    DateTime? toDate,
    int? medicineId,
    String? actionType,
  }) async {
    final db = await database;

    // ✅ بناء شرط WHERE ديناميكياً
    final List<String> conditions = ['userId = ?'];
    final List<dynamic> args = [userId];

    if (fromDate != null) {
      conditions.add('actionTime >= ?');
      args.add(fromDate.toIso8601String());
    }

    if (toDate != null) {
      conditions.add('actionTime <= ?');
      args.add(toDate.toIso8601String());
    }

    if (medicineId != null) {
      conditions.add('medicineId = ?');
      args.add(medicineId);
    }

    if (actionType != null) {
      conditions.add('actionType = ?');
      args.add(actionType);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _tableLogs,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'actionTime DESC',
    );

    return List.generate(maps.length, (i) => MedicineLog.fromMap(maps[i]));
  }

  /// عدد سجلات "تناول" في فترة معينة
  Future<int> getTakenCount({
    required String userId,
    DateTime? fromDate,
    DateTime? toDate,
    int? medicineId,
  }) async {
    final db = await database;

    final List<String> conditions = ["userId = ?", "actionType = 'taken'"];
    final List<dynamic> args = [userId];

    if (fromDate != null) {
      conditions.add('actionTime >= ?');
      args.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      conditions.add('actionTime <= ?');
      args.add(toDate.toIso8601String());
    }
    if (medicineId != null) {
      conditions.add('medicineId = ?');
      args.add(medicineId);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableLogs WHERE ${conditions.join(' AND ')}',
      args,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// إجمالي الحبات المتناولة في فترة
  Future<int> getTotalTakenPills({
    required String userId,
    DateTime? fromDate,
    DateTime? toDate,
    int? medicineId,
  }) async {
    final db = await database;

    final List<String> conditions = ["userId = ?", "actionType = 'taken'"];
    final List<dynamic> args = [userId];

    if (fromDate != null) {
      conditions.add('actionTime >= ?');
      args.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      conditions.add('actionTime <= ?');
      args.add(toDate.toIso8601String());
    }
    if (medicineId != null) {
      conditions.add('medicineId = ?');
      args.add(medicineId);
    }

    // المجموع = SUM(pillCountBefore - pillCountAfter) للأحداث 'taken'
    final result = await db.rawQuery(
      'SELECT SUM(pillCountBefore - pillCountAfter) as total FROM $_tableLogs WHERE ${conditions.join(' AND ')}',
      args,
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// إحصائيات لكل دواء (عدد المرات)
  Future<Map<int, int>> getTakenCountByMedicine({
    required String userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await database;

    final List<String> conditions = ["userId = ?", "actionType = 'taken'"];
    final List<dynamic> args = [userId];

    if (fromDate != null) {
      conditions.add('actionTime >= ?');
      args.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      conditions.add('actionTime <= ?');
      args.add(toDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT medicineId, COUNT(*) as count FROM $_tableLogs WHERE ${conditions.join(' AND ')} GROUP BY medicineId',
      args,
    );

    final Map<int, int> map = {};
    for (final row in result) {
      final medId = row['medicineId'] as int;
      final count = row['count'] as int;
      map[medId] = count;
    }
    return map;
  }

  /// إحصائيات يومية (للرسم البياني)
  Future<Map<String, int>> getDailyTakenCount({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT 
      substr(actionTime, 1, 10) as day,
      COUNT(*) as count
    FROM $_tableLogs
    WHERE userId = ? 
      AND actionType = 'taken'
      AND actionTime >= ?
      AND actionTime <= ?
    GROUP BY substr(actionTime, 1, 10)
    ORDER BY day ASC
    ''',
      [userId, fromDate.toIso8601String(), toDate.toIso8601String()],
    );

    final Map<String, int> map = {};
    for (final row in result) {
      map[row['day'] as String] = row['count'] as int;
    }
    return map;
  }

  /// حذف سجلات قديمة (للصيانة)
  Future<int> deleteOldLogs({
    required String userId,
    required int daysToKeep,
  }) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    return await db.delete(
      _tableLogs,
      where: 'userId = ? AND actionTime < ?',
      whereArgs: [userId, cutoffDate.toIso8601String()],
    );
  }

  /// حذف جميع سجلات مستخدم (عند حذف الحساب)
  Future<int> deleteAllUserLogs(String userId) async {
    final db = await database;
    return await db.delete(
      _tableLogs,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  /// إغلاق قاعدة البيانات
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('🔒 تم إغلاق قاعدة البيانات');
    }
  }
}