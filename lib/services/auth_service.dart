import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  //  Simple getter (NO async)
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
  // Forgot Password
  static Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  Future<User?> register(String email, String password) async {
    final res = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return res.user;
  }

  Future<User?> login(String email, String password) async {
    final res = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return res.user;
  }

  String get userId => _auth.currentUser!.uid;

}