// ============================================================
// ملف: home_screen.dart
// المسار: lib/views/home/home_screen.dart
// الوصف: الصفحة الرئيسية - قائمة الأدوية والتصنيفات
//         بدون أدراج وبدون بلوتوث
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/medicine_controller.dart';
import '../../controllers/category_controller.dart';
import '../../widgets/medicine_card.dart';
import '../services/auth_service.dart';
import 'add_medicine_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ===== المتحكمات =====
  late final MedicineController _medicineController;
  late final CategoryController _categoryController;

  // ===== التصنيف المحدد للفلترة (null = الكل) =====
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();

    // ✅ الحصول على المتحكمات أو إنشاؤها
    try {
      _medicineController = Get.find<MedicineController>();
    } catch (e) {
      _medicineController = Get.put(MedicineController());
    }

    try {
      _categoryController = Get.find<CategoryController>();
    } catch (e) {
      _categoryController = Get.put(CategoryController());
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ استخراج الألوان من الثيم
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      // ===== جسم الصفحة =====
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.8),
              scaffoldBg,
            ],
            stops: const [0.0, 0.25, 0.25],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ==================================================
              // 🔹 رأس الصفحة (Header)
              // ==================================================
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // النصوص الترحيبية
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() {
                          final authService = Get.find<AuthService>();
                          final userName = authService.userName;
                          return Text(
                            userName.isEmpty ? 'welcome'.tr : '${'welcome'.tr} $userName',
                            style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            ),
                          );
                       }),
                        Text(
                          'app_name'.tr,
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // أزرار الرأس
                    Row(
                      children: [

                        _buildHeaderButton(
                          icon: Icons.bar_chart,
                          tooltip: 'reports'.tr,
                          onPressed: () {
                            Get.to(() => const ReportsScreen());
                          },
                        ),

                        const SizedBox(width: 8),

                        // زر التصنيفات
                        _buildHeaderButton(
                          icon: Icons.category_outlined,
                          tooltip: 'categories'.tr,
                          onPressed: () {
                            Get.to(() => const CategoriesScreen());
                          },
                        ),
                        const SizedBox(width: 8),
                        // زر الإعدادات
                        _buildHeaderButton(
                          icon: Icons.settings_outlined,
                          tooltip: 'settings'.tr,
                          onPressed: () {
                            Get.to(() => const SettingsScreen());
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 🔹 فلتر التصنيفات
              // ==================================================
              _buildCategoryFilter(),

              const SizedBox(height: 10),

              // ==================================================
              // 🔹 قائمة الأدوية
              // ==================================================
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ----- عنوان القائمة وزر الإضافة -----
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'medicine_schedule'.tr,
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: onSurfaceColor,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Get.to(() => const AddMedicineScreen());
                              },
                              icon: const Icon(Icons.add, size: 20),
                              label: Text(
                                'add'.tr,
                                style: GoogleFonts.cairo(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ----- قائمة الأدوية -----
                      Expanded(
                        child: Obx(() {
                          // حالة التحميل
                          if (_medicineController.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          // فلترة الأدوية حسب التصنيف
                          final allMedicines = _medicineController.medicines;
                          final medicines = _selectedCategoryId == null
                              ? allMedicines
                              : allMedicines.where((m) => m.categoryId == _selectedCategoryId).toList();

                          // القائمة فارغة
                          if (medicines.isEmpty) {
                            return _buildEmptyState(context);
                          }

                          // عرض القائمة
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: medicines.length,
                            itemBuilder: (context, index) {
                              final medicine = medicines[index];

                              return MedicineCard(
                                medicine: medicine,
                                onDelete: () => _medicineController.deleteMedicine(medicine.id!),
                                onToggle: () => _medicineController.toggleMedicineActive(medicine.id!),
                                onRefill: (additionalPills) {
                                  _medicineController.refillMedicine(medicine.id!, additionalPills);
                                },
                                onTakePill: () {
                                  _medicineController.takePillManually(medicine.id!);
                                },
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // زر رأس الصفحة
  // ==========================================================
  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }

  // ==========================================================
  // فلتر التصنيفات (شرائح أفقية)
  // ==========================================================
  Widget _buildCategoryFilter() {
    return Obx(() {
      final categories = _categoryController.categories;

      // إذا لا توجد تصنيفات، لا نعرض الفلتر
      if (categories.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 45,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // ✅ خيار "الكل"
            _buildCategoryChip(
              label: 'all'.tr,
              icon: Icons.apps,
              color: Theme.of(context).colorScheme.primary,
              isSelected: _selectedCategoryId == null,
              onTap: () {
                setState(() => _selectedCategoryId = null);
              },
            ),

            const SizedBox(width: 8),

            // ✅ تصنيفات المستخدم
            ...categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryChip(
                  label: category.name,
                  icon: category.icon,
                  color: Theme.of(context).colorScheme.primary,
                  isSelected: _selectedCategoryId == category.id,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId =
                      _selectedCategoryId == category.id ? null : category.id;
                    });
                  },
                ),
              );
            }).toList(),
          ],
        ),
      );
    });
  }

  // ==========================================================
  // شريحة تصنيف واحدة
  // ==========================================================
  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // حالة فارغة (لا توجد أدوية)
  // ==========================================================
  Widget _buildEmptyState(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 80,
            color: onSurfaceColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'no_medicines'.tr,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onSurfaceColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'add_medicine_hint'.tr,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: onSurfaceColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}