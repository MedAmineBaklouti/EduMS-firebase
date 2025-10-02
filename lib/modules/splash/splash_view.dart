import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/safe_asset_image.dart';
import '../../../app/routes/app_pages.dart';

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
    // Show splash for minimum 3 seconds
    await Future.delayed(Duration(seconds: 5));

    // Then check auth state
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          SafeAssetImage(
            assetPath: 'assets/splash/background.png',
            fit: BoxFit.cover,
            fallback: Container(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Your logo
                SafeAssetImage(
                  assetPath: 'assets/EduMS_logo.png',
                  fit: BoxFit.contain,
                  fallback: Icon(
                    Icons.school,
                    size: 120,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 20),
                // Loading indicator
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Made with',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: SafeAssetImage(
                      assetPath: 'assets/Denet_logo.png',
                      fit: BoxFit.contain,
                      fallback: Text(
                        'Denet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}