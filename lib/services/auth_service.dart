// ============================================================
// ملف: auth_service.dart
// المسار: lib/services/auth_service.dart
// الوصف: خدمة المصادقة - تدعم عزل البيانات لكل مستخدم
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔐 AuthService
class AuthService extends GetxController {
  // ==========================================================
  // المراجع الأساسية
  // ==========================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================
  // المتغيرات التفاعلية
  // ==========================================================

  final Rx<User?> _user = Rx<User?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _userName = ''.obs;

  // ==========================================================
  // Getters
  // ==========================================================

  User? get user => _user.value;
  bool get isLoading => _isLoading.value;
  bool get isLoggedIn => _user.value != null;
  String? get userId => _user.value?.uid;
  String? get userEmail => _user.value?.email;
  String get userName => _userName.value;

  // ✅ getter جديد للـ Rx - للاستماع للتغييرات
  Rx<User?> get userRx => _user;

  // ==========================================================
  // دورة الحياة
  // ==========================================================
  @override
  void onInit() {
    super.onInit();
    debugPrint('🔐 تهيئة AuthService...');

    _auth.authStateChanges().listen((User? user) {
      debugPrint('👤 تغيرت حالة المستخدم: ${user?.email ?? "غير مسجل"}');
      _user.value = user;

      if (user != null) {
        _loadUserName();
      } else {
        _userName.value = '';
      }
    });
  }

  // ==========================================================
  // ✅ تحميل اسم المستخدم (3 مصادر)
  // ==========================================================
  Future<void> _loadUserName() async {
    try {
      if (_user.value == null) return;

      final String uid = _user.value!.uid;
      final prefs = await SharedPreferences.getInstance();

      // ✅ 1. من SharedPreferences (فوري + offline) - الأسرع
      final cachedName = prefs.getString('user_name_$uid');
      if (cachedName != null && cachedName.isNotEmpty) {
        _userName.value = cachedName;
        debugPrint('✅ الاسم من الذاكرة: $cachedName');
        return;
      }

      // ✅ 2. من FirebaseAuth.displayName (offline)
      final authName = _user.value!.displayName;
      if (authName != null && authName.isNotEmpty) {
        _userName.value = authName;
        await prefs.setString('user_name_$uid', authName);
        debugPrint('✅ الاسم من Auth: $authName');
        return;
      }

      // ✅ 3. من Firestore (يحتاج إنترنت - آخر خيار)
      debugPrint('📥 جاري تحميل الاسم من Firestore...');
      try {
        final doc = await _firestore
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.serverAndCache));

        if (doc.exists && doc.data() != null) {
          final name = doc.data()!['name'] ?? '';
          if (name.isNotEmpty) {
            _userName.value = name;
            await prefs.setString('user_name_$uid', name);
            debugPrint('✅ الاسم من Firestore: $name');
          }
        } else {
          debugPrint('⚠️ لا توجد بيانات في Firestore');
        }
      } catch (e) {
        debugPrint('⚠️ Firestore فشل (offline؟): $e');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل اسم المستخدم: $e');
    }
  }

  // ==========================================================
  // ✅ تسجيل الدخول
  // ==========================================================
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading.value = true;

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('✅ تم تسجيل الدخول بنجاح');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ خطأ FirebaseAuth: ${e.code}');
      _showErrorSnackbar(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      debugPrint('❌ خطأ غير متوقع: $e');
      _showErrorSnackbar('error_occurred'.tr);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // ==========================================================
  // ✅ إنشاء حساب جديد
  // ==========================================================
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading.value = true;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final String trimmedName = name.trim();
        final String uid = credential.user!.uid;

        // ✅ 1. تحديث displayName في Firebase Auth
        try {
          await credential.user!.updateDisplayName(trimmedName);
          debugPrint('✅ تم تحديث displayName');
        } catch (e) {
          debugPrint('⚠️ updateDisplayName فشل: $e');
        }

        // ✅ 2. حفظ في SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name_$uid', trimmedName);
          debugPrint('✅ تم حفظ الاسم في SharedPreferences');
        } catch (e) {
          debugPrint('⚠️ SharedPreferences فشل: $e');
        }

        // ✅ 3. حفظ في Firestore
        /*try {
          await _firestore.collection('users').doc(uid).set({
            'name': trimmedName,
            'email': email.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('⚠️ Firestore فشل: $e');
        }*/

        // ✅ 4. تحديث المتغير المحلي
        _userName.value = trimmedName;
      }

      debugPrint('✅ تم إنشاء الحساب بنجاح');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ خطأ FirebaseAuth: ${e.code}');
      _showErrorSnackbar(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      debugPrint('❌ خطأ غير متوقع: $e');
      _showErrorSnackbar('error_occurred'.tr);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // ==========================================================
  // ✅ إعادة تعيين كلمة المرور
  // ==========================================================
  Future<bool> resetPassword(String email) async {
    _isLoading.value = true;

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      Get.snackbar(
        'success'.tr,
        'reset_email_sent'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );

      debugPrint('✅ تم إرسال بريد إعادة التعيين');
      return true;
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _showErrorSnackbar('error_occurred'.tr);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // ==========================================================
  // ✅ تسجيل الخروج
  // ==========================================================
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userName.value = '';
      debugPrint('✅ تم تسجيل الخروج');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل الخروج: $e');
    }
  }

  // ==========================================================
  // ✅ تحديث اسم المستخدم
  // ==========================================================
  Future<bool> updateUserName(String newName) async {
    try {
      if (userId == null) return false;

      final String trimmedName = newName.trim();
      final String uid = userId!;

      try {
        await _user.value!.updateDisplayName(trimmedName);
      } catch (e) {
        debugPrint('⚠️ updateDisplayName فشل: $e');
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name_$uid', trimmedName);
      } catch (e) {
        debugPrint('⚠️ SharedPreferences فشل: $e');
      }

      try {
        await _firestore.collection('users').doc(uid).update({
          'name': trimmedName,
        });
      } catch (e) {
        debugPrint('⚠️ Firestore فشل: $e');
      }

      _userName.value = trimmedName;
      debugPrint('✅ تم تحديث الاسم');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الاسم: $e');
      return false;
    }
  }

  // ==========================================================
  // 🛠️ دوال مساعدة
  // ==========================================================
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'user_not_found'.tr;
      case 'wrong-password':
        return 'wrong_password'.tr;
      case 'invalid-email':
        return 'invalid_email'.tr;
      case 'user-disabled':
        return 'user_disabled'.tr;
      case 'invalid-credential':
        return 'invalid_credential'.tr;
      case 'email-already-in-use':
        return 'email_already_in_use'.tr;
      case 'weak-password':
        return 'weak_password'.tr;
      case 'operation-not-allowed':
        return 'operation_not_allowed'.tr;
      case 'network-request-failed':
        return 'network_error'.tr;
      case 'too-many-requests':
        return 'too_many_requests'.tr;
      default:
        return 'error_occurred'.tr;
    }
  }
}