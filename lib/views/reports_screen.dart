// ============================================================
// ملف: reports_screen.dart
// المسار: lib/views/reports/reports_screen.dart
// الوصف: صفحة التقارير - تعرض إحصائيات المستخدم
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/report_controller.dart';
import '../../controllers/medicine_controller.dart';
import '../../models/medicine_log.dart';
import '../widgets/charts_widgets.dart';
import 'dart:typed_data';
import '../../core/utils/pdf_generator.dart';
import '../../services/auth_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ الحصول على المتحكمات
    final ReportController controller = Get.put(ReportController());
    final MedicineController medicineController = Get.find<MedicineController>();

    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // ===== AppBar =====
      appBar: AppBar(
        title: Text(
          'reports'.tr,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Get.back(),
        ),

        actions: [
          Obx(() {
            if (controller.isLoading) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'export_pdf'.tr,
              onPressed: () => _exportPdf(context, controller),
            );
          }),
        ],
      ),

      // ===== Body =====
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==========================================
                // 1️⃣ اختيار الفترة
                // ==========================================
                _buildPeriodSelector(context, controller),

                const SizedBox(height: 20),

                // ==========================================
                // 2️⃣ بطاقة نسبة الالتزام
                // ==========================================
                _buildAdherenceCard(context, controller),

                const SizedBox(height: 16),

                // ==========================================
                // 3️⃣ بطاقات الإحصائيات الرئيسية
                // ==========================================
                _buildMainStats(context, controller),

                // بعد _buildMainStats:
                const SizedBox(height: 16),

// ==========================================
// ✅ 4️⃣ رسم بياني خطي (التطور اليومي)
// ==========================================
                if (controller.dailyTakenCount.isNotEmpty)
                  _buildDailyChart(context, controller),

                const SizedBox(height: 16),

// ==========================================
// ✅ 5️⃣ رسم بياني عمودي (حسب الدواء)
// ==========================================
                if (controller.takenByMedicine.isNotEmpty)
                  _buildMedicineBarChart(context, controller, medicineController),

                const SizedBox(height: 16),

                // ==========================================
                // 4️⃣ إحصائيات كل دواء
                // ==========================================
                if (controller.takenByMedicine.isNotEmpty)
                  _buildMedicineStats(context, controller, medicineController),

                const SizedBox(height: 16),

                // ==========================================
                // 5️⃣ آخر السجلات
                // ==========================================
                if (controller.allLogs.isNotEmpty)
                  _buildRecentLogs(context, controller, medicineController),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ==========================================================
// 4️⃣ رسم بياني خطي
// ==========================================================
  Widget _buildDailyChart(BuildContext context, ReportController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'daily_progress'.tr,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ChartsWidgets.buildLineChart(
            context: context,
            dailyData: controller.dailyTakenCount,
            height: 200,
          ),
        ],
      ),
    );
  }

