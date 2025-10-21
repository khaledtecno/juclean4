// In your auth service or login/logout handlers
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'FCM.dart';

class AuthService {
  final FCMTokenService _tokenService = FCMTokenService();

  Future<void> login(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // After successful login, verify admin role
      final userDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userCredential.user!.email)
          .get();

      if (userDoc.exists) {
        // Initialize token for admin
        await _tokenService.initialize();
      } else {
        throw Exception('Not an admin user');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> logout() async {
    await _tokenService.removeToken();
    await FirebaseAuth.instance.signOut();
  }
}