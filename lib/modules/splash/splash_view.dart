import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          Image.asset(
            'assets/splash/background.png',
            fit: BoxFit.cover,
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Your logo
                Image.asset(
                  'assets/EduMS_logo.png',
                  width: 200,
                  height: 200,
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
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Image.asset(
                    'assets/Denet_logo.png',
                    height: 40,
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