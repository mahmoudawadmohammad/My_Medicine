// ============================================================
// ملف: category_card.dart
// المسار: lib/widgets/category_card.dart
// الوصف: بطاقة عرض تصنيف مع تفاصيل وخيارات سريعة
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../models/medicine.dart';
import '../controllers/medicine_controller.dart';

// 🏷️ CategoryCard: بطاقة عرض تصنيف واحد
class CategoryCard extends StatelessWidget {
  final Category category;
  final int medicinesCount;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    required this.medicinesCount,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: surfaceColor,
      child: InkWell(
        // ✅ عند الضغط: عرض التفاصيل
        onTap: () => _showCategoryDetails(context),

        // ✅ عند الضغط المطول: عرض الخيارات السريعة
        onLongPress: () => _showQuickOptions(context),

        borderRadius: BorderRadius.circular(15),

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ==================================================
              // ✅ أيقونة التصنيف
              // ==================================================
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      category.color,
                      category.color.withOpacity(0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: category.color.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  category.icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              // ==================================================
              // ✅ معلومات التصنيف
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 14,
                          color: category.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$medicinesCount ${medicinesCount == 1 ? 'medicine'.tr : 'medicines'.tr}',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: onSurfaceColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: onSurfaceColor.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category.formattedDate,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: onSurfaceColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ✅ أزرار التحكم
              // ==================================================
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: category.color,
                      ),
                      tooltip: 'edit'.tr,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      tooltip: 'delete'.tr,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),

              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: onSurfaceColor.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ✅ عرض تفاصيل التصنيف (ضغطة عادية)
  // ==========================================================
  void _showCategoryDetails(BuildContext context) {
    // الحصول على أدوية هذا التصنيف
    final medicineController = Get.find<MedicineController>();
    final medicines = medicineController.getMedicinesByCategory(category.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== رأس النافذة =====
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            category.color,
                            category.color.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Icon(category.icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'category'.tr,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: category.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),

                // ===== تفاصيل التصنيف =====
                _buildDetailRow(
                  Icons.medication,
                  'medicines_count'.tr,
                  '$medicinesCount',
                ),
                _buildDetailRow(
                  Icons.calendar_today,
                  'created_at'.tr,
                  category.formattedDate,
                ),
                _buildColorRow(context),

                const SizedBox(height: 20),
                const Divider(),

                // ===== قائمة الأدوية في التصنيف =====
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${'medicines_in_category'.tr} ($medicinesCount)',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (medicines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'no_medicines_in_category'.tr,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                else
                  ...medicines.map((medicine) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: category.color.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            medicine.getPillStatusIcon(),
                            color: medicine.getPillStatusColor(),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medicine.name,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${medicine.pillCount} ${'pill'.tr} • ${_getFormattedTimes(medicine, context)}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // ===== زر التعديل =====
                if (onEdit != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit!();
                      },
                      icon: const Icon(Icons.edit),
                      label: Text('edit_category'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: category.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // ✅ عرض الخيارات السريعة (ضغط مطول)
  // ==========================================================
  void _showQuickOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== مقبض السحب =====
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ===== اسم التصنيف =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(category.icon, color: category.color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // ===== زر عرض التفاصيل =====
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: category.color,
                  size: 28,
                ),
                title: Text(
                  'view_details'.tr,
                  style: GoogleFonts.cairo(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCategoryDetails(context);
                },
              ),

              // ===== زر التعديل =====
              if (onEdit != null)
                ListTile(
                  leading: Icon(
                    Icons.edit_outlined,
                    color: category.color,
                    size: 28,
                  ),
                  title: Text(
                    'edit_category'.tr,
                    style: GoogleFonts.cairo(),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit!();
                  },
                ),

              // ===== زر الحذف =====
              if (onDelete != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 28,
                  ),
                  title: Text(
                    'delete_category'.tr,
                    style: GoogleFonts.cairo(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete!();
                  },
                ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
// ✅ صف عرض اللون (كدايرة ملونة)
// ==========================================================
  Widget _buildColorRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.palette, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '${'color'.tr}:',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          // ✅ دائرة بلون التصنيف
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: category.color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ✅ صف تفاصيل
  // ==========================================================
  Widget _buildDetailRow(
      IconData icon,
      String label,
      String value, {
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ✅ تنسيق الأوقات
  // ==========================================================
  String _getFormattedTimes(Medicine medicine, BuildContext context) {
    String times = medicine.getFormattedTime(context);
    if (medicine.time2 != null) times += ', ${medicine.time2!.format(context)}';
    if (medicine.time3 != null) times += ', ${medicine.time3!.format(context)}';
    return times;
  }
}