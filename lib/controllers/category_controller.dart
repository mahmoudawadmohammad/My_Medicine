// ============================================================
// ملف: category_controller.dart
// المسار: lib/controllers/category_controller.dart
// الوصف: متحكم التصنيفات - يدعم عزل البيانات لكل مستخدم (userId)
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/category.dart';
import '../core/database/database_helper.dart';
import '../services/auth_service.dart';   // ✅ جديد

class CategoryController extends GetxController {
  // ==========================================================
  // المراجع
  // ==========================================================

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = Get.find<AuthService>();  // ✅ جديد

  Worker? _authWorker;   // ✅ لمتابعة تغييرات المستخدم

  // ==========================================================
  // المتغيرات التفاعلية
  // ==========================================================

  final RxList<Category> _categories = <Category>[].obs;
  final RxBool _isLoading = false.obs;

  // ==========================================================
  // Getters
  // ==========================================================

  List<Category> get categories => _categories.toList();
  bool get isLoading => _isLoading.value;
  int get categoriesCount => _categories.length;
  bool get hasCategories => _categories.isNotEmpty;

  // ==========================================================
  // دورة الحياة
  // ==========================================================

  @override
  void onInit() {
    super.onInit();

    // ✅ الاستماع لتغييرات المستخدم
    _authWorker = ever(_authService.userRx, (user) {
      if (user != null) {
        debugPrint('👤 تغير المستخدم → إعادة تحميل التصنيفات');
        loadCategories();
      } else {
        // تسجيل خروج → مسح القائمة
        _categories.clear();
        debugPrint('🚪 تسجيل خروج → مسح التصنيفات');
      }
    });

    // ✅ تحميل مبدئي (إذا كان المستخدم مسجل)
    if (_authService.userId != null) {
      loadCategories();
    }
  }

  @override
  void onClose() {
    _authWorker?.dispose();   // ✅ إلغاء مستمع المستخدم
    super.onClose();
  }

  // ==========================================================
  // تحميل التصنيفات
  // ==========================================================

  Future<void> loadCategories() async {
    // ✅ التحقق من وجود مستخدم
    final String? userId = _authService.userId;
    if (userId == null) {
      debugPrint('⚠️ لا يوجد مستخدم - تخطي تحميل التصنيفات');
      _categories.clear();
      return;
    }

    _isLoading.value = true;

    try {
      // ✅ تمرير userId
      final categories = await _dbHelper.getCategories(userId);
      _categories.assignAll(categories);
      debugPrint('✅ تم تحميل ${categories.length} تصنيف للمستخدم $userId');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل التصنيفات: $e');
      Get.snackbar(
        'error'.tr,
        'failed_load_categories'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // ==========================================================
  // إضافة تصنيف
  // ==========================================================

  Future<bool> addCategory(Category category) async {
    final String? userId = _authService.userId;
    if (userId == null) {
      Get.snackbar('error'.tr, 'not_logged_in'.tr);
      return false;
    }

    // التحقق من أن الاسم غير فارغ
    if (category.name.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'category_name_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    // التحقق من عدم وجود تصنيف بنفس الاسم
    if (_categories.any((c) => c.name.toLowerCase() == category.name.toLowerCase())) {
      Get.snackbar(
        'warning_alert'.tr,
        'category_already_exists'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      // ✅ تمرير userId
      await _dbHelper.insertCategory(category, userId);
      await loadCategories();

      Get.snackbar(
        'success'.tr,
        '${'added_successfully'.tr} ${category.name} ${'successfully'.tr}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في إضافة التصنيف: $e');
      Get.snackbar(
        '${'error'.tr} ❌',
        'failed_add_category'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // ==========================================================
  // تعديل تصنيف
  // ==========================================================

  Future<bool> updateCategory(Category category) async {
    final String? userId = _authService.userId;
    if (userId == null) return false;

    if (category.name.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'category_name_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      // ✅ تمرير userId
      await _dbHelper.updateCategory(category, userId);
      await loadCategories();

      Get.snackbar(
        'success'.tr,
        'category_updated'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث التصنيف: $e');
      Get.snackbar(
        '${'error'.tr} ❌',
        'failed_update_category'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // ==========================================================
  // حذف تصنيف
  // ==========================================================

  Future<bool> deleteCategory(int categoryId) async {
    final String? userId = _authService.userId;
    if (userId == null) return false;

    try {
      final category = _categories.firstWhereOrNull((c) => c.id == categoryId);
      if (category == null) return false;

      // 1️⃣ حذف الأدوية المرتبطة
      await _dbHelper.deleteMedicinesByCategory(categoryId, userId);   // ✅

      // 2️⃣ حذف التصنيف
      await _dbHelper.deleteCategory(categoryId, userId);   // ✅

      // 3️⃣ إعادة تحميل
      await loadCategories();

      Get.snackbar(
        'deleted_success'.tr,
        '${'category_deleted'.tr} ${category.name}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف التصنيف: $e');
      Get.snackbar(
        '${'error'.tr} ❌',
        'failed_delete_category'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // ==========================================================
  // دوال مساعدة (بدون userId - تعمل على القائمة المحلية)
  // ==========================================================

  Category? getCategoryById(int? categoryId) {
    if (categoryId == null) return null;
    return _categories.firstWhereOrNull((c) => c.id == categoryId);
  }

  String getCategoryName(int? categoryId) {
    if (categoryId == null) return 'no_category'.tr;
    final category = getCategoryById(categoryId);
    return category?.name ?? 'no_category'.tr;
  }

  Color getCategoryColor(int? categoryId) {
    if (categoryId == null) return Colors.grey;
    final category = getCategoryById(categoryId);
    return category?.color ?? Colors.grey;
  }

  IconData getCategoryIcon(int? categoryId) {
    if (categoryId == null) return Icons.medication;
    final category = getCategoryById(categoryId);
    return category?.icon ?? Icons.medication;
  }

  Future<void> refreshCategories() async {
    await loadCategories();
  }
}