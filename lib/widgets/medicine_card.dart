// ============================================================
// ملف: medicine_card.dart
// المسار: lib/widgets/medicine_card.dart
// الوصف: بطاقة عرض دواء - مع دعم الأوقات المتعددة
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medicine.dart';
import '../controllers/category_controller.dart';

// 💊 MedicineCard: بطاقة عرض دواء واحد
class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback? onTakePill;
  final Function(int)? onRefill;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onDelete,
    required this.onToggle,
    this.onTakePill,
    this.onRefill,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ الحصول على لون التصنيف
    final categoryController = Get.find<CategoryController>();
    final category = categoryController.getCategoryById(medicine.categoryId);
    final categoryColor = category?.color ?? Theme.of(context).colorScheme.primary;
    final categoryIcon = category?.icon ?? Icons.medication;
    final categoryName = category?.name ?? 'no_category'.tr;

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: medicine.isActive ? surfaceColor : Colors.grey[100],

      child: ListTile(
        // ✅ عند الضغط على البطاقة
        onTap: () => _showMedicineDetails(context),

        // ✅ عند الضغط المطول
        onLongPress: () => _showQuickOptions(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),

        // ======================================================
        // leading: أيقونة التصنيف
        // ======================================================
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: medicine.isActive
                  ? [categoryColor, categoryColor.withOpacity(0.7)]
                  : [Colors.grey[400]!, Colors.grey[600]!],
            ),
            boxShadow: [
              BoxShadow(
                color: medicine.isActive
                    ? categoryColor.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            categoryIcon,
            color: Colors.white,
            size: 26,
          ),
        ),

        // ======================================================
        // title: اسم الدواء + التصنيف + حالة النشاط
        // ======================================================
        title: Row(
          children: [
            Expanded(
              child: Text(
                medicine.name,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: medicine.isActive ? onSurfaceColor : Colors.grey[600],
                  decoration: medicine.isActive ? TextDecoration.none : TextDecoration.lineThrough,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // شارة النشاط
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: medicine.isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                medicine.isActive ? 'active'.tr : 'inactive'.tr,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: medicine.isActive ? Colors.green[700] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),

        // ======================================================
        // subtitle: التصنيف + الحبات + الوقت + الأيام
        // ======================================================
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            // ----- صف التصنيف -----
            Row(
              children: [
                Icon(categoryIcon, size: 14, color: categoryColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    categoryName,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: categoryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ----- صف حالة الحبات -----
            Row(
              children: [
                Icon(medicine.getPillStatusIcon(), size: 14, color: medicine.getPillStatusColor()),
                const SizedBox(width: 4),
                // ✅ استخدام Expanded بدلاً من Flexible للتحكم بالمساحة
                Expanded(
                  child: Text(
                    medicine.getPillStatusText(),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: medicine.getPillStatusColor(),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // ✅ استخدام Flexible بدلاً من Container لشارة التعبئة
                if (medicine.isActive && medicine.isLowStock && !medicine.wereAllTimesProcessed())
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'needs_refill'.tr,
                        style: GoogleFonts.cairo(fontSize: 9, color: Colors.orange[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            // ----- صف الأوقات -----
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _getFormattedTimes(context),
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ----- صف الأيام -----
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    medicine.selectedDays.isEmpty
                        ? 'all_days'.tr
                        : medicine.getSelectedDaysText(),
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ======================================================
            // ✅ شارة "تم التناول اليوم" - تظهر فقط عند اكتمال جميع الجرعات
            // ======================================================
            if (medicine.isActive && medicine.wereAllTimesProcessed())
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 11, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'taken_today'.tr,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // ======================================================
        // trailing: أزرار التحكم
        // ======================================================
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر تناول حبة
            if (medicine.isActive && medicine.hasPillsLeft)
              IconButton(
                onPressed: onTakePill != null ? () => _confirmTakePill(context) : null,
                icon: const Icon(Icons.check_circle_outline, size: 22, color: Colors.green),
                tooltip: 'take_pill'.tr,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              ),

            // زر إعادة التعبئة
            if (medicine.isActive)
              IconButton(
                onPressed: onRefill != null ? () => _showRefillDialog(context) : null,
                icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.blue),
                tooltip: 'refill'.tr,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              ),

            // زر تبديل النشاط
            IconButton(
              onPressed: onToggle,
              icon: Icon(
                medicine.isActive ? Icons.toggle_on : Icons.toggle_off,
                size: 28,
                color: medicine.isActive ? Colors.green : Colors.grey[400],
              ),
              tooltip: medicine.isActive ? 'disable_medicine'.tr : 'enable_medicine'.tr,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              visualDensity: VisualDensity.compact,
            ),

            // زر الحذف
            IconButton(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline, size: 22, color: Colors.red),
              tooltip: 'delete'.tr,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // دالة مساعدة: تنسيق الأوقات
  // ==========================================================
  String _getFormattedTimes(BuildContext context) {
    String times = medicine.getFormattedTime(context);
    if (medicine.time2 != null) times += ' | ${medicine.time2!.format(context)}';
    if (medicine.time3 != null) times += ' | ${medicine.time3!.format(context)}';
    return times;
  }

  // ==========================================================
  // حوار تأكيد الحذف
  // ==========================================================
  Future<void> _confirmDelete(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 24),
              const SizedBox(width: 10),
              Text('confirm_delete'.tr, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'confirm_delete_msg'.tr} "${medicine.name}"؟',
                style: GoogleFonts.cairo(fontSize: 16),
              ),
              if (medicine.pillCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '⚠️ ${'will_be_lost'.tr} ${medicine.pillCount} ${'pill'.tr}',
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.orange[700]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr, style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onDelete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('delete'.tr, style: GoogleFonts.cairo()),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // حوار إعادة التعبئة
  // ==========================================================
  Future<void> _showRefillDialog(BuildContext context) async {
    final TextEditingController refillController = TextEditingController(text: '10');

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.blue),
              const SizedBox(width: 10),
              Text('refill'.tr, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${'medicine_name'.tr}: ${medicine.name}', style: GoogleFonts.cairo(fontSize: 15)),
              Text('${'current_pills'.tr}: ${medicine.pillCount}', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 20),
              Text('${'pills_to_add'.tr}:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      int current = int.tryParse(refillController.text) ?? 0;
                      if (current > 1) refillController.text = (current - 1).toString();
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: TextField(
                      controller: refillController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      int current = int.tryParse(refillController.text) ?? 0;
                      refillController.text = (current + 1).toString();
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr, style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () {
                final additional = int.tryParse(refillController.text) ?? 0;
                if (additional > 0 && onRefill != null) {
                  Navigator.pop(context);
                  onRefill!(additional);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('fill'.tr, style: GoogleFonts.cairo()),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // حوار تأكيد التناول اليدوي
  // ==========================================================
  Future<void> _confirmTakePill(BuildContext context) async {
    if (medicine.pillCount <= 0) {
      Get.snackbar('not_possible'.tr, 'no_pills_left'.tr);
      return;
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final isOnTime = medicine.isExactTimeNow();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(
                isOnTime ? Icons.check_circle : Icons.touch_app,
                color: isOnTime ? Colors.green[700] : Colors.blue,
              ),
              const SizedBox(width: 10),
              Text(
                isOnTime ? 'confirm_take_medicine'.tr : 'manual_medicine_take'.tr,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'confirm_take_pill_from'.tr} "${medicine.name}"؟',
                style: GoogleFonts.cairo(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text('${'pills_before_take'.tr} ${medicine.pillCount}', style: GoogleFonts.cairo(fontSize: 14)),
              Text(
                '${'will_become'.tr} ${medicine.pillCount - 1} ${'pills_after_take'.tr}',
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr, style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onTakePill?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isOnTime ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isOnTime ? 'take'.tr : 'take_manually'.tr,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // ✅ عرض تفاصيل الدواء
  // ==========================================================
  void _showMedicineDetails(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    final category = categoryController.getCategoryById(medicine.categoryId);
    final categoryName = category?.name ?? 'no_category'.tr;
    final categoryColor = category?.color ?? Theme.of(context).colorScheme.primary;
    final categoryIcon = category?.icon ?? Icons.medication;

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
                          colors: [categoryColor, categoryColor.withOpacity(0.7)],
                        ),
                      ),
                      child: Icon(categoryIcon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            categoryName,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: categoryColor,
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

                // ======================================================
                // ✅ قسم أوقات الجرعات (جديد)
                // ======================================================
                _buildDosesSection(context),

                const SizedBox(height: 16),

                // ===== تفاصيل الدواء =====
                _buildDetailRow(Icons.numbers, 'pill_count_label'.tr, '${medicine.pillCount} ${'pill'.tr}'),
                _buildDetailRow(Icons.calendar_today, 'days_title'.tr,
                    medicine.selectedDays.isEmpty ? 'all_days'.tr : medicine.getSelectedDaysText()),
                if (medicine.lastProcessedDate != null)
                  _buildDetailRow(Icons.history, 'last_taken'.tr, _formatDateTime(medicine.lastProcessedDate!)),
                if (medicine.lastRefillDate != null)
                  _buildDetailRow(Icons.refresh, 'last_refill'.tr, _formatDateTime(medicine.lastRefillDate!)),

                const SizedBox(height: 20),

                // ===== أزرار الإجراءات =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (medicine.isActive && medicine.hasPillsLeft)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmTakePill(context);
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text('take_pill'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (medicine.isActive)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRefillDialog(context);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text('refill'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
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
  // ✅ قسم عرض أوقات الجرعات (جديد)
  // ==========================================================
  Widget _buildDosesSection(BuildContext context) {
    // جمع الأوقات مع أرقامها
    final List<Map<String, dynamic>> allTimes = [
      {'time': medicine.time, 'number': 1},
    ];
    if (medicine.time2 != null) {
      allTimes.add({'time': medicine.time2!, 'number': 2});
    }
    if (medicine.time3 != null) {
      allTimes.add({'time': medicine.time3!, 'number': 3});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                '${'doses_today'.tr}:',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // عرض كل وقت مع حالته
        ...allTimes.map((timeData) {
          final TimeOfDay time = timeData['time'];
          final int number = timeData['number'];
          final bool isProcessed = medicine.wasTimeProcessedToday(number);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isProcessed
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isProcessed
                    ? Colors.green.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isProcessed ? Icons.check_circle : Icons.schedule,
                  color: isProcessed ? Colors.green : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        number == 1
                            ? 'first_dose'.tr
                            : number == 2
                            ? 'second_dose'.tr
                            : 'third_dose'.tr,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        time.format(context),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isProcessed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'taken'.tr,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
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

              // ===== اسم الدواء =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  medicine.name,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(),

              // ===== زر التفعيل/التعطيل =====
              ListTile(
                leading: Icon(
                  medicine.isActive ? Icons.toggle_off : Icons.toggle_on,
                  color: medicine.isActive ? Colors.grey : Colors.green,
                  size: 28,
                ),
                title: Text(
                  medicine.isActive ? 'disable_medicine'.tr : 'enable_medicine'.tr,
                  style: GoogleFonts.cairo(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onToggle();
                },
              ),

              // ===== زر إعادة التعبئة =====
              if (medicine.isActive)
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 28),
                  title: Text('refill'.tr, style: GoogleFonts.cairo()),
                  onTap: () {
                    Navigator.pop(context);
                    _showRefillDialog(context);
                  },
                ),

              // ===== زر تناول حبة =====
              if (medicine.isActive && medicine.hasPillsLeft)
                ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                  title: Text('take_pill'.tr, style: GoogleFonts.cairo()),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmTakePill(context);
                  },
                ),

              // ===== زر الحذف =====
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                title: Text('delete_medicine'.tr, style: GoogleFonts.cairo(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
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
  // ✅ صف تفاصيل
  // ==========================================================
  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label:', style: GoogleFonts.cairo(fontSize: 15, color: Colors.grey[600])),
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
  // ✅ تنسيق التاريخ والوقت
  // ==========================================================
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}