import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../service/auth_service.dart';

class PasswordResetController extends GetxController {
  final AuthService _authService = Get.find();

  final RxInt step = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString verifiedEmail = ''.obs;
  final RxString resetCode = ''.obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode codeFocus = FocusNode();
  final FocusNode newPasswordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  void unfocusFields() {
    emailFocus.unfocus();
    codeFocus.unfocus();
    newPasswordFocus.unfocus();
    confirmPasswordFocus.unfocus();
  }

  Future<void> sendResetEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        'Missing Email',
        'Please enter the email associated with your account.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading(true);
      Get.closeAllSnackbars();
      await _authService.sendPasswordResetEmail(email);
      verifiedEmail.value = email;
      step.value = 1;
      Get.snackbar(
        'Email Sent',
        'We just sent a verification code to $email. Check your inbox or spam folder.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
      );
    } catch (e) {
      Get.snackbar(
        'Reset Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> resendCode() async {
    final email = verifiedEmail.value.isNotEmpty
        ? verifiedEmail.value
        : emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar(
        'Missing Email',
        'Enter your email first so we know where to send the code.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    emailController.text = email;
    await sendResetEmail();
  }

  Future<void> verifyCode() async {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar(
        'Missing Code',
        'Enter the verification code from the email we sent you.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading(true);
      Get.closeAllSnackbars();
      final email = await _authService.verifyPasswordResetCode(code);
      verifiedEmail.value = email;
      resetCode.value = code;
      step.value = 2;
      Get.snackbar(
        'Code Verified',
        'Great! Enter a new password for your account.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Verification Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> confirmReset() async {
    final password = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar(
        'Missing Password',
        'Enter and confirm your new password to continue.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (password.length < 6) {
      Get.snackbar(
        'Weak Password',
        'Your new password should be at least 6 characters long.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar(
        'Password Mismatch',
        'The passwords do not match. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final code = resetCode.value.trim().isEmpty
        ? codeController.text.trim()
        : resetCode.value.trim();

    if (code.isEmpty) {
      Get.snackbar(
        'Missing Code',
        'Please verify your email with the code we sent first.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading(true);
      Get.closeAllSnackbars();
      await _authService.confirmPasswordReset(code: code, newPassword: password);

      final loginEmail = verifiedEmail.value.isNotEmpty
          ? verifiedEmail.value
          : emailController.text.trim();

      if (loginEmail.isNotEmpty) {
        await _authService.loginWithEmail(loginEmail, password);
      }

      Get.snackbar(
        'Password Updated',
        'Password changed successfully. Redirecting to your dashboard...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading(false);
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    emailFocus.dispose();
    codeFocus.dispose();
    newPasswordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.onClose();
  }
}
