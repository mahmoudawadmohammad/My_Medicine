// ============================================================
// ملف: splash_screen.dart
// الوصف: شاشة البداية الجميلة التي تظهر أثناء تحميل التطبيق
//         تستخدم أيقونات Flutter المدمجة فقط (بدون صور خارجية)
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  // ===== إعداد الحركات =====
  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        // ===== خلفية متدرجة جميلة =====
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              AppColors.secondary,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ===== عناصر زخرفية في الخلفية =====
            _buildBackgroundDecorations(size),

            // ===== المحتوى الرئيسي =====
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ===== الشعار (Logo) =====
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: _buildLogo(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // ===== اسم التطبيق =====
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: _buildAppName(),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  // ===== شعار التطبيق (بالعربية) =====
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: _buildAppNameArabic(),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // ===== مؤشر التحميل =====
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: _buildLoadingIndicator(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ===== تذييل الصفحة =====
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value * 0.7,
                    child: _buildFooter(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== بناء العناصر الزخرفية في الخلفية =====
  Widget _buildBackgroundDecorations(Size size) {
    return Stack(
      children: [
        // دائرة كبيرة في الأعلى
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.05),
            ),
          ),
        ),

        // دائرة متوسطة في الأسفل
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.08),
            ),
          ),
        ),

        // دائرة صغيرة
        Positioned(
          top: size.height * 0.3,
          left: -30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
            ),
          ),
        ),

        // نقاط زخرفية
        ...List.generate(8, (index) {
          return Positioned(
            top: (index * 90).toDouble() % size.height,
            left: (index * 50).toDouble() % size.width,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===== بناء الشعار باستخدام أيقونات Flutter المدمجة =====
  Widget _buildLogo() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.25),
            Theme.of(context).colorScheme.surface.withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الأيقونة الرئيسية - صندوق الدواء
          Icon(
            Icons.medication,
            size: 75,
            color: Theme.of(context).colorScheme.surface,
          ),

          // أيقونة قلب صغيرة في الأسفل
          Positioned(
            bottom: 35,
            right: 35,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
              ),
              child: Icon(
                Icons.favorite,
                size: 25,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),

          // أيقونة صندوق صغيرة في الأعلى
          Positioned(
            top: 30,
            left: 30,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
              ),
              child: Icon(
                Icons.inbox,
                size: 18,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),

          // أيقونة نجمة صغيرة
          Positioned(
            top: 50,
            right: 25,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.15),
              ),
              child: Icon(
                Icons.star,
                size: 12,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .shimmer(duration: 2000.ms)
        .then()
        .rotate(duration: 1000.ms, begin: 0.02, end: -0.02)
        .then()
        .rotate(duration: 1000.ms, begin: -0.02, end: 0.02);
  }

  // ===== بناء اسم التطبيق (إنجليزي) =====
  Widget _buildAppName() {
    return Text(
      'My Medicine',
      style: GoogleFonts.cairo(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.surface,
        letterSpacing: 1.5,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    )
        .animate()
        .shimmer(duration: 2000.ms, color: Theme.of(context).colorScheme.surface.withOpacity(0.3))
        .then()
        .scale(
      begin: const Offset(1, 1),
      end: const Offset(1.1, 1.1),
      duration: 700.ms,
    );
  }

  // ===== بناء اسم التطبيق (عربي) =====
  Widget _buildAppNameArabic() {
    return Text(
      'دوائي',
      style: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        letterSpacing: 1.0,
      ),
    )
        .animate(delay: 300.ms)
        .fadeIn(duration: 800.ms)
        .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }

  // ===== بناء مؤشر التحميل =====
  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.surface),
            strokeWidth: 3,
            backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'loading'.tr,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ),
        )
            .animate(onComplete: (controller) => controller.repeat())
            .fadeOut(duration: 800.ms)
            .then()
            .fadeIn(duration: 800.ms),
      ],
    );
  }

  // ===== بناء تذييل الصفحة =====
  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '© 2026 Smart Pillbox',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite,
              size: 12,
              color: Colors.red,
            ),
            const SizedBox(width: 5),
            Text(
              'for_your_health'.tr,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}