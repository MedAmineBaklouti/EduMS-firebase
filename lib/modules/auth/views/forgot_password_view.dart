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
                                _StepIndicator(step: controller.step.value),
                                const SizedBox(height: 24),
                                if (controller.step.value == 0)
                                  _EmailStep(theme: theme)
                                else if (controller.step.value == 1)
                                  _CodeStep(theme: theme)
                                else
                                  _NewPasswordStep(theme: theme),
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

class _EmailStep extends GetView<PasswordResetController> {
  const _EmailStep({required this.theme});

  final ThemeData theme;

  @override
  PasswordResetController get controller => Get.find();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your account email and we will send you a verification code.',
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
              : const Text('Send Code'),
        ),
      ],
    );
  }
}

class _CodeStep extends GetView<PasswordResetController> {
  const _CodeStep({required this.theme});

  final ThemeData theme;

  @override
  PasswordResetController get controller => Get.find();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the verification code from the password reset email sent to '
          '${controller.verifiedEmail.value}.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.codeController,
          focusNode: controller.codeFocus,
          decoration: InputDecoration(
            labelText: 'Verification code',
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
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.verifyCode(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: controller.isLoading.value ? null : controller.verifyCode,
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
              : const Text('Verify Code'),
        ),
        TextButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.resendCode,
          child: const Text('Resend code'),
        ),
      ],
    );
  }
}

class _NewPasswordStep extends GetView<PasswordResetController> {
  const _NewPasswordStep({required this.theme});

  final ThemeData theme;

  @override
  PasswordResetController get controller => Get.find();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set a new password for ${controller.verifiedEmail.value}.',
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
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = const ['Email', 'Code', 'New Password'];

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
