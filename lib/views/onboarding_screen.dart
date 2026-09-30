// ============================================================
// ملف: onboarding_screen.dart
// الوصف: شاشة التعريف الأولى التي تظهر للمستخدم الجديد
//         تستخدم أيقونات Flutter المدمجة فقط (بدون صور خارجية)
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
//import 'package:smart_pillbox/views/home_screen.dart';
import 'package:smart_pillbox/views/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final LiquidController _liquidController = LiquidController();
  int _currentPage = 0;

  // ===== بيانات صفحات التعريف (باستخدام أيقونات Flutter المدمجة) =====
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'onboarding_title1'.tr,
      'subtitle': 'onboarding_subtitle1'.tr,
      'mainIcon': Icons.health_and_safety,
      'smallIcon': Icons.favorite,
      'extraIcon': Icons.medical_services,
      'color': const Color(0xFF1B7B6E),
    },
    {
      'title': 'onboarding_title2'.tr,
      'subtitle': 'onboarding_subtitle2'.tr,
      'mainIcon': Icons.category,
      'smallIcon': Icons.folder_special,
      'extraIcon': Icons.label,
      'color': const Color(0xFF2E8B57),
    },
    {
      'title': 'onboarding_title3'.tr,
      'subtitle': 'onboarding_subtitle3'.tr,
      'mainIcon': Icons.calendar_month,
      'smallIcon': Icons.schedule,
      'extraIcon': Icons.alarm,
      'color': const Color(0xFF3CB371),
    },
    {
      'title': 'onboarding_title4'.tr,
      'subtitle': 'onboarding_subtitle4'.tr,
      'mainIcon': Icons.notifications_active,
      'smallIcon': Icons.alarm,
      'extraIcon': Icons.notification_important,
      'color': const Color(0xFF20B2AA),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===== Liquid Swipe: المحتوى الرئيسي =====
          LiquidSwipe(
            pages: _buildPages(),
            liquidController: _liquidController,
            enableSideReveal: true,
            slideIconWidget: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.surface,
            ),
            positionSlideIcon: 0.8,
            waveType: WaveType.liquidReveal,
            onPageChangeCallback: (index) {
              setState(() {
                _currentPage = index;
              });
            },
          ),

          // ===== زر التخطي =====
          _buildSkipButton(),

          // ===== زر "هيا نبدأ" =====
          _buildGetStartedButton(),

          // ===== مؤشر الصفحات =====
          _buildPageIndicator(),
        ],
      ),
    );
  }

  // ===== بناء صفحات Liquid Swipe =====
  List<Widget> _buildPages() {
    return _onboardingData.map((data) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              data['color'],
              data['color'].withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ===== أيقونة الصفحة =====
              _buildPageIcon(data)
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 50),

              // ===== عنوان الصفحة =====
              Text(
                data['title'],
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.surface,
                  height: 1.3,
                ),
              )
                  .animate()
                  .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 20),

              // ===== النص الفرعي =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  data['subtitle'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              )
                  .animate(delay: 200.ms)
                  .slideY(begin: 0.3, end: 0, duration: 500.ms)
                  .fadeIn(duration: 500.ms),

              const Spacer(flex: 3),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ===== بناء أيقونة الصفحة (بدون صور خارجية) =====
  Widget _buildPageIcon(Map<String, dynamic> data) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
          width: 2.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الأيقونة الرئيسية
          Icon(
            data['mainIcon'],
            size: 80,
            color: Theme.of(context).colorScheme.surface,
          ),

          // أيقونة صغيرة في الزاوية اليمنى السفلية
          Positioned(
            bottom: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.25),
              ),
              child: Icon(
                data['smallIcon'],
                size: 35,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),

          // أيقونة إضافية صغيرة في الزاوية اليسرى العليا
          Positioned(
            top: 35,
            left: 35,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.15),
              ),
              child: Icon(
                data['extraIcon'],
                size: 20,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),

          // حلقة زخرفية خارجية
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                width: 1,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== زر التخطي =====
  Widget _buildSkipButton() {
    return Positioned(
      top: 50,
      right: 20,
      child: _currentPage < _onboardingData.length - 1
          ? TextButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isFirstTime', false);
          Get.off(() => const LoginScreen());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'skip'.tr,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Theme.of(context).colorScheme.surface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      )
          : const SizedBox.shrink(),
    ).animate().fadeIn(duration: 500.ms);
  }

  // ===== زر "هيا نبدأ" =====
  Widget _buildGetStartedButton() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: _currentPage == _onboardingData.length - 1
          ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: ElevatedButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isFirstTime', false);
            Get.off(() => const LoginScreen());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 10,
            shadowColor: Colors.black.withOpacity(0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'get_started'.tr,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward, size: 28),
            ],
          ),
        ),
      )
          .animate()
          .scale(duration: 600.ms, curve: Curves.elasticOut)
          .fadeIn(duration: 500.ms)
          : const SizedBox.shrink(),
    );
  }

  // ===== مؤشر الصفحات (النقاط) =====
  Widget _buildPageIndicator() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _onboardingData.length,
              (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: _currentPage == index ? 25 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}