// ============================================================
// ملف: category_controller.dart
// المسار: lib/controllers/category_controller.dart
// الوصف: متحكم التصنيفات - يدعم عزل البيانات + التزامن مع Firestore
//         ✅ سحب البيانات من Firestore (Pull)
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../core/database/database_helper.dart';
import '../services/auth_service.dart';

class CategoryController extends GetxController {
  // ==========================================================
  // المراجع
  // ==========================================================

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = Get.find<AuthService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Worker? _authWorker;

  // ✅ منع تكرار السحب
  bool _isSyncingFromFirestore = false;

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

    _authWorker = ever(_authService.userRx, (user) {
      if (user != null) {
        debugPrint('👤 تغير المستخدم → إعادة تحميل التصنيفات');
        loadCategories();
      } else {
        _categories.clear();
        debugPrint('🚪 تسجيل خروج → مسح التصنيفات');
      }
    });

    if (_authService.userId != null) {
      loadCategories();
    }
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    super.onClose();
  }

  // ==========================================================
  // 🔥 دالة مساعدة: مزامنة تصنيف واحد مع Firestore (Push)
  // ==========================================================
  Future<void> _syncCategoryToFirestore(Category category, String userId) async {
    try {
      if (category.id == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(category.id.toString())
          .set({
        'name': category.name,
        'colorValue': category.colorValue,
        'iconCode': category.iconCode,
        'createdAt': category.createdAt?.toIso8601String(),
        'lastSyncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ تمت مزامنة التصنيف ${category.name} مع Firestore');
    } catch (e) {
      debugPrint('⚠️ فشل مزامنة التصنيف مع Firestore: $e');
    }
  }

  // ==========================================================
  // ✅ سحب التصنيفات من Firestore (Pull)
  // ==========================================================
  Future<void> _pullCategoriesFromFirestore(String userId) async {
    if (_isSyncingFromFirestore) {
      debugPrint('⏭️ سحب التصنيفات جارٍ بالفعل - تخطي');
      return;
    }

    _isSyncingFromFirestore = true;

    try {
      debugPrint('📥 جاري سحب التصنيفات من Firestore...');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ لا توجد تصنيفات في Firestore');
        return;
      }

      debugPrint('📦 تم جلب ${snapshot.docs.length} تصنيف من Firestore');

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();

          // نحوّل الـ id من String لـ int
          final int? categoryId = int.tryParse(doc.id);

          final Category category = Category(
            id: categoryId,
            name: data['name'] ?? '',
            colorValue: data['colorValue'] ?? 0,
            iconCode: data['iconCode'] ?? 0,
            createdAt: data['createdAt'] != null
                ? DateTime.tryParse(data['createdAt'])
                : null,
          );

          // upsert في SQLite
          await _dbHelper.upsertCategory(category, userId);
        } catch (e) {
          debugPrint('⚠️ خطأ في معالجة تصنيف من Firestore: $e');
        }
      }

      debugPrint('✅ تم سحب التصنيفات وتحديث SQLite');
    } catch (e) {
      debugPrint('❌ خطأ في سحب التصنيفات من Firestore: $e');
    } finally {
      _isSyncingFromFirestore = false;
    }
  }

  // ==========================================================
  // تحميل التصنيفات
  // ==========================================================

  Future<void> loadCategories() async {
    final String? userId = _authService.userId;
    if (userId == null) {
      debugPrint('⚠️ لا يوجد مستخدم - تخطي تحميل التصنيفات');
      _categories.clear();
      return;
    }

    _isLoading.value = true;

    try {
      // 🔥 1. سحب من Firestore أولاً
      await _pullCategoriesFromFirestore(userId);

      // 2. قراءة من SQLite
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
      // ✅ إضافة محلياً
      final newId = await _dbHelper.insertCategory(category, userId);
      category.id = newId;

      // 🔥 التزامن مع Firestore
      await _syncCategoryToFirestore(category, userId);

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
      await _dbHelper.updateCategory(category, userId);

      // 🔥 التزامن مع Firestore
      await _syncCategoryToFirestore(category, userId);

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

      // 1️⃣ حذف الأدوية المرتبطة محلياً
      await _dbHelper.deleteMedicinesByCategory(categoryId, userId);

      // 2️⃣ حذف التصنيف محلياً
      await _dbHelper.deleteCategory(categoryId, userId);

      // 🔥 3️⃣ حذف التصنيف + الأدوية المرتبطة من Firestore
      try {
        // حذف الأدوية المرتبطة
        final medicinesQuery = await _firestore
            .collection('users')
            .doc(userId)
            .collection('medicines')
            .where('categoryId', isEqualTo: categoryId)
            .get();

        for (final doc in medicinesQuery.docs) {
          await doc.reference.delete();
        }
        debugPrint('✅ تم حذف ${medicinesQuery.docs.length} دواء من Firestore');

        // حذف التصنيف
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .doc(categoryId.toString())
            .delete();
        debugPrint('✅ تم حذف التصنيف من Firestore');
      } catch (e) {
        debugPrint('⚠️ فشل حذف التصنيف من Firestore: $e');
      }

      // 4️⃣ إعادة تحميل
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
  // دوال مساعدة
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