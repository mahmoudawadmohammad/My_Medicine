// ============================================================
// ملف: pdf_generator.dart
// المسار: lib/core/utils/pdf_generator.dart
// الوصف: توليد تقارير PDF بدعم اللغتين (عربي/إنجليزي)
// ============================================================

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get_navigation/src/root/parse_route.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/medicine.dart';
import '../../models/medicine_log.dart';

class PdfGenerator {
  PdfGenerator._();

  // ==========================================================
  // ✅ تحميل الخطوط
  // ==========================================================
  static Future<pw.Font> _loadRegularFont() async {
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  static Future<pw.Font> _loadBoldFont() async {
    final fontData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    return pw.Font.ttf(fontData);
  }

  // ==========================================================
  // ✅ توليد تقرير PDF شامل
  // ==========================================================
  static Future<Uint8List> generateReport({
    required String userName,
    required String periodText,
    required int totalPills,
    required int totalTaken,
    required int totalRefill,
    required double adherenceRate,
    required Map<int, int> takenByMedicine,
    required List<Medicine> medicines,
    required List<MedicineLog> logs,
    required bool isArabic,
  }) async {
    // ✅ تحميل الخطوط
    final regularFont = await _loadRegularFont();
    final boldFont = await _loadBoldFont();

    // ✅ إنشاء الثيم بخط Cairo
    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
      italic: regularFont,
      boldItalic: boldFont,
    );

    final pdf = pw.Document(theme: theme);

    // ✅ النصوص حسب اللغة
    final texts = _getTexts(isArabic);

    // ✅ إضافة الصفحة
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: theme,
        // ✅ دعم RTL للعربية
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (context) => [
          // ===== الرأس =====
          _buildHeader(texts, userName, periodText, boldFont, regularFont),

          pw.SizedBox(height: 24),

          // ===== نسبة الالتزام =====
          _buildAdherenceSection(texts, adherenceRate, boldFont, regularFont),

          pw.SizedBox(height: 20),

          // ===== الإحصائيات الرئيسية =====
          _buildMainStats(
            texts,
            totalPills,
            totalTaken,
            totalRefill,
            boldFont,
            regularFont,
          ),

          pw.SizedBox(height: 24),

          // ===== إحصائيات حسب الدواء =====
          if (takenByMedicine.isNotEmpty)
            _buildMedicineStats(
              texts,
              takenByMedicine,
              medicines,
              boldFont,
              regularFont,
            ),

          pw.SizedBox(height: 24),

          // ===== آخر السجلات =====
          if (logs.isNotEmpty)
            _buildRecentLogs(
              texts,
              logs.take(20).toList(),
              boldFont,
              regularFont,
            ),

          pw.SizedBox(height: 24),

          // ===== Footer =====
          _buildFooter(texts, regularFont),
        ],
      ),
    );

    return pdf.save();
  }

  // ==========================================================
  // ✅ النصوص حسب اللغة
  // ==========================================================
  static Map<String, String> _getTexts(bool isArabic) {
    if (isArabic) {
      return {
        'title': 'تقرير دوائي',
        'user': 'المستخدم',
        'period': 'الفترة',
        'adherence': 'نسبة الالتزام',
        'pills_taken': 'حبات متناولة',
        'doses_taken': 'جرعات',
        'refills': 'تعبئات',
        'by_medicine': 'إحصائيات حسب الدواء',
        'medicine': 'الدواء',
        'count': 'العدد',
        'recent_logs': 'آخر النشاطات',
        'action': 'النوع',
        'date': 'التاريخ',
        'taken': 'تم التناول',
        'refilled': 'تمت التعبئة',
        'footer': 'تم إنشاء هذا التقرير تلقائياً بواسطة تطبيق دوائي',
        'no_data': 'لا توجد بيانات',
      };
    } else {
      return {
        'title': 'My Medicine Report',
        'user': 'User',
        'period': 'Period',
        'adherence': 'Adherence Rate',
        'pills_taken': 'Pills Taken',
        'doses_taken': 'Doses',
        'refills': 'Refills',
        'by_medicine': 'By Medicine',
        'medicine': 'Medicine',
        'count': 'Count',
        'recent_logs': 'Recent Activity',
        'action': 'Action',
        'date': 'Date',
        'taken': 'Taken',
        'refilled': 'Refilled',
        'footer': 'This report was generated automatically by My Medicine app',
        'no_data': 'No Data',
      };
    }
  }

  // ==========================================================
  // ✅ الرأس
  // ==========================================================
  static pw.Widget _buildHeader(
      Map<String, String> texts,
      String userName,
      String period,
      pw.Font boldFont,
      pw.Font regularFont,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          texts['title']!,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
            color: PdfColors.teal800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, color: PdfColors.teal800),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${texts['user']}: $userName',
              style: pw.TextStyle(
                fontSize: 12,
                font: regularFont,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              '${texts['period']}: $period',
              style: pw.TextStyle(
                fontSize: 12,
                font: regularFont,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // ✅ قسم نسبة الالتزام
  // ==========================================================
  static pw.Widget _buildAdherenceSection(
      Map<String, String> texts,
      double rate,
      pw.Font boldFont,
      pw.Font regularFont,
      ) {
    final percentage = (rate * 100).toStringAsFixed(1);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.teal200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            texts['adherence']!,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
              color: PdfColors.teal800,
            ),
          ),
          pw.Text(
            '$percentage%',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
              color: PdfColors.teal800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ✅ الإحصائيات الرئيسية
  // ==========================================================
  static pw.Widget _buildMainStats(
      Map<String, String> texts,
      int totalPills,
      int totalTaken,
      int totalRefill,
      pw.Font boldFont,
      pw.Font regularFont,
      ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _statBox(
            texts['pills_taken']!,
            totalPills.toString(),
            PdfColors.blue700,
            boldFont,
            regularFont,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _statBox(
            texts['doses_taken']!,
            totalTaken.toString(),
            PdfColors.green700,
            boldFont,
            regularFont,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _statBox(
            texts['refills']!,
            totalRefill.toString(),
            PdfColors.orange700,
            boldFont,
            regularFont,
          ),
        ),
      ],
    );
  }

  static pw.Widget _statBox(
      String label,
      String value,
      PdfColor color,
      pw.Font boldFont,
      pw.Font regularFont,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              font: regularFont,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ✅ إحصائيات حسب الدواء
  // ==========================================================
  static pw.Widget _buildMedicineStats(
      Map<String, String> texts,
      Map<int, int> takenByMedicine,
      List<Medicine> medicines,
      pw.Font boldFont,
      pw.Font regularFont,
      ) {
    final entries = takenByMedicine.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          texts['by_medicine']!,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
            color: PdfColors.teal800,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.teal100),
              children: [
                _tableCell(texts['medicine']!, boldFont, regularFont, isHeader: true),
                _tableCell(texts['count']!, boldFont, regularFont, isHeader: true),
              ],
            ),
            ...entries.map((entry) {
              final medicine =
              medicines.firstWhereOrNull((m) => m.id == entry.key);
              final name = medicine?.name ?? '---';

              return pw.TableRow(
                children: [
                  _tableCell(name, boldFont, regularFont),
                  _tableCell(entry.value.toString(), boldFont, regularFont),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // ✅ آخر السجلات
  // ==========================================================
  static pw.Widget _buildRecentLogs(
      Map<String, String> texts,
      List<MedicineLog> logs,
      pw.Font boldFont,
      pw.Font regularFont,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          texts['recent_logs']!,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
            color: PdfColors.teal800,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.teal100),
              children: [
                _tableCell(texts['medicine']!, boldFont, regularFont, isHeader: true),
                _tableCell(texts['action']!, boldFont, regularFont, isHeader: true),
                _tableCell(texts['date']!, boldFont, regularFont, isHeader: true),
              ],
            ),
            ...logs.map((log) {
              final action = log.isTaken ? texts['taken']! : texts['refilled']!;
              return pw.TableRow(
                children: [
                  _tableCell(log.medicineName, boldFont, regularFont),
                  _tableCell(action, boldFont, regularFont),
                  _tableCell(log.formattedDateTime, boldFont, regularFont),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableCell(
      String text,
      pw.Font boldFont,
      pw.Font regularFont, {
        bool isHeader = false,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          font: isHeader ? boldFont : regularFont,
          color: isHeader ? PdfColors.teal800 : PdfColors.grey800,
        ),
      ),
    );
  }

  // ==========================================================
  // ✅ Footer
  // ==========================================================
  static pw.Widget _buildFooter(
      Map<String, String> texts,
      pw.Font regularFont,
      ) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Text(
          texts['footer']!,
          style: pw.TextStyle(
            fontSize: 10,
            font: regularFont,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'My Medicine 2026 ©',
          style: pw.TextStyle(
            fontSize: 9,
            font: regularFont,
            color: PdfColors.grey500,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // ==========================================================
  // ✅ عرض / مشاركة PDF
  // ==========================================================
  static Future<void> previewPdf(Uint8List pdfBytes, String filename) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: filename,
    );
  }

  static Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }
}