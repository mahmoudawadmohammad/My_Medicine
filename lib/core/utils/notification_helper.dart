// ============================================================
// ملف: notification_helper.dart
// المسار: lib/core/utils/notification_helper.dart
// الوصف: مساعد الإشعارات - ✅ تم حذف showMedicineNotification المكررة
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../../models/medicine.dart';
import 'package:smart_pillbox/services/background_task.dart';

// 🔔 NotificationHelper: فئة Singleton لإدارة جميع الإشعارات
class NotificationHelper {
  // ===== Singleton Pattern =====
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // ==========================================================
  // معرفات القنوات
  // ==========================================================
  static const String _channelIdMedicine = 'pillbox_medicine_channel_v2';
  static const String _channelNameMedicine = 'تنبيهات مواعيد الأدوية';
  static const String _channelDescMedicine = 'إشعارات عند موعد تناول الدواء';

  static const String _channelIdLowStock = 'pillbox_low_stock_channel_v2';
  static const String _channelNameLowStock = 'تنبيهات نفاد المخزون';
  static const String _channelDescLowStock = 'إشعارات عند انخفاض عدد الحبات أو نفادها';

  static const String _channelIdGeneral = 'pillbox_general_channel_v2';
  static const String _channelNameGeneral = 'إشعارات عامة';
  static const String _channelDescGeneral = 'إشعارات عامة وتنبيهات متنوعة';

  // ==========================================================
  // معرفات الإشعارات
  // ==========================================================
  static const int _medicineNotificationBase = 1000;
  static const int _lowStockNotificationBase = 2000;
  static const int _manualTakeNotificationBase = 5000;
  static const int _generalNotificationBase = 9000;

  // ==========================================================
  // 🚀 التهيئة
  // ==========================================================
  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    await _requestPermissions();
    await _createNotificationChannels();

