// ============================================================
// ملف: medicine_controller.dart
// المسار: lib/controllers/medicine_controller.dart
// الوصف: متحكم الأدوية - يدعم عزل البيانات + تسجيل الأحداث
//         ✅ تم إصلاح مشكلة التكرار (حبتين بدل حبة)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/medicine.dart';
import '../models/medicine_log.dart';
import '../core/database/database_helper.dart';
import '../core/utils/notification_helper.dart';
import '../services/auth_service.dart';

class MedicineController extends GetxController {
  // ==========================================================
  // المراجع
  // ==========================================================

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationHelper _notificationHelper = NotificationHelper();
  final AuthService _authService = Get.find<AuthService>();

  Timer? _timer;
  Worker? _authWorker;

  // ✅✅✅ قائمة لتتبع الجرعات قيد المعالجة (لمنع التكرار)
  final Set<String> _processingDoses = <String>{};

  // ==========================================================
  // المتغيرات التفاعلية
  // ==========================================================

  final RxList<Medicine> _medicines = <Medicine>[].obs;
  final RxBool _isLoading = false.obs;
  final RxInt _totalPills = 0.obs;

  // ==========================================================
  // Getters
  // ==========================================================

  List<Medicine> get medicines => _medicines.toList();
  bool get isLoading => _isLoading.value;
  int get totalPills => _totalPills.value;
  int get medicinesCount => _medicines.length;

  // ==========================================================
  // دورة الحياة
  // ==========================================================

  @override
  void onInit() {
    super.onInit();

    _authWorker = ever(_authService.userRx, (user) {
      if (user != null) {
        debugPrint('👤 تغير المستخدم → إعادة تحميل الأدوية');
        _loadMedicines();
      } else {
        _medicines.clear();
        _totalPills.value = 0;
        debugPrint('🚪 تسجيل خروج → مسح القائمة');
      }
    });

    if (_authService.userId != null) {
      _loadMedicines();
    }

    _startScheduleChecker();
  }

  @override
  void onClose() {
    _timer?.cancel();
    _authWorker?.dispose();
    super.onClose();
  }

  // ==========================================================
  // بدء الفحص الدوري
  // ==========================================================

