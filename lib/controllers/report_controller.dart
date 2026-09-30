// ============================================================
// ملف: report_controller.dart
// المسار: lib/controllers/report_controller.dart
// الوصف: متحكم التقارير - يحسب الإحصائيات ويعرضها
//         ✅ يدعم عزل البيانات لكل مستخدم (userId)
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/medicine.dart';
import '../models/medicine_log.dart';
import '../core/database/database_helper.dart';
import '../services/auth_service.dart';

// 📊 ReportPeriod: فترات التقرير
enum ReportPeriod {
  today,      // اليوم
  week,       // آخر 7 أيام
  month,      // آخر 30 يوم
  all,        // كل الوقت
}

class ReportController extends GetxController {
  // ==========================================================
  // المراجع
  // ==========================================================

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = Get.find<AuthService>();

  // ==========================================================
  // المتغيرات التفاعلية
  // ==========================================================

  /// الفترة المختارة حالياً
  final Rx<ReportPeriod> _selectedPeriod = ReportPeriod.week.obs;

  /// حالة التحميل
  final RxBool _isLoading = false.obs;

  /// إجمالي الحبات المتناولة في الفترة
  final RxInt _totalPillsTaken = 0.obs;

  /// عدد مرات التناول في الفترة
  final RxInt _totalTakenCount = 0.obs;

  /// عدد مرات التعبئة في الفترة
  final RxInt _totalRefillCount = 0.obs;

  /// عدد الأيام في الفترة (للحساب)
  final RxInt _daysInPeriod = 0.obs;

  /// إحصائيات لكل دواء (medicineId → count)
  final RxMap<int, int> _takenByMedicine = <int, int>{}.obs;

  /// إحصائيات يومية (date → count) - للرسم البياني
  final RxMap<String, int> _dailyTakenCount = <String, int>{}.obs;

  /// قائمة كل السجلات في الفترة
  final RxList<MedicineLog> _allLogs = <MedicineLog>[].obs;

  /// قائمة الأدوية (للأسماء والألوان)
  final RxList<Medicine> _medicines = <Medicine>[].obs;

  // ==========================================================
  // Getters
  // ==========================================================

  ReportPeriod get selectedPeriod => _selectedPeriod.value;
  bool get isLoading => _isLoading.value;
  int get totalPillsTaken => _totalPillsTaken.value;
  int get totalTakenCount => _totalTakenCount.value;
  int get totalRefillCount => _totalRefillCount.value;
  int get daysInPeriod => _daysInPeriod.value;
  Map<int, int> get takenByMedicine => _takenByMedicine;
  Map<String, int> get dailyTakenCount => _dailyTakenCount;
  List<MedicineLog> get allLogs => _allLogs.toList();
  List<Medicine> get medicines => _medicines.toList();

  /// نسبة الالتزام (0.0 - 1.0)
  /// = عدد المرات المأخوذة / (عدد المرات المتوقعة)
  double get adherenceRate {
    if (_daysInPeriod.value == 0 || _medicines.isEmpty) return 0.0;

    // حساب العدد المتوقع من الجرعات
    int expectedDoses = 0;
    for (final med in _medicines.where((m) => m.isActive)) {
      expectedDoses += med.totalDosesCount * _daysInPeriod.value;
    }

    if (expectedDoses == 0) return 0.0;

    final taken = _totalTakenCount.value;
    final rate = taken / expectedDoses;
    return rate > 1.0 ? 1.0 : rate;
  }

  /// نسبة الالتزام كنص مئوي
  String get adherencePercentage {
    return '${(adherenceRate * 100).toStringAsFixed(1)}%';
  }

  /// متوسط الحبات في اليوم
  double get averagePillsPerDay {
    if (_daysInPeriod.value == 0) return 0.0;
    return _totalPillsTaken.value / _daysInPeriod.value;
  }

