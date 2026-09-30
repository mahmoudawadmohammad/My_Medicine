// ============================================================
// ملف: register_screen.dart
// المسار: lib/views/auth/register_screen.dart
// الوصف: شاشة إنشاء حساب جديد
//         تدعم الوضع الليلي والنهاري واللغتين العربية والإنجليزية
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';              // واجهات Flutter
import 'package:get/get.dart';                       // GetX للتنقل وإدارة الحالة
import 'package:google_fonts/google_fonts.dart';     // الخطوط العربية
import 'package:flutter_animate/flutter_animate.dart'; // الحركات

import '../services/auth_service.dart';      // خدمة المصادقة
import 'home_screen.dart';                   // الصفحة الرئيسية

// 📝 RegisterScreen: شاشة إنشاء حساب جديد
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ==========================================================
  // مفاتيح ومتحكمات النموذج
  // ==========================================================

  // _formKey: مفتاح النموذج للتحقق من صحة البيانات
  final _formKey = GlobalKey<FormState>();

  // متحكمات النصوص
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // ==========================================================
  // متغيرات الحالة
  // ==========================================================

  // هل كلمة المرور مخفية؟
  bool _obscurePassword = true;

  // هل تأكيد كلمة المرور مخفي؟
  bool _obscureConfirmPassword = true;

  // هل وافق المستخدم على الشروط؟
  bool _acceptedTerms = false;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        backgroundColor: Colors.transparent, // شفاف
        elevation: 0,                         // بدون ظل
        foregroundColor: onSurfaceColor,      // لون الأيقونات
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),        // الرجوع للصفحة السابقة
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
                  // ==========================================
                  // الشعار (Logo)
                  // ==========================================
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
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
                        Icons.person_add,
                        size: 50,
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
                    'create_your_account'.tr,
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
                    'register_to_continue'.tr,
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
                  // حقل الاسم الكامل
                  // ==========================================
                  _buildNameField(primaryColor, surfaceColor, onSurfaceColor)
                      .animate(delay: 400.ms)
                      .slideX(begin: -0.2, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 16),

                  // ==========================================
                  // حقل البريد الإلكتروني
                  // ==========================================
                  _buildEmailField(primaryColor, surfaceColor, onSurfaceColor)
                      .animate(delay: 500.ms)
                      .slideX(begin: -0.2, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 16),

                  // ==========================================
                  // حقل كلمة المرور
                  // ==========================================
                  _buildPasswordField(primaryColor, surfaceColor, onSurfaceColor)
                      .animate(delay: 600.ms)
                      .slideX(begin: -0.2, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 16),

                  // ==========================================
                  // حقل تأكيد كلمة المرور
                  // ==========================================
                  _buildConfirmPasswordField(primaryColor, surfaceColor, onSurfaceColor)
                      .animate(delay: 700.ms)
                      .slideX(begin: -0.2, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 16),

                  // ==========================================
                  // الموافقة على الشروط
                  // ==========================================
                  _buildTermsCheckbox(primaryColor, onSurfaceColor)
                      .animate(delay: 800.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 30),

                  // ==========================================
                  // زر إنشاء الحساب
                  // ==========================================
                  _buildRegisterButton(primaryColor)
                      .animate(delay: 900.ms)
                      .slideY(begin: 0.2, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 30),

                  // ==========================================
                  // دعوة لتسجيل الدخول
                  // ==========================================
                  _buildLoginPrompt(primaryColor, onSurfaceColor)
                      .animate(delay: 1000.ms)
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
  // حقل الاسم الكامل
  // ==========================================================
  Widget _buildNameField(Color primaryColor, Color surfaceColor, Color onSurfaceColor) {
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
        controller: _nameController,
        keyboardType: TextInputType.name,       // لوحة مفاتيح النص
        textInputAction: TextInputAction.next,  // زر التالي
        textCapitalization: TextCapitalization.words, // أول حرف كبير
        decoration: InputDecoration(
          labelText: 'name'.tr,
          hintText: 'enter_full_name'.tr,
          prefixIcon: Icon(Icons.person_outline, color: primaryColor),
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
          if (value == null || value.trim().isEmpty) {
            return 'field_required'.tr;
          }
          if (value.trim().length < 3) {
            return 'name_too_short'.tr;
          }
          return null;
        },
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
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        textDirection: TextDirection.ltr,        // البريد LTR دائماً
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
          if (value == null || value.trim().isEmpty) {
            return 'field_required'.tr;
          }
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
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: 'password'.tr,
          hintText: '••••••••',
          prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
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
  // حقل تأكيد كلمة المرور
  // ==========================================================
  Widget _buildConfirmPasswordField(Color primaryColor, Color surfaceColor, Color onSurfaceColor) {
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
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _register(),   // تنفيذ عند الضغط على Done
        decoration: InputDecoration(
          labelText: 'confirm_password'.tr,
          hintText: '••••••••',
          prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: onSurfaceColor.withOpacity(0.5),
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
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
          // ✅ التحقق من تطابق كلمتي المرور
          if (value != _passwordController.text) {
            return 'passwords_not_match'.tr;
          }
          return null;
        },
      ),
    );
  }

  // ==========================================================
  // الموافقة على الشروط
  // ==========================================================
  Widget _buildTermsCheckbox(Color primaryColor, Color onSurfaceColor) {
    return Row(
      children: [
        // ===== Checkbox =====
        Checkbox(
          value: _acceptedTerms,
          activeColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          onChanged: (value) {
            setState(() {
              _acceptedTerms = value ?? false;
            });
          },
        ),
        // ===== نص الموافقة =====
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptedTerms = !_acceptedTerms;
              });
            },
            child: Text(
              'accept_terms'.tr,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: onSurfaceColor.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // زر إنشاء الحساب
  // ==========================================================
  Widget _buildRegisterButton(Color primaryColor) {
    return Obx(() {
      final isLoading = _authService.isLoading;

      return ElevatedButton(
        onPressed: (isLoading || !_acceptedTerms) ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: primaryColor.withOpacity(0.4),
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'register'.tr,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.person_add, size: 22),
          ],
        ),
      );
    });
  }

  // ==========================================================
  // دعوة لتسجيل الدخول
  // ==========================================================
  Widget _buildLoginPrompt(Color primaryColor, Color onSurfaceColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'have_account'.tr,
          style: GoogleFonts.cairo(
            fontSize: 15,
            color: onSurfaceColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            'login_now'.tr,
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
  // ✅ دالة إنشاء الحساب
  // ==========================================================
  Future<void> _register() async {
    // 1️⃣ التحقق من الموافقة على الشروط
    if (!_acceptedTerms) {
      Get.snackbar(
        'warning_alert'.tr,
        'must_accept_terms'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
      return;
    }

    // 2️⃣ التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 3️⃣ إخفاء لوحة المفاتيح
    FocusScope.of(context).unfocus();

    // 4️⃣ محاولة إنشاء الحساب
    final success = await _authService.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // 5️⃣ إذا نجح، انتقل للصفحة الرئيسية
    if (success && mounted) {
      Get.offAll(() => const HomeScreen());
    }
  }
}