  void _startScheduleChecker() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 60),
          (timer) => _checkDueMedicines(),
    );
    debugPrint('✅ تم بدء الفحص الدوري (كل 60 ثانية)');
  }

  // ==========================================================
  // تحميل البيانات
  // ==========================================================

  Future<void> _loadMedicines() async {
    final String? userId = _authService.userId;
    if (userId == null) {
      debugPrint('⚠️ لا يوجد مستخدم مسجل - تخطي تحميل الأدوية');
      _medicines.clear();
      _totalPills.value = 0;
      return;
    }

    _isLoading.value = true;

    try {
      final medicines = await _dbHelper.getMedicines(userId);
      _medicines.assignAll(medicines);

      _updateTotalPills();
      _checkDueMedicines();

      debugPrint('✅ تم تحميل ${medicines.length} دواء للمستخدم $userId');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الأدوية: $e');
      Get.snackbar(
        'error'.tr,
        'failed_load_medicines'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _updateTotalPills() {
    int total = 0;
    for (var med in _medicines.where((m) => m.isActive)) {
      total += med.pillCount;
    }
    _totalPills.value = total;
  }

  // ==========================================================
  // ✅ فحص الأدوية المستحقة (معدل - بدون تكرار)
  // ==========================================================

  void _checkDueMedicines() {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final today = DateTime.now();

    for (var med in _medicines.where((m) => m.isActive)) {
      if (!med.isScheduledForToday(dateTime: today)) continue;
      if (med.pillCount <= 0) continue;

      final List<Map<String, dynamic>> allTimes = [
        {'time': med.time, 'number': 1},
      ];
      if (med.time2 != null) {
        allTimes.add({'time': med.time2!, 'number': 2});
      }
      if (med.time3 != null) {
        allTimes.add({'time': med.time3!, 'number': 3});
      }

      for (final timeData in allTimes) {
        final TimeOfDay medTime = timeData['time'];
        final int doseNumber = timeData['number'];
        final int medMinutes = medTime.hour * 60 + medTime.minute;
        final int diff = (medMinutes - nowMinutes).abs();

        if (diff == 0) {
          // ✅ التحقق من القائمة المحلية
          if (med.wasTimeProcessedToday(doseNumber)) continue;

          // ✅✅✅ التحقق الإضافي: هل هذه الجرعة قيد المعالجة؟
          final doseKey = '${med.id}_$doseNumber';
          if (_processingDoses.contains(doseKey)) {
            debugPrint('⏭️ الجرعة $doseNumber للدواء ${med.name} قيد المعالجة - تخطي');
            continue;
          }

          // ✅✅✅ معالجة الجرعة (مع قراءة من قاعدة البيانات)
          _processMedicineDose(med, doseNumber);
          break;
        }
      }
    }
  }

  // ==========================================================
  // ✅ معالجة جرعة (مع قراءة من قاعدة البيانات لمنع التكرار)
  // ==========================================================

  Future<void> _processMedicineDose(Medicine medicine, int doseNumber) async {
    final String? userId = _authService.userId;
    if (userId == null) return;

    // ✅✅✅ مفتاح فريد للجرعة
    final String doseKey = '${medicine.id}_$doseNumber';

    // ✅✅✅ التحقق: هل الجرعة قيد المعالجة؟
    if (_processingDoses.contains(doseKey)) {
      debugPrint('⏭️ الجرعة $doseNumber قيد المعالجة - تخطي');
      return;
    }

    // ✅✅✅ إضافة الجرعة لقائمة المعالجة
    _processingDoses.add(doseKey);
    debugPrint('🔒 تم قفل الجرعة $doseKey');

    try {
      if (!medicine.isScheduledForToday()) {
        debugPrint('⏭️ الدواء ${medicine.name} غير مجدول اليوم');
        return;
      }

      // ✅✅✅ قراءة الدواء من قاعدة البيانات (للتأكد من الحالة الحالية)
      debugPrint('🔍 قراءة الدواء ${medicine.name} من قاعدة البيانات...');
      final freshMedicines = await _dbHelper.getMedicines(userId);
      final freshMedicine = freshMedicines.firstWhereOrNull(
            (m) => m.id == medicine.id,
      );

      if (freshMedicine == null) {
        debugPrint('❌ الدواء غير موجود في القاعدة');
        return;
      }

      // ✅✅✅ التحقق: هل WorkManager عالج الجرعة بالفعل؟
      if (freshMedicine.wasTimeProcessedToday(doseNumber)) {
        debugPrint('✅ الجرعة $doseNumber معالجة بالفعل (من WorkManager) - تخطي');

        // ✅ تحديث القائمة المحلية من القاعدة
        final index = _medicines.indexWhere((m) => m.id == medicine.id);
        if (index != -1) {
          _medicines[index] = freshMedicine;
          _medicines.refresh();
        }
        _updateTotalPills();
        return;
      }

      // ✅✅✅ التحقق من وجود حبات
      if (freshMedicine.pillCount <= 0) {
        debugPrint('⚠️ لا توجد حبات في ${freshMedicine.name}');
        return;
      }

      debugPrint('✅ يمكن معالجة الجرعة $doseNumber - جاري التنفيذ...');

      // ✅ حفظ عدد الحبات قبل
      final int pillCountBefore = freshMedicine.pillCount;

      // ✅ إنقاص حبة + تسجيل الوقت
      final updatedAfterTake = freshMedicine.takeOnePill();
      final updatedAfterProcess =
      updatedAfterTake.markTimeAsProcessed(doseNumber);

      // ✅ تحديث قاعدة البيانات
      await _dbHelper.updateMedicine(updatedAfterProcess, userId);

      // ✅ تحديث القائمة المحلية
      final index = _medicines.indexWhere((m) => m.id == medicine.id);
      if (index != -1) {
        _medicines[index] = updatedAfterProcess;
        _medicines.refresh();
      }

      _updateTotalPills();

      // ✅ تسجيل الحدث
      await _logTaken(
        userId: userId,
        medicine: freshMedicine,
        doseNumber: doseNumber,
        pillCountBefore: pillCountBefore,
        pillCountAfter: updatedAfterProcess.pillCount,
      );

      debugPrint('✅ تمت معالجة الجرعة $doseNumber من ${freshMedicine.name}');
      debugPrint('📊 الحبات: $pillCountBefore → ${updatedAfterProcess.pillCount}');

      // ✅ إذا نفذت الحبات
      if (updatedAfterProcess.pillCount == 0) {
        _notificationHelper.showLowStockNotification(
          updatedAfterProcess,
          isEmpty: true,
        );
        Get.snackbar(
          'warning_alert'.tr,
          '${'pills_run_out'.tr} ${freshMedicine.name}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة الجرعة: $e');
    } finally {
      // ✅✅✅ إزالة الجرعة من قائمة المعالجة (بعد 5 ثواني)
      // ننتظر قليلاً لمنع التكرار في نفس الدقيقة
      Future.delayed(const Duration(seconds: 5), () {
        _processingDoses.remove(doseKey);
        debugPrint('🔓 تم فتح الجرعة $doseKey');
      });
    }
  }

  // ==========================================================
  // دالة مساعدة: تسجيل حدث "تناول"
  // ==========================================================

  Future<void> _logTaken({
    required String userId,
    required Medicine medicine,
    required int doseNumber,
    required int pillCountBefore,
    required int pillCountAfter,
  }) async {
    try {
      String? scheduledTime;
      if (doseNumber == 1) {
        scheduledTime = _formatTimeOfDay(medicine.time);
      } else if (doseNumber == 2 && medicine.time2 != null) {
        scheduledTime = _formatTimeOfDay(medicine.time2!);
      } else if (doseNumber == 3 && medicine.time3 != null) {
        scheduledTime = _formatTimeOfDay(medicine.time3!);
      }

      final log = MedicineLog(
        userId: userId,
        medicineId: medicine.id!,
        medicineName: medicine.name,
        categoryId: medicine.categoryId,
        actionType: 'taken',
        doseNumber: doseNumber,
        scheduledTime: scheduledTime,
        actionTime: DateTime.now(),
        pillCountBefore: pillCountBefore,
        pillCountAfter: pillCountAfter,
      );

      await _dbHelper.insertLog(log);
      debugPrint('📝 تم تسجيل: taken (${medicine.name} - جرعة $doseNumber)');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل الحدث: $e');
    }
  }

  // ==========================================================
  // دالة مساعدة: تسجيل حدث "تعبئة"
  // ==========================================================

  Future<void> _logRefill({
    required String userId,
    required Medicine medicine,
    required int addedPills,
    required int pillCountBefore,
    required int pillCountAfter,
  }) async {
    try {
      final log = MedicineLog(
        userId: userId,
        medicineId: medicine.id!,
        medicineName: medicine.name,
        categoryId: medicine.categoryId,
        actionType: 'refill',
        actionTime: DateTime.now(),
        pillCountBefore: pillCountBefore,
        pillCountAfter: pillCountAfter,
        notes: 'أُضيف $addedPills حبة',
      );

      await _dbHelper.insertLog(log);
      debugPrint('📝 تم تسجيل: refill (${medicine.name} - +$addedPills)');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل التعبئة: $e');
    }
  }

  // ==========================================================
  // دالة مساعدة: تنسيق TimeOfDay إلى نص
  // ==========================================================

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ==========================================================
  // إضافة دواء
  // ==========================================================

  Future<bool> addMedicine(Medicine medicine) async {
    final String? userId = _authService.userId;
    if (userId == null) {
      Get.snackbar('error'.tr, 'not_logged_in'.tr);
      return false;
    }

    if (medicine.pillCount < 1) {
      Get.snackbar('error'.tr, 'min_one_pill'.tr);
      return false;
    }

    try {
      medicine.userId = userId;
      final newId = await _dbHelper.insertMedicine(medicine, userId);
      medicine.id = newId;

      await _scheduleNotifications(medicine);
      await _loadMedicines();

      Get.snackbar(
        'success'.tr,
        '${'added_successfully'.tr} ${medicine.name} ${'successfully'.tr}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar('${'error'.tr} ❌', '${'failed_add_medicine'.tr} $e');
      return false;
    }
  }

  // ==========================================================
  // جدولة الإشعارات
  // ==========================================================

  Future<void> _scheduleNotifications(Medicine medicine) async {
    if (medicine.id == null) return;

    await _notificationHelper.scheduleMedicineNotificationWithWorkManager(
      medicine: medicine,
      doseTime: medicine.time,
      doseNumber: 1,
    );

    if (medicine.time2 != null) {
      await _notificationHelper.scheduleMedicineNotificationWithWorkManager(
        medicine: medicine,
        doseTime: medicine.time2!,
        doseNumber: 2,
      );
    }

    if (medicine.time3 != null) {
      await _notificationHelper.scheduleMedicineNotificationWithWorkManager(
        medicine: medicine,
        doseTime: medicine.time3!,
        doseNumber: 3,
      );
    }

    debugPrint('✅ تمت جدولة إشعارات ${medicine.name}');
  }

  // ==========================================================
  // حذف دواء
  // ==========================================================

  Future<void> deleteMedicine(int id) async {
    final String? userId = _authService.userId;
    if (userId == null) return;

    try {
      await _notificationHelper.cancelAllScheduledForMedicine(id);
      await _dbHelper.deleteMedicine(id, userId);
      await _loadMedicines();
      Get.snackbar('deleted_success'.tr, 'delete_success'.tr);
    } catch (e) {
      Get.snackbar('${'error'.tr} ❌', 'failed_delete_medicine'.tr);
    }
  }

  // ==========================================================
  // إعادة تعبئة (مع تسجيل الحدث)
  // ==========================================================

  Future<bool> refillMedicine(int medicineId, int additionalPills) async {
    final String? userId = _authService.userId;
    if (userId == null) return false;

    try {
      final medicine = _medicines.firstWhere((m) => m.id == medicineId);

      final int pillCountBefore = medicine.pillCount;

      final updatedMedicine = medicine.refill(additionalPills);

      await _dbHelper.updateMedicine(updatedMedicine, userId);
      await _loadMedicines();

      await _logRefill(
        userId: userId,
        medicine: medicine,
        addedPills: additionalPills,
        pillCountBefore: pillCountBefore,
        pillCountAfter: updatedMedicine.pillCount,
      );

      _notificationHelper.showRefillSuccessNotification(
        medicineName: medicine.name,
        addedPills: additionalPills,
        newTotal: updatedMedicine.pillCount,
      );

      Get.snackbar(
        'refill_done'.tr,
        '${'added_successfully'.tr} $additionalPills ${'pills_to'.tr} ${medicine.name}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar('${'error'.tr} ❌', 'failed_refill'.tr);
      return false;
    }
  }

  // ==========================================================
  // تناول حبة يدوياً (مع تسجيل الحدث)
  // ==========================================================

  Future<void> takePillManually(int medicineId) async {
    final String? userId = _authService.userId;
    if (userId == null) return;

    try {
      final medicine = _medicines.firstWhere((m) => m.id == medicineId);

      if (medicine.pillCount <= 0) {
        Get.snackbar('warning_alert'.tr, 'no_pills_left'.tr);
        return;
      }

      final isOnTime = medicine.isExactTimeNow();
      final currentDose = medicine.getCurrentDoseNumber();

      final int pillCountBefore = medicine.pillCount;

      final updatedMedicine = medicine.takeOnePill();

      await _dbHelper.updateMedicine(updatedMedicine, userId);

      if (currentDose > 0) {
        final marked = updatedMedicine.markTimeAsProcessed(currentDose);
        await _dbHelper.updateMedicine(marked, userId);
      }

      await _loadMedicines();

      final int doseToLog = currentDose > 0 ? currentDose : 1;

      await _logTaken(
        userId: userId,
        medicine: medicine,
        doseNumber: doseToLog,
        pillCountBefore: pillCountBefore,
        pillCountAfter: updatedMedicine.pillCount,
      );

      if (!isOnTime) {
        await _notificationHelper.showManualTakeNotification(
          medicineName: medicine.name,
          remainingPills: updatedMedicine.pillCount,
          scheduledTime: medicine.time,
        );
      }

      Get.snackbar(
        'taken_success'.tr,
        '${'took_pill_from'.tr} ${medicine.name}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ خطأ: $e');
    }
  }

  // ==========================================================
  // تبديل النشاط
  // ==========================================================

  Future<void> toggleMedicineActive(int id) async {
    final String? userId = _authService.userId;
    if (userId == null) return;

    try {
      final medicine = _medicines.firstWhere((m) => m.id == id);
      final updated = medicine.copyWith(isActive: !medicine.isActive);

      await _dbHelper.updateMedicine(updated, userId);

      if (!updated.isActive) {
        await _notificationHelper.cancelAllScheduledForMedicine(id);
        debugPrint('🔕 تم إلغاء إشعارات ${updated.name}');
      } else {
        await _scheduleNotifications(updated);
        debugPrint('🔔 تم إعادة جدولة إشعارات ${updated.name}');
      }

      await _loadMedicines();
    } catch (e) {
      debugPrint('❌ خطأ: $e');
    }
  }

  // ==========================================================
  // إعادة تحميل
  // ==========================================================

  Future<void> refreshMedicines() async {
    await _loadMedicines();
  }

  // ==========================================================
  // الفلترة حسب التصنيف
  // ==========================================================

  List<Medicine> getMedicinesByCategory(int? categoryId) {
    if (categoryId == null) {
      return _medicines.where((m) => m.categoryId == null).toList();
    }
    return _medicines.where((m) => m.categoryId == categoryId).toList();
  }

  int getMedicinesCountByCategory(int categoryId) {
    return _medicines.where((m) => m.categoryId == categoryId).length;
  }
}