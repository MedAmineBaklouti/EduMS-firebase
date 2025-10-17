import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Rx<User?> user = Rx<User?>(null);
  late final SharedPreferences prefs;

  Future<AuthService> init() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _auth.setSettings(forceRecaptchaFlow: true);
    }

    prefs = await SharedPreferences.getInstance();
    _auth.authStateChanges().listen((User? user) {
      this.user.value = user;
      if (user != null) {
        prefs.setBool('isLoggedIn', true);
      } else {
        prefs.setBool('isLoggedIn', false);
      }
    });
    return this;
  }

  User? get currentUser => _auth.currentUser;

  String? get currentRole => prefs.getString('userRole');

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.getIdToken(true);
      final idTokenResult = await credential.user?.getIdTokenResult(true);
      String? role = idTokenResult?.claims?['role'];

      if (role == null) {
        final doc = await _firestore
            .collection('userRoles')
            .doc(credential.user!.uid)
            .get();
        role = doc.data()?['role'];
      }

      if (role == null) {
        await _auth.signOut();
        throw 'Unauthorized: No role assigned.';
      }

      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', role);

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    }
  }

  Future<String> registerUser(
      {required String email,
      required String password,
      required String role}) async {
    final firebaseApp = await Firebase.initializeApp(
      name: 'registerUser',
      options: Firebase.app().options,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: firebaseApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
      await _firestore
          .collection('userRoles')
          .doc(uid)
          .set({'role': role});
      await secondaryAuth.signOut();
      return uid;
    } finally {
      await firebaseApp.delete();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await prefs.setBool('isLoggedIn', false);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Failed to send password reset email.';
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  Future<UserCredential> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Failed to verify the phone credential.';
    }
  }

  Future<UserCredential> signInWithSmsCode(
      String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return signInWithPhoneCredential(credential);
  }

  Future<String> verifyPasswordResetCode(String code) async {
    try {
      return await _auth.verifyPasswordResetCode(code);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Invalid or expired verification code.';
    }
  }

  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Failed to reset password.';
    }
  }

  Future<void> updatePasswordForCurrentUser(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No authenticated user found.';
    }

    try {
      await user.updatePassword(newPassword);
      await user.reload();
      this.user.value = _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Failed to update password.';
    }
  }

  Future<void> updateCredentials({
    String? newEmail,
    String? newPassword,
    required String currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No authenticated user found.';
    }

    if ((newEmail == null || newEmail.isEmpty) &&
        (newPassword == null || newPassword.isEmpty)) {
      throw 'No changes to update.';
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw 'Your account is missing an email address.';
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      if (newEmail != null && newEmail.isNotEmpty && newEmail != email) {
        await user.updateEmail(newEmail);
      }

      if (newPassword != null && newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }

      await user.reload();
      this.user.value = _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Failed to update credentials.';
    }
  }
}