    debugPrint('✅ تم تهيئة نظام الإشعارات بنجاح');
  }

  // ==========================================================
  // ✅ طلب الصلاحيات
  // ==========================================================
  Future<void> _requestPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final bool? notifGranted = await androidPlugin.requestNotificationsPermission();
      debugPrint('📱 صلاحية الإشعارات: $notifGranted');

      final bool? exactGranted = await androidPlugin.requestExactAlarmsPermission();
      debugPrint('⏰ صلاحية المنبهات الدقيقة: $exactGranted');
    }

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // ==========================================================
  // 📡 إنشاء القنوات
  // ==========================================================
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const AndroidNotificationChannel medicineChannel = AndroidNotificationChannel(
        _channelIdMedicine, _channelNameMedicine,
        description: _channelDescMedicine,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(medicineChannel);

      const AndroidNotificationChannel lowStockChannel = AndroidNotificationChannel(
        _channelIdLowStock, _channelNameLowStock,
        description: _channelDescLowStock,
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(lowStockChannel);

      const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
        _channelIdGeneral, _channelNameGeneral,
        description: _channelDescGeneral,
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(generalChannel);

      debugPrint('✅ تم إنشاء قنوات الإشعارات');
    }
  }

  // ==========================================================
  // ✅ قراءة الإعدادات
  // ==========================================================
  Future<Map<String, bool>> _getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'enabled': prefs.getBool('notifications_enabled') ?? true,
        'sound': prefs.getBool('sound_enabled') ?? true,
        'vibration': prefs.getBool('vibration_enabled') ?? true,
      };
    } catch (e) {
      debugPrint('❌ خطأ في قراءة الإعدادات: $e');
      return {'enabled': true, 'sound': true, 'vibration': true};
    }
  }

  // ==========================================================
  // ✅ دالة مساعدة: حساب أقرب يوم مطابق
  // ==========================================================
  DateTime? _calculateNextScheduledDate(TimeOfDay doseTime, Medicine medicine) {
    final now = DateTime.now();

    for (int daysToAdd = 0; daysToAdd < 30; daysToAdd++) {
      final candidateDate = DateTime(
        now.year,
        now.month,
        now.day + daysToAdd,
        doseTime.hour,
        doseTime.minute,
      );

      if (candidateDate.isBefore(now)) {
        continue;
      }

      if (medicine.isScheduledForToday(dateTime: candidateDate)) {
        debugPrint('📅 أقرب يوم مطابق: $candidateDate');
        return candidateDate;
      }
    }

    debugPrint('⚠️ لا يوجد يوم مطابق خلال 30 يوم');
    return null;
  }

  // ❌❌❌ تم حذف showMedicineNotification بالكامل
  // السبب: كانت تعرض إشعار فوري مكرر مع الإشعار المجدول

  // ==========================================================
  // ✅ جدولة إشعار (مع مراعاة الأيام المحددة)
  // ==========================================================
  Future<void> scheduleMedicineNotification({
    required Medicine medicine,
    required TimeOfDay doseTime,
    required int doseNumber,
  }) async {
    final settings = await _getNotificationSettings();
    if (!settings['enabled']!) {
      debugPrint('🔕 الإشعارات معطلة');
      return;
    }

    final DateTime? scheduledDate = _calculateNextScheduledDate(doseTime, medicine);
    if (scheduledDate == null) {
      debugPrint('⚠️ لا يوجد يوم مطابق');
      return;
    }

    final bool soundEnabled = settings['sound']!;
    final bool vibrationEnabled = settings['vibration']!;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelIdMedicine,
      _channelNameMedicine,
      channelDescription: _channelDescMedicine,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: vibrationEnabled,
      playSound: soundEnabled,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFF1B7B6E),
      colorized: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
      badgeNumber: 1,
      subtitle: 'medicine_time'.tr,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final int notificationId = (medicine.id ?? 0) * 10 + doseNumber;

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      _getMedicineNotificationTitle(medicine, doseNumber: doseNumber),
      _getMedicineNotificationBody(medicine, doseNumber: doseNumber),
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'medicine_${medicine.id}_$doseNumber',
    );

    debugPrint('⏰ تمت جدولة إشعار: $notificationId في $scheduledDate');
  }

  // ==========================================================
  // ✅ جدولة الإشعار + WorkManager معاً
  // ==========================================================
  Future<void> scheduleMedicineNotificationWithWorkManager({
    required Medicine medicine,
    required TimeOfDay doseTime,
    required int doseNumber,
  }) async {
    final settings = await _getNotificationSettings();
    if (!settings['enabled']!) {
      debugPrint('🔕 الإشعارات معطلة');
      return;
    }

    await cancelScheduledDose(medicine.id!, doseNumber);

    final DateTime? scheduledDate = _calculateNextScheduledDate(doseTime, medicine);
    if (scheduledDate == null) {
      debugPrint('⚠️ لا يوجد يوم مطابق');
      return;
    }

    final Duration initialDelay = scheduledDate.difference(DateTime.now());
    if (initialDelay.isNegative) {
      debugPrint('⚠️ التأخير سالب');
      return;
    }

    // 1️⃣ جدولة الإشعار
    await scheduleMedicineNotification(
      medicine: medicine,
      doseTime: doseTime,
      doseNumber: doseNumber,
    );

    // 2️⃣ جدولة WorkManager
    try {
      await Workmanager().registerOneOffTask(
        "medicine_${medicine.id}_$doseNumber",
        medicineDoseTask,
        initialDelay: initialDelay,
        inputData: {
          'medicineId': medicine.id,
          'doseNumber': doseNumber,
          'userId': medicine.userId ?? '',
        },
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );

      debugPrint('✅ تمت جدولة WorkManager للجرعة $doseNumber في $scheduledDate (المستخدم: ${medicine.userId})');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة WorkManager: $e');
    }
  }

  // ==========================================================
  // ✅ جدولة جميع جرعات الدواء
  // ==========================================================
  Future<void> scheduleAllDosesForMedicine({
    required Medicine medicine,
    required List<TimeOfDay> doseTimes,
  }) async {
    await cancelAllScheduledForMedicine(medicine.id!);

    for (int i = 0; i < doseTimes.length; i++) {
      await scheduleMedicineNotificationWithWorkManager(
        medicine: medicine,
        doseTime: doseTimes[i],
        doseNumber: i + 1,
      );
    }

    debugPrint('✅ تمت جدولة ${doseTimes.length} جرعات للدواء ${medicine.name}');
  }

  // ==========================================================
  // ✅ إلغاء الإشعارات + مهام WorkManager للدواء
  // ==========================================================
  Future<void> cancelAllScheduledForMedicine(int medicineId) async {
    for (int i = 1; i <= 5; i++) {
      await _notificationsPlugin.cancel(medicineId * 10 + i);
    }

    try {
      for (int i = 1; i <= 5; i++) {
        await Workmanager().cancelByUniqueName('medicine_${medicineId}_$i');
      }
      debugPrint('🔕 تم إلغاء مهام WorkManager للدواء $medicineId');
    } catch (e) {
      debugPrint('⚠️ خطأ في إلغاء مهام WorkManager: $e');
    }

    debugPrint('🔕 تم إلغاء جميع إشعارات الدواء $medicineId');
  }

  // ==========================================================
  // ✅ إلغاء إشعار جرعة معينة + مهمة WorkManager
  // ==========================================================
  Future<void> cancelScheduledDose(int medicineId, int doseNumber) async {
    await _notificationsPlugin.cancel(medicineId * 10 + doseNumber);

    try {
      await Workmanager().cancelByUniqueName('medicine_${medicineId}_$doseNumber');
      debugPrint('🔕 تم إلغاء مهمة WorkManager للجرعة $doseNumber');
    } catch (e) {
      debugPrint('⚠️ خطأ في إلغاء مهمة WorkManager: $e');
    }

    debugPrint('🔕 تم إلغاء الجرعة $doseNumber للدواء $medicineId');
  }

  // ==========================================================
  // ✅ إلغاء جميع الإشعارات + جميع مهام WorkManager
  // ==========================================================
  Future<void> cancelAllScheduledNotifications() async {
    await _notificationsPlugin.cancelAll();

    try {
      await Workmanager().cancelAll();
      debugPrint('🔕 تم إلغاء جميع مهام WorkManager');
    } catch (e) {
      debugPrint('⚠️ خطأ في إلغاء مهام WorkManager: $e');
    }

    debugPrint('🔕 تم إلغاء جميع الإشعارات المجدولة');
  }

  // ==========================================================
  // ✅ إشعار التناول اليدوي
  // ==========================================================
  Future<void> showManualTakeNotification({
    required String medicineName,
    required int remainingPills,
    required TimeOfDay scheduledTime,
  }) async {
    final settings = await _getNotificationSettings();
    if (!settings['enabled']!) return;

    final bool vibrationEnabled = settings['vibration']!;
    final bool soundEnabled = settings['sound']!;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelIdGeneral,
      _channelNameGeneral,
      channelDescription: _channelDescGeneral,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: vibrationEnabled,
      playSound: soundEnabled,
      icon: '@mipmap/ic_launcher',
      color: Colors.blue,
      colorized: true,
      category: AndroidNotificationCategory.event,
      visibility: NotificationVisibility.public,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
      badgeNumber: 1,
      subtitle: 'manual_medicine_take'.tr,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String title = '${'notification_manual'.tr} - $medicineName';

    final StringBuffer body = StringBuffer();
    body.write('${'took_pill_from'.tr} $medicineName ${'manually_period'.tr}\n');

    if (remainingPills == 0) {
      body.write('${'out_of_pills_refill'.tr}\n');
    } else {
      body.write('💊 ${'remaining_colon'.tr} $remainingPills ${'pill'.tr}.\n');
    }

    final String scheduledTimeStr =
        '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
    body.write('\n⏰ ${'note_outside_schedule'.tr} ($scheduledTimeStr)');

    await _notificationsPlugin.show(
      _manualTakeNotificationBase + (medicineName.hashCode.abs() % 1000),
      title, body.toString(), details,
      payload: 'manual_take',
    );

    debugPrint('🔔 تم إرسال إشعار تناول يدوي');
  }

  // ==========================================================
  // ⚠️ إشعار انخفاض المخزون
  // ==========================================================
  Future<void> showLowStockNotification(Medicine medicine, {bool isEmpty = false}) async {
    final settings = await _getNotificationSettings();
    if (!settings['enabled']!) return;

    final bool vibrationEnabled = settings['vibration']!;
    final bool soundEnabled = settings['sound']!;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelIdLowStock,
      _channelNameLowStock,
      channelDescription: _channelDescLowStock,
      importance: isEmpty ? Importance.high : Importance.defaultImportance,
      priority: isEmpty ? Priority.high : Priority.defaultPriority,
      enableVibration: vibrationEnabled,
      playSound: isEmpty && soundEnabled,
      icon: '@mipmap/ic_launcher',
      color: isEmpty ? Colors.red : Colors.orange,
      colorized: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: isEmpty && soundEnabled,
      badgeNumber: 1,
      subtitle: isEmpty ? 'important_alert'.tr : 'alert'.tr,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String title = isEmpty
        ? '${'notification_empty'.tr} ${medicine.name}'
        : '${'notification_low_stock'.tr} - ${medicine.name}';

    final String body = isEmpty
        ? '${'completely_empty_refill'.tr}'
        : '${'remaining'.tr} ${medicine.pillCount} ${'pills_only_from'.tr} ${medicine.name}.';

    await _notificationsPlugin.show(
      _lowStockNotificationBase + (medicine.id ?? 0),
      title, body, details,
      payload: 'lowstock_${medicine.id}',
    );
  }

  // ==========================================================
  // 🎉 إشعار نجاح إعادة التعبئة
  // ==========================================================
  Future<void> showRefillSuccessNotification({
    required String medicineName,
    required int addedPills,
    required int newTotal,
  }) async {
    final settings = await _getNotificationSettings();
    if (!settings['enabled']!) return;

    final bool vibrationEnabled = settings['vibration']!;
    final bool soundEnabled = settings['sound']!;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelIdGeneral,
      _channelNameGeneral,
      channelDescription: _channelDescGeneral,
      importance: Importance.low,
      priority: Priority.low,
      enableVibration: vibrationEnabled,
      playSound: soundEnabled,
      icon: '@mipmap/ic_launcher',
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: soundEnabled,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      _generalNotificationBase + 100,
      'refill_success'.tr,
      '${'added_successfully'.tr} $addedPills ${'pills_to'.tr} $medicineName.\n${'current_total'.tr} $newTotal ${'pill'.tr}.',
      details,
    );
  }

  // ==========================================================
  // 🧪 إشعار تجريبي
  // ==========================================================
  Future<void> showTestNotification() async {
    final settings = await _getNotificationSettings();
    final bool vibrationEnabled = settings['vibration']!;
    final bool soundEnabled = settings['sound']!;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelIdGeneral,
      _channelNameGeneral,
      channelDescription: _channelDescGeneral,
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      _generalNotificationBase + 999,
      '🧪 إشعار تجريبي',
      'تم إعداد نظام الإشعارات بنجاح!',
      details,
    );
  }

  // ==========================================================
  // ❌ إلغاء الإشعارات (للاستخدام العام)
  // ==========================================================
  Future<void> cancelMedicineNotification(int medicineId) async {
    await _notificationsPlugin.cancel(_medicineNotificationBase + medicineId);
    await _notificationsPlugin.cancel(_lowStockNotificationBase + medicineId);

    try {
      for (int i = 1; i <= 5; i++) {
        await Workmanager().cancelByUniqueName('medicine_${medicineId}_$i');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في إلغاء مهام WorkManager: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();

    try {
      await Workmanager().cancelAll();
    } catch (e) {
      debugPrint('⚠️ خطأ في إلغاء مهام WorkManager: $e');
    }

    debugPrint('🔕 تم إلغاء جميع الإشعارات');
  }

  // ==========================================================
  // 🎯 معالجات الضغط
  // ==========================================================
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: payload=${response.payload}');
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Background notification tapped: ${response.payload}');
  }

  // ==========================================================
  // 🛠️ دوال مساعدة
  // ==========================================================
  String _getMedicineNotificationTitle(Medicine medicine, {int? doseNumber}) {
    String doseLabel = '';
    if (doseNumber != null) {
      if (doseNumber == 1) {
        doseLabel = ' (${'first_dose'.tr})';
      } else if (doseNumber == 2) {
        doseLabel = ' (${'second_dose'.tr})';
      } else if (doseNumber == 3) {
        doseLabel = ' (${'third_dose'.tr})';
      }
    }

    if (medicine.pillCount == 1) {
      return '🔔 ${'notification_medicine'.tr}: ${medicine.name}$doseLabel ${'last_pill'.tr}';
    } else if (medicine.pillCount <= 3) {
      return '⚠️ ${'notification_medicine'.tr}: ${medicine.name}$doseLabel';
    } else {
      return '🔔 ${'notification_medicine'.tr}: ${medicine.name}$doseLabel';
    }
  }

  String _getMedicineNotificationBody(Medicine medicine, {int? doseNumber}) {
    final StringBuffer buffer = StringBuffer();

   /* if (doseNumber != null) {
      if (doseNumber == 1) {
        buffer.write('💊 ${'first_dose'.tr}\n');
      } else if (doseNumber == 2) {
        buffer.write('💊 ${'second_dose'.tr}\n');
      } else if (doseNumber == 3) {
        buffer.write('💊 ${'third_dose'.tr}\n');
      }
    }*/

    //buffer.write('${'remaining_colon'.tr} ${medicine.pillCount-1} ${'pill'.tr}.');

    if (medicine.pillCount == 1) {
      buffer.write('\n${'last_pill_refill'.tr}');
    } else if (medicine.pillCount <= 3) {
      buffer.write('\n${'low_stock_refill'.tr}');
    }
    return buffer.toString();
  }
}