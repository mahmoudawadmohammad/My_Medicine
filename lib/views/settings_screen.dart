// ============================================================
// ملف: settings_screen.dart
// المسار: lib/views/settings/settings_screen.dart
// الوصف: صفحة الإعدادات - تسمح للمستخدم بتخصيص التطبيق
//         مع تطبيق فوري للإعدادات
//         + خيار "حسب النظام" للوضع واللغة
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/notification_helper.dart';
import '../services/auth_service.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/constants/app_colors.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

// ⚙️ SettingsScreen: صفحة إعدادات التطبيق
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  // ==========================================================
  // متغيرات حالة الإعدادات
  // ==========================================================

  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // نسخة من مساعد الإشعارات
  final NotificationHelper _notificationHelper = NotificationHelper();

  // نسخة من خدمة المصادقة
  final AuthService _authService = Get.find<AuthService>();

  // نسخة من المتحكمات
  final ThemeController _themeController = Get.find<ThemeController>();
  final LanguageController _languageController = Get.find<LanguageController>();

  // ==========================================================
  // initState
  // ==========================================================
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ==========================================================
  // تحميل الإعدادات
  // ==========================================================
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });

    debugPrint('📂 تم تحميل الإعدادات: إشعارات=$_notificationsEnabled');
  }

  // ==========================================================
  // حفظ إعدادات الإشعارات
  // ==========================================================
  Future<void> _saveNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
  }

  // ==========================================================
  // تغيير الإشعارات
  // ==========================================================
  Future<void> _onNotificationsChanged(bool value) async {
    setState(() {
      _notificationsEnabled = value;
      if (!value) {
        _soundEnabled = false;
        _vibrationEnabled = false;
      }
    });

    await _saveNotificationSettings();

    if (value) {
      await _notificationHelper.initialize();
      _showSnackBar('notifications_enabled'.tr, Colors.green);
    } else {
      await _notificationHelper.cancelAllNotifications();
      _showSnackBar('notifications_disabled'.tr, Colors.orange);
    }
  }

  // ==========================================================
  // تغيير الصوت
  // ==========================================================
  Future<void> _onSoundChanged(bool value) async {
    setState(() => _soundEnabled = value);
    await _saveNotificationSettings();
    _showSnackBar(
        value ? 'sound_enabled'.tr : 'sound_disabled'.tr,
        value ? Colors.green : Colors.orange
    );
  }

  // ==========================================================
  // عرض SnackBar
  // ==========================================================
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 16,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==========================================================
  // إعادة تعيين الإعدادات
  // ==========================================================
  Future<void> _resetSettings() async {
    setState(() {
      _notificationsEnabled = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
    });

    await _saveNotificationSettings();
    await _notificationHelper.initialize();

    // ✅ إعادة تعيين الثيم واللغة إلى 'system'
    await _themeController.setThemeMode('system');
    await _languageController.changeLanguage('system');

    _showSnackBar('settings_reset'.tr, Colors.green);
  }

  // ==========================================================
  // إعادة جولة التعريف
  // ==========================================================
  Future<void> _resetOnboarding() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'reset_onboarding'.tr,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'reset_onboarding_confirm'.tr,
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr, style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'yes'.tr,
              style: GoogleFonts.cairo(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstTime', true);
      Get.offAll(() => const OnboardingScreen());
    }
  }

  // ==========================================================
  // حوار تأكيد تسجيل الخروج
  // ==========================================================
  Future<void> _confirmLogout(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Text(
                'confirm_logout'.tr,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'confirm_logout_message'.tr,
            style: GoogleFonts.cairo(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr, style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _authService.signOut();
                Get.offAll(() => const LoginScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'logout'.tr,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // بناء واجهة المستخدم
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'settings'.tr,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Get.back(),
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [

            // ==================================================
            // قسم الإشعارات
            // ==================================================
            _buildSectionHeader(
              icon: Icons.notifications_outlined,
              title: 'notifications'.tr,
            ),

            _buildSettingsCard(
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'enable_notifications'.tr,
                  subtitle: 'notifications_desc'.tr,
                  value: _notificationsEnabled,
                  onChanged: _onNotificationsChanged,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.volume_up_outlined,
                  title: 'sound'.tr,
                  subtitle: 'sound_desc'.tr,
                  value: _soundEnabled,
                  enabled: _notificationsEnabled,
                  onChanged: _onSoundChanged,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ✅ قسم المظهر - مع خيار "حسب النظام"
            // ==================================================
            _buildSectionHeader(
              icon: Icons.palette_outlined,
              title: 'appearance'.tr,
            ),

            _buildSettingsCard(
              children: [
                // ✅ ListTile لاختيار الوضع
                Obx(() {
                  final currentMode = _themeController.themeModeString;
                  String modeText;
                  IconData modeIcon;

                  switch (currentMode) {
                    case 'light':
                      modeText = 'light_mode'.tr;
                      modeIcon = Icons.light_mode;
                      break;
                    case 'dark':
                      modeText = 'dark_mode'.tr;
                      modeIcon = Icons.dark_mode;
                      break;
                    case 'system':
                    default:
                      modeText = 'follow_system'.tr;
                      modeIcon = Icons.brightness_auto;
                      break;
                  }

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        modeIcon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      'theme_mode'.tr,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'theme_mode_desc'.tr,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          modeText,
                          style: GoogleFonts.cairo(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                    onTap: () => _showThemeModeDialog(),
                  );
                }),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ✅ قسم اللغة - مع خيار "حسب النظام"
            // ==================================================
            _buildSectionHeader(
              icon: Icons.language_outlined,
              title: 'language'.tr,
            ),

            _buildSettingsCard(
              children: [
                Obx(() {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      'language'.tr,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'language_desc'.tr,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _languageController.currentLanguageName,
                          style: GoogleFonts.cairo(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                    onTap: () => _showLanguageDialog(),
                  );
                }),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // قسم متقدم
            // ==================================================
            _buildSectionHeader(
              icon: Icons.settings_outlined,
              title: 'advanced'.tr,
            ),

            _buildSettingsCard(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.refresh_outlined, color: Colors.orange),
                  ),
                  title: Text(
                    'reset_settings'.tr,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'reset_settings_desc'.tr,
                    style: GoogleFonts.cairo(fontSize: 13),
                  ),
                  onTap: _resetSettings,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    'reset_onboarding'.tr,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'reset_onboarding_desc'.tr,
                    style: GoogleFonts.cairo(fontSize: 13),
                  ),
                  onTap: _resetOnboarding,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // قسم الحساب
            // ==================================================
            _buildSectionHeader(
              icon: Icons.account_circle_outlined,
              title: 'account'.tr,
            ),

            _buildSettingsCard(
              children: [
                Obx(() {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.email_outlined, color: Colors.blue),
                    ),
                    title: Text(
                      'email'.tr,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _authService.userEmail ?? 'not_logged_in'.tr,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  );
                }),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout, color: Colors.red),
                  ),
                  title: Text(
                    'logout'.tr,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  subtitle: Text(
                    'logout_description'.tr,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // معلومات التطبيق
            // ==================================================
            _buildSectionHeader(
              icon: Icons.info_outline,
              title: 'about'.tr,
            ),

            _buildSettingsCard(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline, color: Colors.blue),
                  ),
                  title: Text(
                    'version'.tr,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('1.0.0', style: GoogleFonts.cairo(fontSize: 13)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'updated'.tr,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.copyright_outlined, color: Colors.purple),
                  ),
                  title: Text(
                    'rights'.tr,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${'app_name'.tr} 2026 ©',
                    style: GoogleFonts.cairo(fontSize: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ويدجت مساعد: عنوان القسم
  // ==========================================================
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ويدجت مساعد: بطاقة الإعدادات
  // ==========================================================
  Widget _buildSettingsCard({
    required List<Widget> children,
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
      child: Column(children: children),
    );
  }

  // ==========================================================
  // ✅ حوار اختيار وضع الثيم (جديد)
  // ==========================================================
  void _showThemeModeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'theme_mode'.tr,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ خيار "حسب النظام"
              RadioListTile<String>(
                title: Text(
                  '🌓 ${'follow_system'.tr}',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'follow_system_desc'.tr,
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                ),
                value: 'system',
                groupValue: _themeController.themeModeString,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) async {
                  Navigator.pop(context);
                  await _themeController.setThemeMode(value!);
                  if (mounted) {
                    _showSnackBar('theme_mode_changed'.tr, Colors.green);
                  }
                },
              ),
              // ✅ خيار "فاتح"
              RadioListTile<String>(
                title: Text(
                  '☀️ ${'light_mode'.tr}',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                ),
                value: 'light',
                groupValue: _themeController.themeModeString,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) async {
                  Navigator.pop(context);
                  await _themeController.setThemeMode(value!);
                  if (mounted) {
                    _showSnackBar('theme_mode_changed'.tr, Colors.green);
                  }
                },
              ),
              // ✅ خيار "داكن"
              RadioListTile<String>(
                title: Text(
                  '🌙 ${'dark_mode'.tr}',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                ),
                value: 'dark',
                groupValue: _themeController.themeModeString,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) async {
                  Navigator.pop(context);
                  await _themeController.setThemeMode(value!);
                  if (mounted) {
                    _showSnackBar('theme_mode_changed'.tr, Colors.green);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // ✅ حوار اختيار اللغة (معدل - يدعم "حسب النظام")
  // ==========================================================
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'language'.tr,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ خيار "حسب النظام"
              RadioListTile<String>(
                title: Text(
                  '🌐 ${'follow_system'.tr}',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'follow_system_lang_desc'.tr,
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                ),
                value: 'system',
                groupValue: _languageController.currentLanguage.value,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) async {
                  Navigator.pop(context);
                  await _languageController.changeLanguage(value!);
                  if (mounted) {
                    _showSnackBar('language_changed'.tr, Colors.green);
                  }
                },
              ),
              // ✅ اللغات المدعومة
              ...LanguageController.supportedLanguages.map((lang) {
                return RadioListTile<String>(
                  title: Text(
                    '${lang['flag']} ${lang['name']}',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                  ),
                  value: lang['code'] as String,
                  groupValue: _languageController.currentLanguage.value,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) async {
                    Navigator.pop(context);
                    await _languageController.changeLanguage(value!);
                    if (mounted) {
                      _showSnackBar('language_changed'.tr, Colors.green);
                    }
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // ويدجت مساعد: مفتاح تبديل
  // ==========================================================
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
    bool enabled = true,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w500,
          color: enabled ? Theme.of(context).colorScheme.onSurface : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.cairo(
          fontSize: 13,
          color: enabled ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey[400],
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}