import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_pages.dart';
import '../controllers/password_reset_controller.dart';

class ForgotPasswordView extends GetView<PasswordResetController> {
  const ForgotPasswordView({super.key});

  @override
  PasswordResetController get controller => Get.find();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final logoAsset =
        isDarkMode ? 'assets/EduMS_logo_dark.png' : 'assets/EduMS_logo.png';

    return GestureDetector(
      onTap: controller.unfocusFields,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                isDarkMode
                    ? 'assets/splash/background_dark.png'
                    : 'assets/splash/background.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        logoAsset,
                        width: 160,
                        height: 160,
                      ),
                      const SizedBox(height: 32),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Obx(
                            () => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Reset Password',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _MethodToggle(
                                  theme: theme,
                                  selected: controller.method.value,
                                  onChanged: controller.selectMethod,
                                ),
                                const SizedBox(height: 24),
                                if (controller.method.value ==
                                    PasswordResetMethod.emailLink)
                                  _EmailLinkStep(theme: theme)
                                else ...[
                                  _StepIndicator(
                                    step: controller.step.value,
                                    steps: const [
                                      'Phone',
                                      'OTP',
                                      'New Password'
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  if (controller.step.value == 0)
                                    _PhoneNumberStep(theme: theme)
                                  else if (controller.step.value == 1)
                                    _OtpStep(theme: theme)
                                  else
                                    _NewPasswordStep(
                                      theme: theme,
                                      isPhoneFlow: true,
                                    ),
                                ],
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () => Get.offAllNamed(AppPages.LOGIN),
                                  child: const Text('Back to Login'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodToggle extends StatelessWidget {
  const _MethodToggle({
    required this.theme,
    required this.selected,
    required this.onChanged,
  });

  final ThemeData theme;
  final PasswordResetMethod selected;
  final void Function(PasswordResetMethod) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Email link'),
                ],
              ),
            ),
            selected: selected == PasswordResetMethod.emailLink,
            onSelected: (_) => onChanged(PasswordResetMethod.emailLink),
            selectedColor: theme.colorScheme.primary.withOpacity(0.2),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: selected == PasswordResetMethod.emailLink
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected == PasswordResetMethod.emailLink
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
            backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sms_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Phone OTP'),
                ],
              ),
            ),
            selected: selected == PasswordResetMethod.phoneOtp,
            onSelected: (_) => onChanged(PasswordResetMethod.phoneOtp),
            selectedColor: theme.colorScheme.primary.withOpacity(0.2),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: selected == PasswordResetMethod.phoneOtp
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected == PasswordResetMethod.phoneOtp
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
            backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}

class _EmailLinkStep extends GetView<PasswordResetController> {
  const _EmailLinkStep({required this.theme});

  final ThemeData theme;

  @override
  PasswordResetController get controller => Get.find();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your email and we\'ll send you a password reset link.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.emailController,
          focusNode: controller.emailFocus,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(
              Icons.email,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor:
                theme.colorScheme.surfaceVariant.withOpacity(0.4),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.sendResetEmail(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed:
              controller.isLoading.value ? null : controller.sendResetEmail,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send reset email'),
        ),
      ],
    );
  }
}

class _PhoneNumberStep extends GetView<PasswordResetController> {
  const _PhoneNumberStep({required this.theme});

  final ThemeData theme;

  @override
  PasswordResetController get controller => Get.find();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the phone number linked to your account and we\'ll send an OTP.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.phoneController,
          focusNode: controller.phoneFocus,
          decoration: InputDecoration(
            labelText: 'Phone number',
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor:
                theme.colorScheme.surfaceVariant.withOpacity(0.4),
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.sendPhoneCode(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed:
              controller.isLoading.value ? null : controller.sendPhoneCode,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send OTP'),
        ),
      ],
    );
  }
}

class _OtpStep extends GetView<PasswordResetController> {
  const _OtpStep({required this.theme});

  final ThemeData theme;

  @override
  PasswordResetController get controller => Get.find();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the verification code sent to ${controller.phoneController.text.trim()}.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.otpController,
          focusNode: controller.otpFocus,
          decoration: InputDecoration(
            labelText: 'OTP code',
            prefixIcon: Icon(
              Icons.verified_user,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor:
                theme.colorScheme.surfaceVariant.withOpacity(0.4),
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.verifyOtp(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed:
              controller.isLoading.value ? null : controller.verifyOtp,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify OTP'),
        ),
        TextButton(
          onPressed:
              controller.isLoading.value ? null : controller.resendOtp,
          child: const Text('Resend code'),
        ),
      ],
    );
  }
}

class _NewPasswordStep extends GetView<PasswordResetController> {
  const _NewPasswordStep({required this.theme, this.isPhoneFlow = false});

  final ThemeData theme;
  final bool isPhoneFlow;

  @override
  PasswordResetController get controller => Get.find();

  @override
  Widget build(BuildContext context) {
    final email = controller.verifiedEmail.value;
    final description = isPhoneFlow
        ? (email.isNotEmpty
            ? 'Set a new password for $email.'
            : 'Set a new password for your account.')
        : 'Set a new password for ${controller.verifiedEmail.value}.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          description,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Obx(
          () => TextField(
            controller: controller.newPasswordController,
            focusNode: controller.newPasswordFocus,
            obscureText: controller.obscureNewPassword.value,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: Icon(
                Icons.lock_reset,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscureNewPassword.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: controller.obscureNewPassword.toggle,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor:
                  theme.colorScheme.surfaceVariant.withOpacity(0.4),
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => controller.confirmPasswordFocus.requestFocus(),
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => TextField(
            controller: controller.confirmPasswordController,
            focusNode: controller.confirmPasswordFocus,
            obscureText: controller.obscureConfirmPassword.value,
            decoration: InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscureConfirmPassword.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: controller.obscureConfirmPassword.toggle,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor:
                  theme.colorScheme.surfaceVariant.withOpacity(0.4),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.confirmReset(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed:
              controller.isLoading.value ? null : controller.confirmReset,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Password'),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.steps});

  final int step;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        steps.length,
        (index) {
          final isActive = index == step;
          final isCompleted = index < step;
          final color = isActive
              ? theme.colorScheme.primary
              : isCompleted
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.outline;

          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  steps[index],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
