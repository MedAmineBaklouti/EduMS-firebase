import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes/app_pages.dart';
import 'package:edums/modules/auth/service/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find();
  final RxBool isLoading = false.obs;
  late final SharedPreferences prefs;

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  @override
  void onInit() {
    prefs = Get.find<SharedPreferences>();
    ever(_authService.user, handleAuthStateChange);
    super.onInit();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.onClose();
  }

  Future<void> handleAuthStateChange(User? user) async {
    isLoading(false); // reset loading at start, just in case

    if (user != null) {
      try {
        isLoading(true);

        await user.getIdToken(true);
        final token = await user.getIdTokenResult(true);
        String? role = token.claims?['role'];
        debugPrint('User role: $role');

        if (role == null) {
          final doc = await FirebaseFirestore.instance
              .collection('userRoles')
              .doc(user.uid)
              .get();
          role = doc.data()?['role'];
        }

        if (role == null) throw 'No role assigned to this user';

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          switch (role) {
            case 'admin':
              await Get.offAllNamed(AppPages.ADMIN_HOME);
              break;
            case 'teacher':
              await Get.offAllNamed(AppPages.TEACHER_HOME);
              break;
            case 'parent':
              await Get.offAllNamed(AppPages.PARENT_HOME);
              break;
            default:
              throw 'Unauthorized role: $role';
          }

          await prefs.setString('userRole', role!);
          isLoading(false); // <-- Reset loading AFTER navigation
        });
      } catch (e) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Get.offAllNamed(AppPages.LOGIN);
          Get.snackbar(
            'Authorization Error',
            e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
          isLoading(false); // Reset loading AFTER navigation
        });
      }
    } else {
      await prefs.remove('userRole');

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Get.offAllNamed(AppPages.LOGIN);
        isLoading(false); // Reset loading AFTER navigation
      });
    }
  }

  Future<void> login() async {
    try {
      isLoading(true);
      Get.closeAllSnackbars();

      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        throw 'Please fill in all fields';
      }

      await _authService.loginWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      passwordController.clear();
    } catch (e) {
      Get.snackbar(
        'Login Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
      isLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      isLoading(true);
      await _authService.logout();
      emailController.clear();
      passwordController.clear();
    } catch (e) {
      Get.snackbar(
        'Logout Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  void unfocusFields() {
    emailFocus.unfocus();
    passwordFocus.unfocus();
  }

  void submitForm() {
    unfocusFields();
    if (!isLoading.value) {
      login();
    }
  }

  String? get currentRole => prefs.getString('userRole');
}