  /// أعلى دواء تم تناوله
  Medicine? get mostTakenMedicine {
    if (_takenByMedicine.isEmpty) return null;
    final maxEntry = _takenByMedicine.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
    );
    return _medicines.firstWhereOrNull((m) => m.id == maxEntry.key);
  }

  // ==========================================================
  // دورة الحياة
  // ==========================================================

  @override
  void onInit() {
    super.onInit();
    loadReport();
  }

  // ==========================================================
  // تغيير الفترة
  // ==========================================================

  Future<void> setPeriod(ReportPeriod period) async {
    if (_selectedPeriod.value == period) return;
    _selectedPeriod.value = period;
    await loadReport();
  }

  // ==========================================================
  // ✅ تحميل التقرير
  // ==========================================================

  Future<void> loadReport() async {
    final String? userId = _authService.userId;
    if (userId == null) {
      debugPrint('⚠️ لا يوجد مستخدم - لا يمكن تحميل التقرير');
      _clearData();
      return;
    }

    _isLoading.value = true;

    try {
      // 1️⃣ حساب تواريخ الفترة
      final DateTime now = DateTime.now();
      DateTime? fromDate;

      switch (_selectedPeriod.value) {
        case ReportPeriod.today:
          fromDate = DateTime(now.year, now.month, now.day);
          _daysInPeriod.value = 1;
          break;
        case ReportPeriod.week:
          fromDate = now.subtract(const Duration(days: 6));
          fromDate = DateTime(fromDate.year, fromDate.month, fromDate.day);
          _daysInPeriod.value = 7;
          break;
        case ReportPeriod.month:
          fromDate = now.subtract(const Duration(days: 29));
          fromDate = DateTime(fromDate.year, fromDate.month, fromDate.day);
          _daysInPeriod.value = 30;
          break;
        case ReportPeriod.all:
          fromDate = null;
          _daysInPeriod.value = 30; // افتراضي للحساب
          break;
      }

      // 2️⃣ جلب الأدوية (للأسماء والأيقونات)
      final medicines = await _dbHelper.getMedicines(userId);
      _medicines.assignAll(medicines);

      // 3️⃣ جلب كل السجلات
      final logs = await _dbHelper.getLogs(
        userId: userId,
        fromDate: fromDate,
      );
      _allLogs.assignAll(logs);

      // 4️⃣ حساب الإحصائيات
      _calculateStats(logs);

      debugPrint('✅ تم تحميل التقرير: ${logs.length} سجل');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل التقرير: $e');
      Get.snackbar(
        'error'.tr,
        'failed_load_report'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // ==========================================================
  // ✅ حساب الإحصائيات من السجلات
  // ==========================================================

  void _calculateStats(List<MedicineLog> logs) {
    int totalPills = 0;
    int takenCount = 0;
    int refillCount = 0;

    final Map<int, int> byMedicine = {};
    final Map<String, int> daily = {};

    for (final log in logs) {
      if (log.isTaken) {
        // ✅ عدد الحبات المتناولة
        totalPills += log.changeAmount.abs();

        takenCount++;

        // ✅ إحصائيات حسب الدواء
        byMedicine[log.medicineId] = (byMedicine[log.medicineId] ?? 0) + 1;

        // ✅ إحصائيات يومية
        final dayKey = _formatDayKey(log.actionTime);
        daily[dayKey] = (daily[dayKey] ?? 0) + 1;
      } else if (log.isRefill) {
        refillCount++;
      }
    }

    _totalPillsTaken.value = totalPills;
    _totalTakenCount.value = takenCount;
    _totalRefillCount.value = refillCount;
    _takenByMedicine.assignAll(byMedicine);
    _dailyTakenCount.assignAll(daily);
  }

  // ==========================================================
  // ✅ تنسيق التاريخ كمفتاح (YYYY-MM-DD)
  // ==========================================================

  String _formatDayKey(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ==========================================================
  // ✅ الحصول على اسم الفترة
  // ==========================================================

  String get periodText {
    switch (_selectedPeriod.value) {
      case ReportPeriod.today:
        return 'today'.tr;
      case ReportPeriod.week:
        return 'last_7_days'.tr;
      case ReportPeriod.month:
        return 'last_30_days'.tr;
      case ReportPeriod.all:
        return 'all_time'.tr;
    }
  }

  // ==========================================================
  // ✅ سجلات دواء معين
  // ==========================================================

  Future<List<MedicineLog>> getLogsForMedicine(int medicineId) async {
    final String? userId = _authService.userId;
    if (userId == null) return [];

    try {
      return await _dbHelper.getLogs(
        userId: userId,
        medicineId: medicineId,
      );
    } catch (e) {
      debugPrint('❌ خطأ: $e');
      return [];
    }
  }

  // ==========================================================
  // ✅ مسح البيانات
  // ==========================================================

  void _clearData() {
    _totalPillsTaken.value = 0;
    _totalTakenCount.value = 0;
    _totalRefillCount.value = 0;
    _takenByMedicine.clear();
    _dailyTakenCount.clear();
    _allLogs.clear();
    _medicines.clear();
  }

  // ==========================================================
  // ✅ إعادة تحميل
  // ==========================================================

  Future<void> refresh() async {
    await loadReport();
  }
}