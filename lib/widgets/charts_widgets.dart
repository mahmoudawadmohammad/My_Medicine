// ============================================================
// ملف: charts_widgets.dart
// المسار: lib/views/reports/widgets/charts_widgets.dart
// الوصف: ويدجتات الرسوم البيانية للتقارير
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartsWidgets {
  // ==========================================================
  // ✅ 1. رسم بياني دائري (لتوزيع الأدوية)
  // ==========================================================
  static Widget buildPieChart({
    required BuildContext context,
    required Map<String, int> data, // name → count
    required List<Color> colors,
    double size = 200,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'no_data'.tr,
          style: GoogleFonts.cairo(color: Colors.grey),
        ),
      );
    }

    final total = data.values.fold(0, (sum, val) => sum + val);

    return SizedBox(
      height: size,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: data.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final percentage = (item.value / total * 100).toStringAsFixed(1);

            return PieChartSectionData(
              color: colors[index % colors.length],
              value: item.value.toDouble(),
              title: '$percentage%',
              radius: 60,
              titleStyle: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================================
  // ✅ 2. رسم بياني خطي (للتطور اليومي)
  // ==========================================================
  static Widget buildLineChart({
    required BuildContext context,
    required Map<String, int> dailyData, // YYYY-MM-DD → count
    double height = 200,
  }) {
    if (dailyData.isEmpty) {
      return Center(
        child: Text(
          'no_data'.tr,
          style: GoogleFonts.cairo(color: Colors.grey),
        ),
      );
    }

    // ترتيب حسب التاريخ
    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].value.toDouble()));
    }

    final maxY = sortedEntries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY / 4).ceilToDouble(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedEntries.length) {
                    return const SizedBox.shrink();
                  }

                  // إظهار فقط كل يومين
                  if (sortedEntries.length > 7 && index % 2 != 0) {
                    return const SizedBox.shrink();
                  }

                  final dateStr = sortedEntries[index].key;
                  final parts = dateStr.split('-');
                  final day = parts.length >= 3 ? parts[2] : '';

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      day,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (maxY / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sortedEntries.length - 1).toDouble(),
          minY: 0,
          maxY: maxY + 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: sortedEntries.length <= 15,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    Theme.of(context).colorScheme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ✅ 3. رسم بياني عمودي (للمقارنة)
  // ==========================================================
  static Widget buildBarChart({
    required BuildContext context,
    required Map<String, int> data,
    double height = 200,
    Color? barColor,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'no_data'.tr,
          style: GoogleFonts.cairo(color: Colors.grey),
        ),
      );
    }

    final entries = data.entries.toList();
    final maxY = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final color = barColor ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY + 1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY / 4).ceilToDouble(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (maxY / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }

                  final label = entries[index].key;
                  // اختصار الاسم إذا طويل
                  final shortLabel = label.length > 8
                      ? '${label.substring(0, 8)}...'
                      : label;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shortLabel,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value.value;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value.toDouble(),
                  color: color,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}