// ==========================================================
// 5️⃣ رسم بياني عمودي
// ==========================================================
  Widget _buildMedicineBarChart(
      BuildContext context,
      ReportController controller,
      MedicineController medicineController,
      ) {
    // تحويل medicineId → name
    final Map<String, int> dataByName = {};
    controller.takenByMedicine.forEach((medId, count) {
      final medicine = controller.medicines
          .firstWhereOrNull((m) => m.id == medId);
      final name = medicine?.name ?? 'unknown'.tr;
      dataByName[name] = count;
    });

    // ترتيب واختيار أعلى 5
    final sortedEntries = dataByName.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = Map.fromEntries(sortedEntries.take(5));

    if (top5.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'top_medicines'.tr,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ChartsWidgets.buildBarChart(
            context: context,
            data: top5,
            height: 200,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 1️⃣ اختيار الفترة
  // ==========================================================
  Widget _buildPeriodSelector(BuildContext context, ReportController controller) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _periodButton(context, controller, ReportPeriod.today, 'today'.tr),
          _periodButton(context, controller, ReportPeriod.week, 'week'.tr),
          _periodButton(context, controller, ReportPeriod.month, 'month'.tr),
          _periodButton(context, controller, ReportPeriod.all, 'all'.tr),
        ],
      ),
    );
  }

  Widget _periodButton(
      BuildContext context,
      ReportController controller,
      ReportPeriod period,
      String label,
      ) {
    final isSelected = controller.selectedPeriod == period;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setPeriod(period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, ReportController controller) async {
    try {
      // ✅ إظهار مؤشر تحميل
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // ✅ الحصول على معلومات المستخدم
      final authService = Get.find<AuthService>();
      final userName = authService.userName.isNotEmpty
          ? authService.userName
          : 'user'.tr;
      final isArabic = Get.locale?.languageCode == 'ar';

      // ✅ توليد PDF
      final Uint8List pdfBytes = await PdfGenerator.generateReport(
        userName: userName,
        periodText: controller.periodText,
        totalPills: controller.totalPillsTaken,
        totalTaken: controller.totalTakenCount,
        totalRefill: controller.totalRefillCount,
        adherenceRate: controller.adherenceRate,
        takenByMedicine: controller.takenByMedicine,
        medicines: controller.medicines,
        logs: controller.allLogs,
        isArabic: isArabic,
      );

      // ✅ إغلاق مؤشر التحميل
      Get.back();

      // ✅ عرض PDF
      final filename = 'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await PdfGenerator.previewPdf(pdfBytes, filename);
    } catch (e) {
      Get.back(); // إغلاق مؤشر التحميل
      debugPrint('❌ خطأ في تصدير PDF: $e');
      Get.snackbar(
        'error'.tr,
        'failed_export_pdf'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==========================================================
  // 2️⃣ بطاقة نسبة الالتزام
  // ==========================================================
  Widget _buildAdherenceCard(BuildContext context, ReportController controller) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final rate = controller.adherenceRate;
    final percentage = controller.adherencePercentage;

    // ✅ لون حسب النسبة
    Color rateColor;
    if (rate >= 0.8) {
      rateColor = Colors.green;
    } else if (rate >= 0.5) {
      rateColor = Colors.orange;
    } else {
      rateColor = Colors.red;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white.withOpacity(0.9),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'adherence_rate'.tr,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ✅ نسبة كبيرة
          Text(
            percentage,
            style: GoogleFonts.cairo(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.periodText,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          // ✅ شريط تقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(rateColor),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 3️⃣ بطاقات الإحصائيات الرئيسية
  // ==========================================================
  Widget _buildMainStats(BuildContext context, ReportController controller) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            icon: Icons.medication,
            color: Colors.blue,
            value: '${controller.totalPillsTaken}',
            label: 'pills_taken'.tr,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.event_available,
            color: Colors.green,
            value: '${controller.totalTakenCount}',
            label: 'doses_taken'.tr,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.refresh,
            color: Colors.orange,
            value: '${controller.totalRefillCount}',
            label: 'refills'.tr,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String value,
        required String label,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 4️⃣ إحصائيات كل دواء
  // ==========================================================
  Widget _buildMedicineStats(
      BuildContext context,
      ReportController controller,
      MedicineController medicineController,
      ) {
    // ترتيب حسب العدد (الأعلى أولاً)
    final entries = controller.takenByMedicine.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_liquid,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'by_medicine'.tr,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...entries.map((entry) {
            final medicine = controller.medicines
                .firstWhereOrNull((m) => m.id == entry.key);

            final name = medicine?.name ?? 'unknown_medicine'.tr;
            final count = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // ✅ أيقونة الدواء
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ✅ اسم الدواء
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // ✅ العدد
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count ${'times'.tr}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ==========================================================
  // 5️⃣ آخر السجلات
  // ==========================================================
  Widget _buildRecentLogs(
      BuildContext context,
      ReportController controller,
      MedicineController medicineController,
      ) {
    // آخر 10 سجلات
    final logs = controller.allLogs.take(10).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'recent_activity'.tr,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...logs.map((log) {
            return _buildLogRow(context, log);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLogRow(BuildContext context, MedicineLog log) {
    // ✅ تحديد نوع الحدث
    final isTaken = log.isTaken;
    final color = isTaken ? Colors.green : Colors.blue;
    final icon = isTaken ? Icons.check_circle : Icons.refresh;
    final actionText = isTaken ? 'taken'.tr : 'refilled'.tr;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // ✅ أيقونة الحدث
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          // ✅ اسم الدواء + نوع الحدث
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.medicineName,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$actionText • ${log.formattedDate} ${log.formattedTime}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // ✅ التغيير (+ أو -)
          if (isTaken)
            Text(
              '-1',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            )
          else
            Text(
              '+${log.changeAmount}',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }
}