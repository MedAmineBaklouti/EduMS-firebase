import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatelessWidget {
  LoginView({super.key});
  final AuthController _authController = Get.find();
  final RxBool _obscurePassword = true.obs;

  @override
  Widget build(BuildContext context) {
    Get.closeAllSnackbars(); // ✅ Close any lingering snackbars
    _authController.isLoading(false); // ✅ Reset loading on screen load

    return GestureDetector(
      onTap: _authController.unfocusFields,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                Theme.of(context).brightness == Brightness.dark
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
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/EduMS_logo_dark.png',
                        width: 200,
                        height: 200,
                      ),
                      const SizedBox(height: 40),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                'Login',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _authController.emailController,
                                focusNode: _authController.emailFocus,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(
                                    Icons.email,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant
                                      .withOpacity(0.4),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    _authController.passwordFocus.requestFocus(),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword.value
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      onPressed: () => _obscurePassword.toggle(),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant
                                        .withOpacity(0.4),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _authController.submitForm(),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Obx(
                                () => FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _authController.isLoading.value
                                      ? null
                                      : _authController.submitForm,
                                  child: _authController.isLoading.value
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                ),
                              ),
                            ],
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
