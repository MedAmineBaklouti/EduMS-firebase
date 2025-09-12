import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Rx<User?> user = Rx<User?>(null);
  late final SharedPreferences prefs;

  Future<AuthService> init() async {
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
        final doc =
            await _firestore.collection('users').doc(credential.user!.uid).get();
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

  Future<String> createUser(
      String email, String password, String role) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set({'role': role});
    return credential.user!.uid;
  }

  Future<void> logout() async {
    await _auth.signOut();
    await prefs.setBool('isLoggedIn', false);
  }
}