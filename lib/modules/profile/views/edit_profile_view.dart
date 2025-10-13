import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../common/widgets/module_page_container.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthService? _authService;
  String _initialEmail = '';
  bool _isSubmitting = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AuthService>()) {
      _authService = Get.find<AuthService>();
      _initialEmail = _authService?.currentUser?.email ?? '';
      if (_initialEmail.isNotEmpty) {
        _emailController.text = _initialEmail;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: onPrimary,
      ),
      body: ModulePageContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(theme),
                const SizedBox(height: 24),
                _buildEmailField(theme),
                const SizedBox(height: 24),
                _buildPasswordSection(theme),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: onPrimary,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSubmitting ? 'Saving...' : 'Save changes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: onPrimary.withOpacity(0.2),
                child: Icon(Icons.person_outline, color: onPrimary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep your credentials secure',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update your account email and password. We will ask for '
                      'your current password to protect your profile.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onPrimary.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account email',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'Please enter an email address';
            }
            final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
            if (!emailRegExp.hasMatch(text)) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your current password and, if needed, a new password. '
          'Leave the new password empty to keep your existing one.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _currentPasswordController,
          obscureText: !_showCurrentPassword,
          decoration: InputDecoration(
            labelText: 'Current password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _showCurrentPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _showCurrentPassword = !_showCurrentPassword;
                });
              },
            ),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: _currentPasswordValidator,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_showNewPassword,
          decoration: InputDecoration(
            labelText: 'New password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _showNewPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _showNewPassword = !_showNewPassword;
                });
              },
            ),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            final text = value ?? '';
            if (text.isEmpty) {
              return null;
            }
            if (text.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm new password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.check_circle_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
            ),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            final confirmation = value ?? '';
            final newPassword = _newPasswordController.text;
            if (newPassword.isEmpty) {
              return null;
            }
            if (confirmation.isEmpty) {
              return 'Confirm your new password';
            }
            if (confirmation != newPassword) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  String? _currentPasswordValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    final emailChanged = _emailController.text.trim() != _initialEmail;
    final wantsPasswordChange = _newPasswordController.text.isNotEmpty;
    if ((emailChanged || wantsPasswordChange) && trimmed.isEmpty) {
      return 'Enter your current password to continue';
    }
    return null;
  }

  Future<void> _submit() async {
    final authService = _authService;
    if (authService == null) {
      Get.snackbar(
        'Unavailable',
        'Authentication service is not ready. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final form = _formKey.currentState;
    if (form == null) {
      return;
    }

    if (!form.validate()) {
      return;
    }

    final trimmedEmail = _emailController.text.trim();
    final emailChanged = trimmedEmail != _initialEmail;
    final newPassword = _newPasswordController.text;
    final wantsPasswordChange = newPassword.isNotEmpty;

    if (!emailChanged && !wantsPasswordChange) {
      Get.snackbar(
        'Nothing to update',
        'Update the email field or enter a new password to save changes.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final currentPassword = _currentPasswordController.text;
    if (currentPassword.isEmpty) {
      Get.snackbar(
        'Current password required',
        'Please enter your current password to confirm the update.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final theme = Theme.of(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await authService.updateCredentials(
        currentPassword: currentPassword,
        newEmail: emailChanged ? trimmedEmail : null,
        newPassword: wantsPasswordChange ? newPassword : null,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _initialEmail = authService.currentUser?.email ?? trimmedEmail;
        _emailController.text = _initialEmail;
      });

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Get.snackbar(
        'Profile updated',
        'Your credentials were saved successfully.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      Get.snackbar(
        'Update failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: theme.colorScheme.error.withOpacity(0.12),
        colorText: theme.colorScheme.error,
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
