// ============================================================
// ملف: forgot_password_screen.dart
// المسار: lib/views/auth/forgot_password_screen.dart
// الوصف: شاشة نسيت كلمة المرور - إرسال رابط إعادة التعيين
//         تدعم الوضع الليلي والنهاري واللغتين العربية والإنجليزية
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';              // واجهات Flutter
import 'package:get/get.dart';                       // GetX للتنقل وإدارة الحالة
import 'package:google_fonts/google_fonts.dart';     // الخطوط العربية
import 'package:flutter_animate/flutter_animate.dart'; // الحركات

import '../services/auth_service.dart';      // خدمة المصادقة

// 🔑 ForgotPasswordScreen: شاشة نسيت كلمة المرور
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // ==========================================================
  // مفاتيح ومتحكمات النموذج
  // ==========================================================

  // _formKey: مفتاح النموذج للتحقق من صحة البيانات
  final _formKey = GlobalKey<FormState>();

  // متحكم البريد الإلكتروني
  final TextEditingController _emailController = TextEditingController();

  // ==========================================================
  // الحصول على الخدمات
  // ==========================================================

  // AuthService: خدمة المصادقة
  final AuthService _authService = Get.find<AuthService>();

  // ==========================================================
  // دورة الحياة
  // ==========================================================

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ==========================================================
  // بناء الواجهة
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // ✅ استخراج الألوان من الثيم (يدعم الوضع الليلي)
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      // ===== الخلفية =====
      backgroundColor: scaffoldBg,

      // ===== شريط التطبيق =====
      appBar: AppBar(
        backgroundColor: Colors.transparent,  // شفاف
        elevation: 0,                          // بدون ظل
        foregroundColor: onSurfaceColor,       // لون الأيقونات
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),         // الرجوع
        ),
      ),

      // ===== جسم الصفحة =====
      body: GestureDetector(
        // إخفاء لوحة المفاتيح عند الضغط خارج الحقول
        onTap: () => FocusScope.of(context).unfocus(),

        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // ==========================================
                  // الشعار (Logo) - أيقونة قفل
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
                            primaryColor,
                            primaryColor.withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 30),

                  // ==========================================
                  // العنوان الرئيسي
                  // ==========================================
                  Text(
                    'forgot_password'.tr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceColor,
                    ),
                  )
                      .animate(delay: 200.ms)
                      .slideY(begin: 0.3, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 12),

                  // ==========================================
                  // العنوان الفرعي
                  // ==========================================
                  Text(
                    'enter_email_to_reset'.tr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: onSurfaceColor.withOpacity(0.6),
                      height: 1.5,
                    ),
                  )
                      .animate(delay: 300.ms)
                      .slideY(begin: 0.3, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 40),

                  // ==========================================
                  // حقل البريد الإلكتروني
                  // ==========================================
                  _buildEmailField(primaryColor, surfaceColor, onSurfaceColor)
                      .animate(delay: 400.ms)
                      .slideX(begin: -0.2, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 30),

                  // ==========================================
                  // زر إرسال رابط إعادة التعيين
                  // ==========================================
                  _buildResetButton(primaryColor)
                      .animate(delay: 500.ms)
                      .slideY(begin: 0.2, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ==========================================
                  // زر العودة لتسجيل الدخول
                  // ==========================================
                  _buildBackToLoginButton(primaryColor, onSurfaceColor)
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 30),

                  // ==========================================
                  // ملاحظة إرشادية
                  // ==========================================
                  _buildInfoNote(primaryColor, onSurfaceColor)
                      .animate(delay: 700.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // حقل البريد الإلكتروني
  // ==========================================================
  Widget _buildEmailField(Color primaryColor, Color surfaceColor, Color onSurfaceColor) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,  // لوحة مفاتيح البريد
        textInputAction: TextInputAction.done,     // زر Done
        textDirection: TextDirection.ltr,          // البريد LTR دائماً
        onFieldSubmitted: (_) => _resetPassword(), // تنفيذ عند Done
        decoration: InputDecoration(
          labelText: 'email'.tr,
          hintText: 'example@email.com',
          prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: surfaceColor,
          labelStyle: GoogleFonts.cairo(),
          hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        style: GoogleFonts.cairo(fontSize: 16),
        validator: (value) {
          // التحقق من أن الحقل غير فارغ
          if (value == null || value.trim().isEmpty) {
            return 'field_required'.tr;
          }
          // التحقق من صيغة البريد
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value.trim())) {
            return 'invalid_email_format'.tr;
          }
          return null;
        },
      ),
    );
  }

  // ==========================================================
  // زر إرسال رابط إعادة التعيين
  // ==========================================================
  Widget _buildResetButton(Color primaryColor) {
    return Obx(() {
      // استخدام Obx لمتابعة حالة التحميل
      final isLoading = _authService.isLoading;

      return ElevatedButton(
        onPressed: isLoading ? null : _resetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: primaryColor.withOpacity(0.4),
        ),
        child: isLoading
        // مؤشر التحميل
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
        // نص الزر
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'send_reset_link'.tr,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.send, size: 22),
          ],
        ),
      );
    });
  }

  // ==========================================================
  // زر العودة لتسجيل الدخول
  // ==========================================================
  Widget _buildBackToLoginButton(Color primaryColor, Color onSurfaceColor) {
    return Center(
      child: TextButton.icon(
        onPressed: () => Get.back(),  // الرجوع
        icon: const Icon(Icons.arrow_back, size: 18),
        label: Text(
          'back_to_login'.tr,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  // ==========================================================
  // ملاحظة إرشادية
  // ==========================================================
  Widget _buildInfoNote(Color primaryColor, Color onSurfaceColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: primaryColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'reset_info_note'.tr,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: onSurfaceColor.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ✅ دالة إرسال رابط إعادة التعيين
  // ==========================================================
  Future<void> _resetPassword() async {
    // 1️⃣ التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2️⃣ إخفاء لوحة المفاتيح
    FocusScope.of(context).unfocus();

    // 3️⃣ إرسال رابط إعادة التعيين
    final success = await _authService.resetPassword(
      _emailController.text.trim(),
    );

    // 4️⃣ إذا نجح، نعرض رسالة نجاح ونعود للصفحة السابقة
    if (success && mounted) {
      // إظهار حوار نجاح
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final primaryColor = Theme.of(context).colorScheme.primary;
          final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'success'.tr,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'reset_email_sent'.tr,
              style: GoogleFonts.cairo(
                fontSize: 15,
                color: onSurfaceColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);  // إغلاق الحوار
                  Get.back();              // الرجوع لصفحة الدخول
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
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
                  'ok'.tr,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}