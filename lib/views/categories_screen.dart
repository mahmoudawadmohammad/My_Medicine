// ============================================================
// ملف: categories_screen.dart
// المسار: lib/views/categories/categories_screen.dart
// الوصف: شاشة إدارة التصنيفات - عرض وإضافة وتعديل وحذف
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/medicine_controller.dart';
import '../../widgets/category_card.dart';
import 'add_category_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ===== الحصول على المتحكمات =====
    final CategoryController categoryController = Get.find<CategoryController>();
    final MedicineController medicineController = Get.find<MedicineController>();

    // ✅ استخراج الألوان من الثيم
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      // ===== شريط التطبيق =====
      appBar: AppBar(
        title: Text(
          'categories'.tr,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // ===== جسم الصفحة =====
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Obx(() {
          // حالة التحميل
          if (categoryController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // إذا لا توجد تصنيفات
          if (!categoryController.hasCategories) {
            return _buildEmptyState(context);
          }

          // عرض القائمة
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categoryController.categories.length,
            itemBuilder: (context, index) {
              final category = categoryController.categories[index];

              // ✅ عدد الأدوية في التصنيف
              final count = medicineController.getMedicinesCountByCategory(category.id!);

              return CategoryCard(
                category: category,
                medicinesCount: count,
                // عند الضغط: عرض أدوية التصنيف
                onTap: () {
                  _showCategoryMedicines(context, category.id!);
                },
                // عند التعديل
                onEdit: () {
                  Get.to(() => AddCategoryScreen(category: category));
                },
                // عند الحذف
                onDelete: () {
                  _confirmDelete(context, category.id!, category.name);
                },
              );
            },
          );
        }),
      ),

      // ===== زر إضافة تصنيف =====
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const AddCategoryScreen());
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'add_category'.tr,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ==========================================================
  // ويدجت: حالة فارغة (لا توجد تصنيفات)
  // ==========================================================
  Widget _buildEmptyState(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // أيقونة
          Icon(
            Icons.category_outlined,
            size: 100,
            color: onSurfaceColor.withOpacity(0.3),
          ),
          const SizedBox(height: 20),

          // رسالة
          Text(
            'no_categories'.tr,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onSurfaceColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'add_category_hint'.tr,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: onSurfaceColor.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // عرض أدوية تصنيف معين
  // ==========================================================
  void _showCategoryMedicines(BuildContext context, int categoryId) {
    final categoryController = Get.find<CategoryController>();
    final category = categoryController.getCategoryById(categoryId);

    if (category == null) return;

    // الانتقال إلى الرئيسية مع فلترة الأدوية
    Get.back();

    Get.snackbar(
      category.name,
      'category_filter_applied'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: category.color,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // ==========================================================
  // حوار تأكيد الحذف
  // ==========================================================
  void _confirmDelete(BuildContext context, int categoryId, String categoryName) {
    final categoryController = Get.find<CategoryController>();
    final medicineController = Get.find<MedicineController>();

    // عدد الأدوية في التصنيف
    final count = medicineController.getMedicinesCountByCategory(categoryId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(
                'confirm_delete'.tr,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'confirm_delete_category'.tr} "$categoryName"؟',
                style: GoogleFonts.cairo(fontSize: 16),
              ),

              // ⚠️ تحذير إذا كان التصنيف يحتوي أدوية
              if (count > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'delete_category_warning'.tr.replaceAll('{}', '$count'),
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            // زر الإلغاء
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'cancel'.tr,
                style: GoogleFonts.cairo(),
              ),
            ),
            // زر التأكيد
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                categoryController.deleteCategory(categoryId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'delete'.tr,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}