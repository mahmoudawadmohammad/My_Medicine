// ============================================================
// ملف: add_category_screen.dart
// المسار: lib/views/categories/add_category_screen.dart
// الوصف: شاشة إضافة تصنيف جديد مع اختيار اللون والأيقونة
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/category.dart';
import '../../controllers/category_controller.dart';

class AddCategoryScreen extends StatefulWidget {
  // ✅ category: إذا مُرر، فالشاشة للتعديل، وإلا فالإضافة
  final Category? category;

  const AddCategoryScreen({super.key, this.category});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  // ==========================================================
  // مفاتيح ومتحكمات النموذج
  // ==========================================================

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  // ==========================================================
  // متغيرات التصنيف
  // ==========================================================

  // اللون المختار (افتراضي: أخضر)
  Color _selectedColor = const Color(0xFF1B7B6E);

  // الأيقونة المختارة (افتراضية: دواء)
  IconData _selectedIcon = Icons.medication;

  // ==========================================================
  // قائمة الألوان المتاحة
  // ==========================================================

  final List<Color> _availableColors = [
    const Color(0xFF1B7B6E), // أخضر داكن
    const Color(0xFF2196F3), // أزرق
    const Color(0xFFE53935), // أحمر
    const Color(0xFFFB8C00), // برتقالي
    const Color(0xFF8E24AA), // بنفسجي
    const Color(0xFF00ACC1), // سماوي
    const Color(0xFF43A047), // أخضر
    const Color(0xFFFDD835), // أصفر
    const Color(0xFF6D4C41), // بني
    const Color(0xFF546E7A), // رمادي مزرق
    const Color(0xFFD81B60), // وردي
    const Color(0xFF3949AB), // أزرق داكن
  ];

  // ==========================================================
  // قائمة الأيقونات المتاحة
  // ==========================================================

  final List<IconData> _availableIcons = [
    Icons.medication,           // دواء
    Icons.medication_liquid,    // شراب
    Icons.vaccines,             // لقاح
    Icons.healing,              // شفاء
    Icons.favorite,             // قلب
    Icons.bloodtype,            // دم
    Icons.sick,                 // مرض
    Icons.monitor_heart,        // مراقبة القلب
    Icons.psychology,           // نفسي
    Icons.visibility,           // عيون
    Icons.air,                  // تنفس
    Icons.medical_services,     // خدمات طبية
    Icons.local_hospital,       // مستشفى
    Icons.health_and_safety,    // صحة وسلامة
    Icons.spa,                  // سبا
    Icons.fitness_center,       // لياقة
    Icons.eco,                  // طبيعي
    Icons.water_drop,           // قطرة ماء
    Icons.nightlight,           // ليل
    Icons.wb_sunny,             // شمس
  ];

  // ==========================================================
  // الـ Controller
  // ==========================================================

  final CategoryController _categoryController = Get.find<CategoryController>();

  // ==========================================================
  // دورة الحياة
  // ==========================================================

  @override
  void initState() {
    super.initState();
    // ✅ إذا كان تعديلاً، نحمّل البيانات
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedColor = widget.category!.color;
      _selectedIcon = widget.category!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ==========================================================
  // بناء الواجهة
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      // ===== شريط التطبيق =====
      appBar: AppBar(
        title: Text(
          widget.category == null ? 'add_category'.tr : 'edit_category'.tr,
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==========================================
                  // ✅ معاينة التصنيف
                  // ==========================================
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _selectedColor,
                            _selectedColor.withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _selectedColor.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _selectedIcon,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==========================================
                  // ✅ حقل اسم التصنيف
                  // ==========================================
                  _buildSectionTitle('category_name'.tr),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'category_name_hint'.tr,
                        prefixIcon: Icon(Icons.label_outline, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: surfaceColor,
                        hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
                      ),
                      style: GoogleFonts.cairo(fontSize: 16),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'category_name_required'.tr;
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // ✅ اختيار اللون
                  // ==========================================
                  _buildSectionTitle('choose_color'.tr),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableColors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedColor = color);
                          },
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? onSurfaceColor : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // ✅ اختيار الأيقونة
                  // ==========================================
                  _buildSectionTitle('choose_icon'.tr),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableIcons.map((icon) {
                        final isSelected = _selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedIcon = icon);
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _selectedColor.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _selectedColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? _selectedColor : onSurfaceColor.withOpacity(0.6),
                              size: 26,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ==========================================
                  // ✅ زر الحفظ
                  // ==========================================
                  ElevatedButton(
                    onPressed: _saveCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.category == null ? 'save_category'.tr : 'update_category'.tr,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.save_alt),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ويدجت: عنوان القسم
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // ==========================================================
  // دالة حفظ التصنيف
  // ==========================================================

  Future<void> _saveCategory() async {
    // 1️⃣ التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) return;

    // 2️⃣ إنشاء كائن التصنيف
    final category = Category(
      id: widget.category?.id,
      name: _nameController.text.trim(),
      colorValue: _selectedColor.value,
      iconCode: _selectedIcon.codePoint,
      createdAt: widget.category?.createdAt,
    );

    // 3️⃣ الحفظ أو التعديل
    bool success;
    if (widget.category == null) {
      success = await _categoryController.addCategory(category);
    } else {
      success = await _categoryController.updateCategory(category);
    }

    // 4️⃣ العودة للصفحة السابقة
    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}