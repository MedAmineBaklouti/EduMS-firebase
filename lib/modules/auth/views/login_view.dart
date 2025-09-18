import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/modern_scaffold.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatelessWidget {
  LoginView({super.key});

  final AuthController _authController = Get.find();
  final RxBool _obscurePassword = true.obs;

  @override
  Widget build(BuildContext context) {
    Get.closeAllSnackbars();
    _authController.isLoading(false);

    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _authController.unfocusFields,
      child: ModernScaffold(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          blurRadius: 36,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/EduMS_logo.png',
                      width: 160,
                      height: 160,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildIntroText(context),
                  const SizedBox(height: 24),
                  _buildLoginCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroText(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Welcome to EduMS',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to manage your school community with ease.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.06),
            blurRadius: 42,
            offset: const Offset(0, 30),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Login to your account',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _authController.emailController,
              focusNode: _authController.emailFocus,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _authController.passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            Obx(
              () => TextField(
                controller: _authController.passwordController,
                focusNode: _authController.passwordFocus,
                obscureText: _obscurePassword.value,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(
                    Icons.lock,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: _obscurePassword.toggle,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _authController.submitForm(),
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _authController.isLoading.value
                    ? null
                    : _authController.submitForm,
                child: _authController.isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.toNamed('/register'),
              child: const Text('Create Admin Account'),
            ),
          ],
        ),
      ),
    );
  }
}
