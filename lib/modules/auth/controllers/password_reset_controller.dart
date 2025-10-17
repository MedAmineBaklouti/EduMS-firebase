import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_pages.dart';
import '../service/auth_service.dart';

enum PasswordResetMethod { emailLink, phoneOtp }

class PasswordResetController extends GetxController {
  final AuthService _authService = Get.find();

  final RxInt step = 0.obs;
  final RxBool isLoading = false.obs;
  final Rx<PasswordResetMethod> method =
      PasswordResetMethod.emailLink.obs;
  final RxString verifiedEmail = ''.obs;
  final RxString resetCode = ''.obs;
  final RxString verificationId = ''.obs;
  final RxnInt resendToken = RxnInt();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode codeFocus = FocusNode();
  final FocusNode newPasswordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode otpFocus = FocusNode();

  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  void unfocusFields() {
    emailFocus.unfocus();
    codeFocus.unfocus();
    newPasswordFocus.unfocus();
    confirmPasswordFocus.unfocus();
    phoneFocus.unfocus();
    otpFocus.unfocus();
  }

  void selectMethod(PasswordResetMethod newMethod) {
    if (method.value == newMethod) {
      return;
    }

    method.value = newMethod;
    step.value = 0;
    verifiedEmail.value = '';
    resetCode.value = '';
    verificationId.value = '';
    resendToken.value = null;

    emailController.clear();
    codeController.clear();
    phoneController.clear();
    otpController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();

    obscureNewPassword.value = true;
    obscureConfirmPassword.value = true;
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
      Get.offAllNamed(AppPages.LOGIN);
      Future.delayed(const Duration(milliseconds: 200), () {
        Get.snackbar(
          'Check your email',
          'We sent a password reset link to $email. Follow the link to update your password.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 6),
        );
      });
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

  Future<void> sendPhoneCode() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      Get.snackbar(
        'Missing Phone Number',
        'Please enter the phone number associated with your account.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading(true);
      Get.closeAllSnackbars();
      await _authService.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _authService.signInWithPhoneCredential(credential);
            verificationId.value = credential.verificationId ?? '';
            otpController.text = credential.smsCode ?? '';
            verifiedEmail.value = _authService.currentUser?.email ?? '';
            step.value = 2;
            Get.snackbar(
              'Phone Verified',
              'Enter a new password for your account.',
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
        },
        verificationFailed: (FirebaseAuthException error) {
          final message = error.code == 'billing-not-enabled'
              ? 'Phone verification is temporarily unavailable. Please contact support while we finish configuring our verification service.'
              : error.message ?? 'Failed to send the verification code.';
          isLoading(false);
          step.value = 0;
          Get.snackbar(
            'Verification Failed',
            message,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
        },
        codeSent: (String newVerificationId, int? newResendToken) {
          verificationId.value = newVerificationId;
          resendToken.value = newResendToken;
          step.value = 1;
          isLoading(false);
          Get.snackbar(
            'OTP Sent',
            'We sent a verification code to $phone.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
        },
        codeAutoRetrievalTimeout: (String newVerificationId) {
          verificationId.value = newVerificationId;
        },
        forceResendingToken: resendToken.value,
      );
    } catch (e) {
      isLoading(false);
      step.value = 0;
      Get.snackbar(
        'Verification Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> verifyOtp() async {
    final code = otpController.text.trim();
    if (code.isEmpty) {
      Get.snackbar(
        'Missing Code',
        'Enter the verification code that was sent to your phone.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (verificationId.value.isEmpty) {
      Get.snackbar(
        'Session Expired',
        'Please request a new verification code and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading(true);
      Get.closeAllSnackbars();
      await _authService.signInWithSmsCode(verificationId.value, code);
      verifiedEmail.value = _authService.currentUser?.email ?? '';
      step.value = 2;
      Get.snackbar(
        'Phone Verified',
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

  Future<void> resendOtp() async {
    await sendPhoneCode();
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

    if (method.value == PasswordResetMethod.emailLink) {
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
        await _authService.confirmPasswordReset(
          code: code,
          newPassword: password,
        );

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
      return;
    }

    try {
      isLoading(true);
      Get.closeAllSnackbars();
      await _authService.updatePasswordForCurrentUser(password);
      await _authService.logout();
      Get.offAllNamed(AppPages.LOGIN);
      Future.delayed(const Duration(milliseconds: 200), () {
        Get.snackbar(
          'Password Updated',
          'Password changed successfully. Use your new password to log in.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      });
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
    phoneController.dispose();
    otpController.dispose();
    emailFocus.dispose();
    codeFocus.dispose();
    newPasswordFocus.dispose();
    confirmPasswordFocus.dispose();
    phoneFocus.dispose();
    otpFocus.dispose();
    super.onClose();
  }
}
