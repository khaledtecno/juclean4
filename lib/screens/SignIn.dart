import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juclean/screens/Customer/HomeScreenC.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../services/FCM.dart';
import 'Admin/AdminMain.dart';
import 'Employee/EmplyeeScreen.dart';
import 'FastTranslationService.dart';
import 'package:http/http.dart' as http;

import 'Splash.dart';


class SignIn extends StatefulWidget {
  SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;  bool isLoading = false;bool _obscureText = true;  bool _isMalay = false;bool isLoadingUser = true; // Loading state

  bool _isRefreshing = false;
  @override
  void initState() {
    super.initState();
    _initializeTranslations();  _getLanguagePreference();
  }
  Future<void> _toggleLanguage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('malys', value);
    setState(() {
      _isMalay = value;
      _isRefreshing = true;
    });

    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _isRefreshing = false;
    });
  }  Future<void> _getLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMalay = prefs.getBool('malys') ?? false;
    });
  }
  Future<void> _initializeTranslations() async {
    final prefs = await SharedPreferences.getInstance();
    final isMalay = prefs.getBool('malys') ?? false;
    await FastTranslationService.init(isMalay);
  } Widget translatedtranslatedText(String text, {TextStyle? style}) {
    return Text(
      FastTranslationService.translate(text),
      style: style,
    );
  } // Controls password visibility
  @override
  Widget build(BuildContext context) { final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final isWideScreen = screenWidth > 700;
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            // Conditional decoration based on screen width
            color: isWideScreen ? null : Colors.white, // No color if using gradient
            gradient: isWideScreen
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Colors.indigo,
                Colors.blueAccent,
              ],
              stops: [0.1, 0.5, 0.9],
            )
                : null,
          ),
          child: SingleChildScrollView(
    child: SizedBox(
    height: MediaQuery.of(context).size.height + 1, // Allow extra space for scrolling
    child:  Stack(
              clipBehavior: Clip.none,
              children: [
                // Background Image
                if(!isWideScreen)
                  Positioned(
                  left: -63,
                  top: 152,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    clipBehavior: Clip.hardEdge,
                    child: Image.asset(
                      'assets/images/back2.png',
                      width: 539,
                      height: 777,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),


                // Form Content
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 42),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            translatedtranslatedText('Sign In',
                              style: GoogleFonts.getFont(
                                'Poppins',
                                color: const Color(0xFF2F3534),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(43),
                            clipBehavior: Clip.hardEdge,
                            child: Image.asset(
                              'assets/images/llogo.png',
                              width: 168,
                              height: 168,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Name Field

                        const SizedBox(height: 20),

                        // Email Field
                        translatedtranslatedText('Email',
                          style: GoogleFonts.getFont(
                            'Poppins',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x07000000),
                                spreadRadius: 0,
                                offset: Offset(-2, 6),
                                blurRadius: 47,
                              )
                            ],
                          ),
                          child: TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              hintText: 'Email@gmail.com',
                              hintStyle: TextStyle(color: Color(0xFFA1A3B0)),
                            ),
                            style: GoogleFonts.getFont(
                              'Poppins',
                              color: const Color(0xFFA1A3B0),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        translatedtranslatedText('Password',
                          style: GoogleFonts.getFont(
                            'Poppins',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x07000000),
                                spreadRadius: 0,
                                offset: Offset(-2, 6),
                                blurRadius: 47,
                              )
                            ],
                          ),
                          child: TextFormField(
                            controller: passwordController, textAlignVertical: TextAlignVertical.center, // Vertical centering

                            obscureText: _obscureText, // Use the boolean variable
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              hintText: '***************', isDense: true,
                              hintStyle: TextStyle(color: Color(0xFFA1A3B0)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText ? Icons.visibility_off : Icons.visibility,
                                  color: Color(0xFFA1A3B0),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText; // Toggle the state
                                  });
                                },
                              ),
                            ),
                            style: GoogleFonts.getFont(
                              'Poppins',
                              color: const Color(0xFFA1A3B0),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sign Up Buttons
                        _buildSignUpButton('SIGN IN', onPressed: () {

                          if(emailController.text.isNotEmpty  &&passwordController.text.isNotEmpty == true){

                            sigin();

                          }else{
                            ElegantNotification.error(
                              title: translatedtranslatedText('Sign-up Failed'),
                              description: translatedtranslatedText('Fill All details'),
                            ).show(context);
                          }
                        }),

                        const SizedBox(height: 20),
                        // Footer Text
                        InkWell(
                          onTap: () => _showForgotPasswordDialog(context),
                          child: Center(
                            child: translatedtranslatedText('Forgot your password.',
                              style: GoogleFonts.getFont(
                                'Poppins',
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ),
      ),
    ));
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController _emailController = TextEditingController();
    bool isSending = false; // Local loading state for dialog

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Allow state updates inside dialog
        builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    translatedtranslatedText('Reset Password', style: GoogleFonts.poppins(fontSize: 18)),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                SizedBox(height: 20),
                if (isSending)
            CircularProgressIndicator()
        else
        ElevatedButton(
        style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),),
        onPressed: () async {
          if (_emailController.text.isEmpty) {
            ElegantNotification.error(
              description: translatedtranslatedText('Please enter email'),
            ).show(context);
            return;
          }

          setState(() => isSending = true);
          try {
            await _auth.sendPasswordResetEmail(
              email: _emailController.text.trim(),
            );
            Navigator.pop(context);
            ElegantNotification.success(
              description: translatedtranslatedText('Reset email sent!'),
            ).show(context);
          } catch (e) {
            ElegantNotification.error(
              description: translatedtranslatedText('Failed: ${e.toString()}'),
            ).show(context);
          } finally {
            setState(() => isSending = false);
          }
        },
        child: translatedtranslatedText('Send Link', style: TextStyle(color: Colors.white),),
      ),
      ],
    ),
    ),
    ),
    ),
    );
  }Future<void> sendWelcomeEmail(String email) async {
    // Use this for all platforms (mobile and web)
    try {
      final response = await http.post(
        Uri.parse('https://us-central1-juclean-69af4.cloudfunctions.net/sendWelcomeEmail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'toEmail': email}),
      );

      if (response.statusCode == 200) {
        print('Email sent successfully');
      } else {
        print('Failed to send email: ${response.body}');
      }
    } catch (e) {
      print('Error sending email: $e');
    }
  }
  Future<void> sendEmail() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendEmail');
      await callable.call({
        'to': emailController.text,
        'subject': 'Welcome to JUClean',
        'html':  '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to JUclean - Your Sparkling Journey Begins!</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Inter', sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background-color: #f9fafb;
        }
        .email-container {
            max-width: 640px;
            margin: 20px auto;
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
        }
        .header {
            background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
            padding: 40px 20px;
            text-align: center;
            color: white;
            position: relative;
        }
        .header::after {
            content: "";
            position: absolute;
            bottom: -30px;
            left: 0;
            right: 0;
            height: 30px;
            background: white;
            border-radius: 24px 24px 0 0;
        }
        .logo {
            width: 120px;
            margin-bottom: 20px;
        }
        h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 700;
        }
        .tagline {
            margin: 8px 0 0;
            font-weight: 400;
            opacity: 0.9;
        }
        .content {
            padding: 40px;
        }
        .welcome-text {
            font-size: 16px;
            margin-bottom: 24px;
        }
        .company-info {
            background: #f8fafc;
            border-radius: 8px;
            padding: 24px;
            margin: 24px 0;
            border-left: 4px solid #3b82f6;
        }
        .info-title {
            color: #1d4ed8;
            margin-top: 0;
            font-size: 18px;
        }
        .features {
            display: flex;
            flex-wrap: wrap;
            gap: 16px;
            margin: 24px 0;
        }
        .feature {
            flex: 1 1 200px;
            background: #f8fafc;
            padding: 16px;
            border-radius: 8px;
            text-align: center;
        }
        .feature-icon {
            font-size: 24px;
            color: #3b82f6;
            margin-bottom: 8px;
        }
        .feature-title {
            font-weight: 600;
            margin: 8px 0 4px;
        }
        .button-container {
            text-align: center;
            margin: 32px 0;
        }
        .button {
            display: inline-block;
            background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
            color: white !important;
            padding: 14px 28px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.25);
            transition: all 0.3s ease;
        }
        .button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(59, 130, 246, 0.35);
        }
        .credentials {
            background: #f8fafc;
            padding: 16px;
            border-radius: 8px;
            margin: 16px 0;
            font-family: monospace;
            border-left: 3px solid #3b82f6;
        }
        .footer {
            text-align: center;
            padding: 24px;
            background: #f8fafc;
            color: #64748b;
            font-size: 14px;
        }
        .social-links {
            margin: 16px 0;
        }
        .social-links a {
            margin: 0 8px;
            color: #3b82f6;
            text-decoration: none;
        }
        .highlight {
            color: #1d4ed8;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>Welcome to JUclean!</h1>
            <p class="tagline">Where cleanliness meets perfection</p>
        </div>

        <div class="content">
            <p class="welcome-text">Dear Valued Customer,</p>
            <p class="welcome-text">Thank you for choosing <span class="highlight">JUclean</span> for your cleaning needs! We're thrilled to have you on board and can't wait to transform your space into a spotless sanctuary.</p>

            <div class="company-info">
                <h3 class="info-title">About JUclean</h3>
                <p>Founded in 2015, JUclean has been delivering exceptional cleaning services to thousands of satisfied customers. Our eco-friendly products and professional team ensure your space isn't just clean, but truly refreshed.</p>
            </div>

            <div class="features">
                <div class="feature">
                    <div class="feature-icon">✨</div>
                    <h4 class="feature-title">Eco-Friendly</h4>
                    <p>We use only environmentally safe cleaning products</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">🛡️</div>
                    <h4 class="feature-title">Fully Insured</h4>
                    <p>Your property is protected with our comprehensive insurance</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">⭐</div>
                    <h4 class="feature-title">5-Star Service</h4>
                    <p>Consistently rated excellent by our customers</p>
                </div>
            </div>

            <div class="button-container">
                <a href="{BookingLink}" class="button">Book Your First Cleaning</a>
            </div>

            <p>If you have any questions about our services or need assistance with your booking, our customer service team is available 7 days a week.</p>
            <p>Welcome to the JUclean family!</p>
            <p>Best regards,<br><strong>The JUclean Team</strong></p>
        </div>

        <div class="footer">
            <div class="social-links">
                <a href="{FacebookLink}">Facebook</a>
                <a href="{InstagramLink}">Instagram</a>
                <a href="{TwitterLink}">Twitter</a>
                <a href="{LinkedInLink}">LinkedIn</a>
            </div>
            <p>JUclean Cleaning Services ©. All rights reserved.</p>
            <p><a href="{PrivacyPolicyLink}" style="color: #3b82f6;">Privacy Policy</a> | <a href="{TermsLink}" style="color: #3b82f6;">Terms of Service</a></p>
            <p>123 Clean Street, Sparkle City, SC 12345</p>
        </div>
    </div>
</body>
</html>
'''
      });
      print('                                              successfully');
    } catch (e) {
      print('Error sending email: $e');
    }
  }
  Future<void> sigin() async {
    setState(() => isLoading = true); // Start loading
    try {

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if(!kIsWeb){
        final FCMTokenService _tokenService = FCMTokenService();
        final userDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(userCredential.user!.email)
            .get();

        if (userDoc.exists) {
          // Initialize token for admin
          await _tokenService.initialize();
        } else {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>  Splash(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
            ),
          );
          throw Exception('Not an admin user');
        }
        final gmailSmtp = SmtpServer(
        'smtp.gmail.com',
        username: 'juclean988@gmail.com',
        password: 'fknp eufo jpjf wplh', // Use the 16-digit app password
        port: 465,
        ssl: true,allowInsecure: true,
      );

        final message = Message()
          ..from = Address(dotenv.env["GMAIL_MAIL"]!, 'JUCLEAN')
          ..recipients.add(emailController.text)
          ..subject = 'Welcome to JUClean '
          ..html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to JUclean - Your Sparkling Journey Begins!</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Inter', sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background-color: #f9fafb;
        }
        .email-container {
            max-width: 640px;
            margin: 20px auto;
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
        }
        .header {
            background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
            padding: 40px 20px;
            text-align: center;
            color: white;
            position: relative;
        }
        .header::after {
            content: "";
            position: absolute;
            bottom: -30px;
            left: 0;
            right: 0;
            height: 30px;
            background: white;
            border-radius: 24px 24px 0 0;
        }
        .logo {
            width: 120px;
            margin-bottom: 20px;
        }
        h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 700;
        }
        .tagline {
            margin: 8px 0 0;
            font-weight: 400;
            opacity: 0.9;
        }
        .content {
            padding: 40px;
        }
        .welcome-text {
            font-size: 16px;
            margin-bottom: 24px;
        }
        .company-info {
            background: #f8fafc;
            border-radius: 8px;
            padding: 24px;
            margin: 24px 0;
            border-left: 4px solid #3b82f6;
        }
        .info-title {
            color: #1d4ed8;
            margin-top: 0;
            font-size: 18px;
        }
        .features {
            display: flex;
            flex-wrap: wrap;
            gap: 16px;
            margin: 24px 0;
        }
        .feature {
            flex: 1 1 200px;
            background: #f8fafc;
            padding: 16px;
            border-radius: 8px;
            text-align: center;
        }
        .feature-icon {
            font-size: 24px;
            color: #3b82f6;
            margin-bottom: 8px;
        }
        .feature-title {
            font-weight: 600;
            margin: 8px 0 4px;
        }
        .button-container {
            text-align: center;
            margin: 32px 0;
        }
        .button {
            display: inline-block;
            background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
            color: white !important;
            padding: 14px 28px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.25);
            transition: all 0.3s ease;
        }
        .button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(59, 130, 246, 0.35);
        }
        .credentials {
            background: #f8fafc;
            padding: 16px;
            border-radius: 8px;
            margin: 16px 0;
            font-family: monospace;
            border-left: 3px solid #3b82f6;
        }
        .footer {
            text-align: center;
            padding: 24px;
            background: #f8fafc;
            color: #64748b;
            font-size: 14px;
        }
        .social-links {
            margin: 16px 0;
        }
        .social-links a {
            margin: 0 8px;
            color: #3b82f6;
            text-decoration: none;
        }
        .highlight {
            color: #1d4ed8;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>Welcome to JUclean!</h1>
            <p class="tagline">Where cleanliness meets perfection</p>
        </div>

        <div class="content">
            <p class="welcome-text">Dear Valued Customer,</p>
            <p class="welcome-text">Thank you for choosing <span class="highlight">JUclean</span> for your cleaning needs! We're thrilled to have you on board and can't wait to transform your space into a spotless sanctuary.</p>

            <div class="company-info">
                <h3 class="info-title">About JUclean</h3>
                <p>Founded in 2015, JUclean has been delivering exceptional cleaning services to thousands of satisfied customers. Our eco-friendly products and professional team ensure your space isn't just clean, but truly refreshed.</p>
            </div>

            <div class="features">
                <div class="feature">
                    <div class="feature-icon">✨</div>
                    <h4 class="feature-title">Eco-Friendly</h4>
                    <p>We use only environmentally safe cleaning products</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">🛡️</div>
                    <h4 class="feature-title">Fully Insured</h4>
                    <p>Your property is protected with our comprehensive insurance</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">⭐</div>
                    <h4 class="feature-title">5-Star Service</h4>
                    <p>Consistently rated excellent by our customers</p>
                </div>
            </div>

            <div class="button-container">
                <a href="{BookingLink}" class="button">Book Your First Cleaning</a>
            </div>

            <p>If you have any questions about our services or need assistance with your booking, our customer service team is available 7 days a week.</p>
            <p>Welcome to the JUclean family!</p>
            <p>Best regards,<br><strong>The JUclean Team</strong></p>
        </div>

        <div class="footer">
            <div class="social-links">
                <a href="{FacebookLink}">Facebook</a>
                <a href="{InstagramLink}">Instagram</a>
                <a href="{TwitterLink}">Twitter</a>
                <a href="{LinkedInLink}">LinkedIn</a>
            </div>
            <p>JUclean Cleaning Services ©. All rights reserved.</p>
            <p><a href="{PrivacyPolicyLink}" style="color: #3b82f6;">Privacy Policy</a> | <a href="{TermsLink}" style="color: #3b82f6;">Terms of Service</a></p>
            <p>123 Clean Street, Sparkle City, SC 12345</p>
        </div>
    </div>
</body>
</html>
''';

        try {
          final sendReport = await send(message, gmailSmtp);
          print('Message sent: $sendReport');
        } on MailerException catch (e) {
          print('Message not sent.');
          for (var p in e.problems) {
            print('Problem: ${p.code}: ${p.msg}');
          }
        }
      }else{
        sendEmail();
      }



      if (userCredential.user!.emailVerified) {
        final isEmployee = await _checkUserRole('users', emailController.text!, 'Employee');
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(userCredential.user!.email)
            .get();

        if (adminDoc.exists) {
          // User is admin - redirect to admin screen
          if (mounted) { if (kIsWeb) {

          } else {
            print("This is not a web platform, can't reload!");
          }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => NeoAdminDashboard()),
            );
          }
          return;
        }

        // Check if user is employee

        if (isEmployee) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => EmplyeeScreen(),
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

        // Regular user
        if (mounted) {
          if (kIsWeb) {
    // Reloads the page
          } else {
            print("This is not a web platform, can't reload!");
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreenC()),
          );
        }else{
          if (kIsWeb) {
 // Reloads the page
        } else {
          print("This is not a web platform, can't reload!");
        }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreenC()),
          );
        }

      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: translatedtranslatedText('Email Not Verified'),
            content: translatedtranslatedText('Please verify your email before proceeding.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: translatedtranslatedText('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _sendVerificationEmail(userCredential.user!);
                },
                child: translatedtranslatedText('Resend Email'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ElegantNotification.error(
        title: translatedtranslatedText('Sign-in Failed'),
        description: Text(e.message ?? "Unknown error"),
      ).show(context);
    } finally {
      setState(() => isLoading = false); // Stop loading
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
  Future<void> _sendVerificationEmail(User user) async {
    setState(() => isLoading = true);
    try {
      await user.sendEmailVerification();
      ElegantNotification.success(
        title: translatedtranslatedText('Email Sent'),
        description: translatedtranslatedText('Check your inbox for verification link.'),
      ).show(context);
    } catch (e) {
      ElegantNotification.error(
        title: translatedtranslatedText('Failed'),
        description: translatedtranslatedText('Could not send verification email.'),
      ).show(context);
    } finally {
      setState(() => isLoading = false);
    }
  }

// Helper function to send verification email


  Widget _buildSignUpButton(String text, {required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 61,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextButton(
        onPressed: isLoading ? null : onPressed, // Disable when loading
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : translatedtranslatedText(text, style: GoogleFonts.poppins(color: Colors.white)),
      ),
    );
  }
}

