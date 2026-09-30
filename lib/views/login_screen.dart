// ============================================================
// ملف: login_screen.dart
// المسار: lib/views/auth/login_screen.dart
// الوصف: شاشة تسجيل الدخول
//         تدعم الوضع الليلي والنهاري واللغتين العربية والإنجليزية
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';              // واجهات Flutter
import 'package:get/get.dart';                       // GetX للتنقل وإدارة الحالة
import 'package:google_fonts/google_fonts.dart';     // الخطوط العربية
import 'package:flutter_animate/flutter_animate.dart'; // الحركات

import '../services/auth_service.dart';      // خدمة المصادقة
import 'register_screen.dart';                       // شاشة إنشاء حساب
import 'forgot_password_screen.dart';                // شاشة نسيت كلمة المرور
import 'home_screen.dart';                   // الصفحة الرئيسية

// 🔐 LoginScreen: شاشة تسجيل الدخول
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ==========================================================
  // مفاتيح ومتحكمات النموذج
  // ==========================================================

  // _formKey: مفتاح النموذج للتحقق من صحة البيانات
  final _formKey = GlobalKey<FormState>();

  // متحكمات النصوص
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ==========================================================
  // متغيرات الحالة
  // ==========================================================

  // هل كلمة المرور مخفية؟
  bool _obscurePassword = true;

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
    _passwordController.dispose();
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
                  // الشعار (Logo)
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
                        Icons.medication,
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
                    'welcome_back'.tr,
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

                  const SizedBox(height: 8),

                  // ==========================================
                  // العنوان الفرعي
                  // ==========================================
                  Text(
                    'login_to_continue'.tr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: onSurfaceColor.withOpacity(0.6),
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

                  const SizedBox(height: 16),

                  // ==========================================
                  // حقل كلمة المرور
                  // ==========================================
                  _buildPasswordField(primaryColor, surfaceColor, onSurfaceColor)
                      .animate(delay: 500.ms)
                      .slideX(begin: -0.2, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 12),

                  // ==========================================
                  // زر نسيت كلمة المرور
                  // ==========================================
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () {
                        Get.to(() => const ForgotPasswordScreen());
                      },
                      child: Text(
                        'forgot_password'.tr,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ==========================================
                  // زر تسجيل الدخول
                  // ==========================================
                  _buildLoginButton(primaryColor)
                      .animate(delay: 700.ms)
                      .slideY(begin: 0.2, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 30),

                  // ==========================================
                  // فاصل "أو"
                  // ==========================================
                  _buildOrDivider(onSurfaceColor)
                      .animate(delay: 800.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ==========================================
                  // زر إنشاء حساب جديد
                  // ==========================================
                  _buildRegisterPrompt(primaryColor, onSurfaceColor)
                      .animate(delay: 900.ms)
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
        textInputAction: TextInputAction.next,     // زر التالي
        textDirection: TextDirection.ltr,          // البريد دائماً LTR
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
          // التحقق من صيغة البريد الإلكتروني
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
  // حقل كلمة المرور
  // ==========================================================
  Widget _buildPasswordField(Color primaryColor, Color surfaceColor, Color onSurfaceColor) {
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
        controller: _passwordController,
        obscureText: _obscurePassword,              // إخفاء كلمة المرور
        textInputAction: TextInputAction.done,      // زر Done
        onFieldSubmitted: (_) => _login(),          // تنفيذ عند الضغط على Done
        decoration: InputDecoration(
          labelText: 'password'.tr,
          hintText: '••••••••',
          prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
          // زر إظهار/إخفاء كلمة المرور
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: onSurfaceColor.withOpacity(0.5),
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
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
          if (value == null || value.isEmpty) {
            return 'field_required'.tr;
          }
          if (value.length < 6) {
            return 'password_too_short'.tr;
          }
          return null;
        },
      ),
    );
  }

  // ==========================================================
  // زر تسجيل الدخول
  // ==========================================================
  Widget _buildLoginButton(Color primaryColor) {
    return Obx(() {
      // استخدام Obx لمتابعة حالة التحميل
      final isLoading = _authService.isLoading;

      return ElevatedButton(
        onPressed: isLoading ? null : _login,  // تعطيل الزر أثناء التحميل
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
        // مؤشر التحميل أثناء العملية
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
              'login'.tr,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.login, size: 22),
          ],
        ),
      );
    });
  }

  // ==========================================================
  // فاصل "أو"
  // ==========================================================
  Widget _buildOrDivider(Color onSurfaceColor) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: onSurfaceColor.withOpacity(0.2),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or'.tr,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: onSurfaceColor.withOpacity(0.5),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: onSurfaceColor.withOpacity(0.2),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // دعوة لإنشاء حساب
  // ==========================================================
  Widget _buildRegisterPrompt(Color primaryColor, Color onSurfaceColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'no_account'.tr,
          style: GoogleFonts.cairo(
            fontSize: 15,
            color: onSurfaceColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            Get.to(() => const RegisterScreen());
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            'create_account_now'.tr,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ✅ دالة تسجيل الدخول
  // ==========================================================
  Future<void> _login() async {
    // 1️⃣ التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2️⃣ إخفاء لوحة المفاتيح
    FocusScope.of(context).unfocus();

    // 3️⃣ محاولة تسجيل الدخول
    final success = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // 4️⃣ إذا نجح، انتقل للصفحة الرئيسية
    if (success && mounted) {
      Get.offAll(() => const HomeScreen());
    }
  }
}