import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/routes/app_pages.dart';
import '../../../core/widgets/modern_scaffold.dart';

class SplashView extends StatefulWidget {
  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 5));
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAllNamed(AppPages.LOGIN);
      return;
    }

    try {
      await user.getIdToken(true);
      final token = await user.getIdTokenResult(true);
      String? role = token.claims?['role'];

      if (role == null) {
        final doc = await FirebaseFirestore.instance
            .collection('userRoles')
            .doc(user.uid)
            .get();
        role = doc.data()?['role'];
      }

      switch (role) {
        case 'admin':
          Get.offAllNamed(AppPages.ADMIN_HOME);
          break;
        case 'teacher':
          Get.offAllNamed(AppPages.TEACHER_HOME);
          break;
        case 'parent':
          Get.offAllNamed(AppPages.PARENT_HOME);
          break;
        default:
          throw 'No valid role';
      }
    } catch (e) {
      Get.offAllNamed(AppPages.LOGIN);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModernScaffold(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      extendBodyBehindAppBar: true,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Image.asset('assets/EduMS_logo.png'),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'EduMS',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preparing your personalized experience...',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 28),
          const SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ],
      ),
    );
  }
}
