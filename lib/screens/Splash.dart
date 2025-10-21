import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juclean/screens/Customer/HomeScreenC.dart';

import '../../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../OnBoardingScreen.dart';
import '../services/FCM.dart';
import 'Admin/AdminMain.dart';
import 'Employee/EmplyeeScreen.dart';
import 'FastTranslationService.dart';
class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {// Helper function to send verification email
  Future<void> _sendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Verification email sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Failed to send verification email')),
      );
    }
  }
  @override
  void initState() {
    super.initState();

 addtoken();
    // Delay auth check to allow initial build to complete
    Future.delayed(const Duration(seconds: 3), _checkAuthAndNavigate);
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // No user signed in, go to get started screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>  OnboardingScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
            ),
          );
        }
        return;
      }

      // Check admin status first
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user!.email)
          .get();

      if (adminDoc.exists) {
        // User is admin - redirect to admin screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NeoAdminDashboard()),
          );
        }
        return;
      }

      // Check employee status
      final isEmployee = await _checkUserRole('users', user.email!, 'Employee');
      if (isEmployee) {
       /* if (!user.emailVerified && mounted) {
          await _showEmailVerificationDialog(user);
          return;
        }*/
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const EmplyeeScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
            ),
          );
        }
        return;
      }

      // Regular user flow
      if (!user.emailVerified && mounted) {
        await _showEmailVerificationDialog(user);
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>  HomeScreenC(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: translatedtranslatedText('Authentication error: ${e.toString()}')),
        );
      }
    }
  }

  Future<bool> _checkUserRole(String collection, String email, [String? type]) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection(collection)
          .where('Email', isEqualTo: email)
          .limit(1);

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: translatedtranslatedText('Error checking user role: ${e.toString()}')),
        );
      }
      return false;
    }
  }
  //123456789jef2

  Future<void> _showEmailVerificationDialog(User user) async {
    bool isResending = false;
    bool isChecking = false;
    Timer? verificationTimer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Start automatic verification checking
          verificationTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
            try {
              await user.reload();
              var updatedUser = FirebaseAuth.instance.currentUser;

              if (updatedUser != null && updatedUser.emailVerified) {
                timer.cancel(); // Stop the timer
                Navigator.of(context).pop(); // Close dialog

                // Navigate to appropriate screen based on user role
                _navigateAfterVerification(updatedUser);
              }
            } catch (e) {
              print('Error checking verification: $e');
            }
          });

          return AlertDialog(
            title: translatedtranslatedText('Email Verification Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                translatedtranslatedText('Please verify your email address before proceeding.'),
                SizedBox(height: 10),
                translatedtranslatedText('We\'ve sent a verification email to ${user.email}'),
                SizedBox(height: 20),
                if (isResending)
                  CircularProgressIndicator()
                else
                  TextButton(
                    onPressed: () async {
                      setState(() => isResending = true);
                      try {
                        await _sendVerificationEmail(user);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: translatedtranslatedText('Verification email sent!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: translatedtranslatedText('Failed to send email: ${e.toString()}')),
                          );
                        }
                      } finally {
                        setState(() => isResending = false);
                      }
                    },
                    child: translatedtranslatedText('Resend Email'),
                  ),
                if (isChecking)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  setState(() => isChecking = true);

                  try {
                    // Manual check when OK button is pressed
                    await user.reload();
                    var updatedUser = FirebaseAuth.instance.currentUser;

                    if (updatedUser != null && updatedUser.emailVerified) {
                      verificationTimer?.cancel(); // Stop the timer
                      Navigator.of(context).pop(); // Close dialog
                      _navigateAfterVerification(updatedUser);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: translatedtranslatedText('Email not verified yet. Please check your inbox.')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: translatedtranslatedText('Error checking verification status')),
                    );
                  } finally {
                    setState(() => isChecking = false);
                  }
                },
                child: isChecking ? CircularProgressIndicator() : translatedtranslatedText('Check Verification'),
              ),
              TextButton(
                onPressed: () async {
                  verificationTimer?.cancel(); // Cancel the timer
                  logout(context);
                },
                child: translatedtranslatedText('Logout'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      // Clean up timer when dialog is closed
      verificationTimer?.cancel();
    });
  }

// Helper function to navigate after verification
  void _navigateAfterVerification(User user) async {
    try {
      // Check admin status
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.email)
          .get();

      if (adminDoc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NeoAdminDashboard()),
        );
        return;
      }

      // Check employee status
      final isEmployee = await _checkUserRole('users', user.email!, 'Employee');
      if (isEmployee) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const EmplyeeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
          ),
        );
        return;
      }

      // Regular user
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomeScreenC(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Navigation error: ${e.toString()}')),
      );
    }
  }
  Future<void> logout(BuildContext context) async {
    Navigator.pop(context); // Close dialog
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => const GetStarted(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Logout error: $e')),
      );
    }
  }


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 305,
          height: 224,
        ),
      ),
    );
  }

  Future<void> addtoken() async {    final fcmTokenService = FCMTokenService();
    await fcmTokenService.initialize();}
}
