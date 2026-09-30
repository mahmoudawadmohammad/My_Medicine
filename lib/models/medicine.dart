// ============================================================
// ملف: medicine.dart
// المسار: lib/models/medicine.dart
// الوصف: نموذج بيانات الدواء - مع دعم تتبع الأوقات المعالجة
//         ✅ يدعم عزل البيانات لكل مستخدم (userId)
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 💊 Medicine: نموذج بيانات يمثل دواءً واحداً
class Medicine {
  // ==========================================================
  // خصائص الدواء الأساسية
  // ==========================================================

  int? id;

  /// ✅ معرف المستخدم المالك لهذا الدواء
  String? userId;

  String name;
  int pillCount;

  /// معرف التصنيف (null = بدون تصنيف)
  int? categoryId;

  /// الأوقات الثلاثة للجرعات
  TimeOfDay time;
  TimeOfDay? time2;
  TimeOfDay? time3;

  /// حالة النشاط
  bool isActive;

  /// آخر تاريخ تمت فيه معالجة جرعة
  DateTime? lastProcessedDate;

  /// آخر تاريخ تمت فيه إعادة التعبئة
  DateTime? lastRefillDate;

  /// أيام الأسبوع المختارة (فارغة = كل الأيام)
  /// 1=السبت، 2=الأحد، ... 7=الجمعة
  List<int> selectedDays;

  /// أرقام الجرعات التي تمت معالجتها اليوم
  List<int> processedTimes;

  // ==========================================================
  // Constructor
  // ==========================================================
  Medicine({
    this.id,
    this.userId,                  // ✅ جديد
    required this.name,
    required this.pillCount,
    this.categoryId,
    required this.time,
    this.time2,
    this.time3,
    this.isActive = true,
    this.lastProcessedDate,
    this.lastRefillDate,
    this.selectedDays = const [],
    this.processedTimes = const [],
  });

