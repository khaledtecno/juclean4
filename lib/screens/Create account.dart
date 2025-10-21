import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:juclean/screens/SignIn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'FastTranslationService.dart';


class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _isMalay = false;bool isLoadingUser = true; // Loading state

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
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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

                            translatedtranslatedText('Create account',
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

                     //

                        // Name Field
                        translatedtranslatedText('Name',
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
                            controller: nameController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              hintText: 'Your name',
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
                            borderRadius: BorderRadius.circular(16),
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
                            controller: passwordController,
                            obscureText: _obscureText, textAlignVertical: TextAlignVertical.center, // Vertical centering
                            // Use the boolean variable
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
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
                        _buildSignUpButton('SIGN UP USER', onPressed: () {
                        if(emailController.text.isNotEmpty && nameController.text.isNotEmpty &&passwordController.text.isNotEmpty == true){
                          _signUpWithEmail();
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
                onTap: (){
                  Navigator.pushReplacement(
                    context,
                    ScaleTransition5(SignIn()),
                  );
                },
                child:           Center(
                  child: translatedtranslatedText('Do not have an account? Sign In',
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
  Future<void> _signUpWithEmail() async {
    setState(() => _isLoading = true); // Start loading
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      await userCredential.user!.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(emailController.text).set({
        'Email': emailController.text,
        'Name': nameController.text,
        'type': 'User',
        'emailVerified': false,
      });
      if(!kIsWeb){
        final gmailSmtp = SmtpServer(
          'smtp.gmail.com',
          username: 'juclean988@gmail.com',
          password: 'fknp eufo jpjf wplh', // Use the 16-digit app password
          port: 465,
          ssl: true,
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
      }

      _showEmailVerificationDialog(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      String message = e.code == 'email-already-in-use'
          ? 'The email is already in use'
          : 'Failed to create account: ${e.message}';
      ElegantNotification.error(description: Text(message)).show(context);
    } catch (e) {
      ElegantNotification.error(description: translatedtranslatedText('An unexpected error occurred')).show(context);
    } finally {
      setState(() => _isLoading = false); // Stop loading
    }
  }

  void _showEmailVerificationDialog(User user) {
    bool isResending = false; // Local loading state for resend button


    bool isChecking = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: translatedtranslatedText('Email Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              translatedtranslatedText('We\'ve sent a verification email to ${user.email}'),
              SizedBox(height: 20),
              if (isResending)
                CircularProgressIndicator()
              else
                TextButton(
                  onPressed: () async {
                    setState(() => isResending = true);
                    try {
                      await user.sendEmailVerification();
                      ElegantNotification.success(
                        description: translatedtranslatedText('Verification email resent'),
                      ).show(context);
                    } catch (e) {
                      ElegantNotification.error(
                        description: translatedtranslatedText('Failed to resend email'),
                      ).show(context);
                    } finally {
                      setState(() => isResending = false);
                    }
                  },
                  child: translatedtranslatedText('Resend email'),
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
                  // Reload user to get latest verification status
                  await user.reload();
                  var updatedUser = FirebaseAuth.instance.currentUser;

                  if (updatedUser != null && updatedUser.emailVerified) {
                    // Email is verified - navigate to sign in page
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => SignIn()),
                    );
                  } else {
                    // Email not verified yet
                    ElegantNotification.info(
                      description: translatedtranslatedText('Email not verified yet. Please check your inbox.'),
                    ).show(context);
                  }
                } catch (e) {
                  ElegantNotification.error(
                    description: translatedtranslatedText('Error checking verification status'),
                  ).show(context);
                } finally {
                  setState(() => isChecking = false);
                }
              },
              child: isChecking ? CircularProgressIndicator() : translatedtranslatedText('OK'),
            ),
          ],
        ),
      ),

    );
  }

  Widget _buildSignUpButton(String text, {required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 61,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextButton(
        onPressed: _isLoading ? null : onPressed, // Disable when loading
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : translatedtranslatedText(
          text,
          style: GoogleFonts.getFont(
            'Poppins',
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


}

