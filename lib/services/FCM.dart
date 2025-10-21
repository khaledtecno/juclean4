// fcm_token_service.dart
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

class FCMTokenService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Ensure user is logged in before proceeding
    if (_auth.currentUser == null) {
      debugPrint("User not logged in, skipping FCM token initialization.");
      return;
    }

    // Request permission for notifications (important for iOS and web)
    await _firebaseMessaging.requestPermission();

    // Get and save the token
    String? token = await _firebaseMessaging.getToken();
    debugPrint("FCM Token: $token");

    if (token != null) {
      // Pass the UID, email, and token to the save function
      await _saveToken(
        uid: _auth.currentUser!.uid,
        email: _auth.currentUser!.email ?? 'no-email', // Handle case where email might be null
        token: token,
      );
    }

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint("Token refreshed: $newToken");
      if (_auth.currentUser != null) {
        _saveToken(
          uid: _auth.currentUser!.uid,
          email: _auth.currentUser!.email ?? 'no-email',
          token: newToken,
        );
      }
    });
  }

  // --- MODIFIED METHOD ---
  // Save token to the new 'tokens' collection
  Future<void> _saveToken({required String uid, required String email, required String token}) async {
    try {
      // The new path is a top-level collection 'tokens'
      // The document ID is the user's unique ID (UID)
      await _firestore.collection('tokens').doc(uid).set({
        'email': email,
        'token': token,
        'platform': _getPlatform(),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge:true is good practice
      debugPrint("Token saved to Firestore for UID: $uid");
    } catch (e) {
      debugPrint("Error saving token: $e");
    }
  }

  // --- MODIFIED METHOD ---
  // Remove token document when user logs out
  Future<void> removeToken() async {
    if (_auth.currentUser == null) return;
    try {
      // Delete the entire document associated with the user's UID
      await _firestore.collection('tokens').doc(_auth.currentUser!.uid).delete();
      debugPrint("Token removed from Firestore for UID: ${_auth.currentUser!.uid}");
    } catch (e) {
      debugPrint("Error removing token: $e");
    }
  }

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}