  // ==========================================================
  // toMap
  // ==========================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,           // ✅ جديد
      'name': name,
      'pillCount': pillCount,
      'categoryId': categoryId,
      'hour': time.hour,
      'minute': time.minute,
      'hour2': time2?.hour,
      'minute2': time2?.minute,
      'hour3': time3?.hour,
      'minute3': time3?.minute,
      'isActive': isActive ? 1 : 0,
      'lastProcessedDate': lastProcessedDate?.toIso8601String(),
      'lastRefillDate': lastRefillDate?.toIso8601String(),
      'selectedDays': selectedDays.isEmpty ? null : selectedDays.join(','),
      'processedTimes': processedTimes.isEmpty ? null : processedTimes.join(','),
    };
  }

  // ==========================================================
  // fromMap
  // ==========================================================
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as int?,
      userId: map['userId'] as String?,   // ✅ جديد
      name: map['name'] as String,
      pillCount: map['pillCount'] as int? ?? 0,
      categoryId: map['categoryId'] as int?,
      time: TimeOfDay(
        hour: map['hour'] as int? ?? 8,
        minute: map['minute'] as int? ?? 0,
      ),
      time2: map['hour2'] != null && map['minute2'] != null
          ? TimeOfDay(hour: map['hour2'] as int, minute: map['minute2'] as int)
          : null,
      time3: map['hour3'] != null && map['minute3'] != null
          ? TimeOfDay(hour: map['hour3'] as int, minute: map['minute3'] as int)
          : null,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      lastProcessedDate: map['lastProcessedDate'] != null
          ? DateTime.parse(map['lastProcessedDate'] as String)
          : null,
      lastRefillDate: map['lastRefillDate'] != null
          ? DateTime.parse(map['lastRefillDate'] as String)
          : null,
      selectedDays: map['selectedDays'] != null &&
          (map['selectedDays'] as String).isNotEmpty
          ? (map['selectedDays'] as String)
          .split(',')
          .map((e) => int.parse(e.trim()))
          .toList()
          : [],
      processedTimes: map['processedTimes'] != null &&
          (map['processedTimes'] as String).isNotEmpty
          ? (map['processedTimes'] as String)
          .split(',')
          .map((e) => int.parse(e.trim()))
          .toList()
          : [],
    );
  }

  // ==========================================================
  // copyWith
  // ==========================================================
  Medicine copyWith({
    int? id,
    String? userId,               // ✅ جديد
    String? name,
    int? pillCount,
    int? categoryId,
    TimeOfDay? time,
    TimeOfDay? time2,
    TimeOfDay? time3,
    bool? isActive,
    DateTime? lastProcessedDate,
    DateTime? lastRefillDate,
    List<int>? selectedDays,
    List<int>? processedTimes,
  }) {
    return Medicine(
      id: id ?? this.id,
      userId: userId ?? this.userId,   // ✅ جديد
      name: name ?? this.name,
      pillCount: pillCount ?? this.pillCount,
      categoryId: categoryId ?? this.categoryId,
      time: time ?? this.time,
      time2: time2 ?? this.time2,
      time3: time3 ?? this.time3,
      isActive: isActive ?? this.isActive,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
      lastRefillDate: lastRefillDate ?? this.lastRefillDate,
      selectedDays: selectedDays ?? this.selectedDays,
      processedTimes: processedTimes ?? this.processedTimes,
    );
  }

  // ==========================================================
  // دوال الوقت (بدون تغيير)
  // ==========================================================

  String getFormattedTime(BuildContext context) {
    return time.format(context);
  }

  String get formattedTimeString {
    final hourStr = time.hour.toString().padLeft(2, '0');
    final minuteStr = time.minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  int get totalMinutes {
    return time.hour * 60 + time.minute;
  }

  List<TimeOfDay> get allTimes {
    final List<TimeOfDay> times = [time];
    if (time2 != null) times.add(time2!);
    if (time3 != null) times.add(time3!);
    return times;
  }

  int get totalDosesCount {
    int count = 1;
    if (time2 != null) count++;
    if (time3 != null) count++;
    return count;
  }

  // ==========================================================
  // دوال الأيام (بدون تغيير)
  // ==========================================================

  bool isScheduledForToday({DateTime? dateTime}) {
    if (selectedDays.isEmpty) return true;

    final now = dateTime ?? DateTime.now();
    final int flutterWeekday = now.weekday;

    int ourDayValue;
    switch (flutterWeekday) {
      case 6:
        ourDayValue = 1;
        break;
      case 7:
        ourDayValue = 2;
        break;
      case 1:
        ourDayValue = 3;
        break;
      case 2:
        ourDayValue = 4;
        break;
      case 3:
        ourDayValue = 5;
        break;
      case 4:
        ourDayValue = 6;
        break;
      case 5:
        ourDayValue = 7;
        break;
      default:
        ourDayValue = 0;
    }

    return selectedDays.contains(ourDayValue);
  }

  bool isDaySelected(int dayValue) {
    if (selectedDays.isEmpty) return true;
    return selectedDays.contains(dayValue);
  }

  String getSelectedDaysText() {
    if (selectedDays.isEmpty) return 'all_days'.tr;

    final dayNames = {
      1: 'saturday'.tr,
      2: 'sunday'.tr,
      3: 'monday'.tr,
      4: 'tuesday'.tr,
      5: 'wednesday'.tr,
      6: 'thursday'.tr,
      7: 'friday'.tr,
    };

    final names = selectedDays
        .map((d) => dayNames[d] ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    return names.join('، ');
  }

  // ==========================================================
  // دوال الحبات (بدون تغيير)
  // ==========================================================

  Medicine takeOnePill() {
    if (pillCount > 0) {
      return copyWith(pillCount: pillCount - 1);
    }
    return this;
  }

  Medicine refill(int additionalPills) {
    if (additionalPills > 0) {
      return copyWith(
        pillCount: pillCount + additionalPills,
        lastRefillDate: DateTime.now(),
      );
    }
    return this;
  }

  // ==========================================================
  // دوال تتبع الأوقات المعالجة (بدون تغيير)
  // ==========================================================

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool wasProcessedToday() {
    if (lastProcessedDate == null) return false;
    return _isSameDay(lastProcessedDate!, DateTime.now());
  }

  bool wasTimeProcessedToday(int doseNumber) {
    if (lastProcessedDate == null) return false;
    if (!_isSameDay(lastProcessedDate!, DateTime.now())) return false;
    return processedTimes.contains(doseNumber);
  }

  Medicine markTimeAsProcessed(int doseNumber) {
    final now = DateTime.now();

    List<int> timesToUse;
    if (lastProcessedDate == null || !_isSameDay(lastProcessedDate!, now)) {
      timesToUse = [];
    } else {
      timesToUse = List.from(processedTimes);
    }

    if (!timesToUse.contains(doseNumber)) {
      timesToUse.add(doseNumber);
    }

    return copyWith(
      processedTimes: timesToUse,
      lastProcessedDate: now,
    );
  }

  bool wereAllTimesProcessed() {
    if (!wasProcessedToday()) return false;
    return processedTimes.length >= totalDosesCount;
  }

  int getRemainingDosesToday() {
    if (!wasProcessedToday()) return totalDosesCount;
    final remaining = totalDosesCount - processedTimes.length;
    return remaining < 0 ? 0 : remaining;
  }

  Medicine resetProcessedTimes() {
    return copyWith(processedTimes: []);
  }

  // ==========================================================
  // دوال الوقت الحالي (بدون تغيير)
  // ==========================================================

  bool isExactTimeNow() {
    final now = TimeOfDay.now();
    if (now.hour == time.hour && now.minute == time.minute) return true;
    if (time2 != null &&
        now.hour == time2!.hour &&
        now.minute == time2!.minute) {
      return true;
    }
    if (time3 != null &&
        now.hour == time3!.hour &&
        now.minute == time3!.minute) {
      return true;
    }
    return false;
  }

  int getCurrentDoseNumber() {
    final now = TimeOfDay.now();
    if (now.hour == time.hour && now.minute == time.minute) return 1;
    if (time2 != null &&
        now.hour == time2!.hour &&
        now.minute == time2!.minute) {
      return 2;
    }
    if (time3 != null &&
        now.hour == time3!.hour &&
        now.minute == time3!.minute) {
      return 3;
    }
    return 0;
  }

  bool shouldProcessNow() {
    if (pillCount <= 0) return false;
    if (!isActive) return false;
    if (!isExactTimeNow()) return false;

    final currentDose = getCurrentDoseNumber();
    if (currentDose == 0) return false;
    if (wasTimeProcessedToday(currentDose)) return false;

    return true;
  }

  // ==========================================================
  // دوال مساعدة (بدون تغيير)
  // ==========================================================

  bool get hasPillsLeft => pillCount > 0;
  bool get isLowStock => pillCount > 0 && pillCount <= 3;
  bool get isEmpty => pillCount == 0;
  bool get isCategorized => categoryId != null;

  String getPillStatusText() {
    if (pillCount == 0) return 'out_of_pills_need_refill'.tr;
    if (pillCount == 1) return 'only_one_pill_left'.tr;
    if (pillCount <= 3) {
      return '⚠️ ${'remaining'.tr} $pillCount ${'pills_only'.tr}';
    }
    if (pillCount <= 10) {
      return '💊 $pillCount ${'pills_remaining'.tr}';
    }
    return '✅ $pillCount ${'pills_available'.tr}';
  }

  Color getPillStatusColor() {
    if (pillCount == 0) return Colors.red;
    if (pillCount <= 3) return Colors.orange;
    if (pillCount <= 10) return Colors.amber;
    return Colors.green;
  }

  IconData getPillStatusIcon() {
    if (pillCount == 0) return Icons.warning_amber_rounded;
    if (pillCount <= 3) return Icons.notification_important;
    return Icons.medication;
  }

  bool isValid() {
    return name.isNotEmpty && pillCount >= 0;
  }
}