import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:juclean/rootwidget.dart';
import 'package:juclean/screens/Admin/NoticationPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:juclean/screens/Create%20account.dart';
import 'package:juclean/screens/Customer/DetailService.dart';
import 'package:juclean/screens/FastTranslationService.dart';
import 'package:juclean/screens/SignIn.dart';
// import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/foundation.dart';
//import 'package:js/js.dart';
//import 'package:js/js_util.dart' as js_util;
import 'package:juclean/services/FCM.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:universal_html/html.dart' as html;
import 'package:juclean/screens/Splash.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
//firebase deploy --only hosting
// firebase deploy --only functions
void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  if (!kIsWeb) {

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    await Firebase.initializeApp();
    await dotenv.load(fileName: ".env");
    // Initialize FCM token handling
    final fcmTokenService = FCMTokenService();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);



    // Set up foreground notifications and channel ONCE.
    await setupFlutterNotifications();






    setupFlutterNotifications();

  }else{
    await dotenv.load(fileName: ".env");
  //  final google = js_util.getProperty(html.window, 'google');
   // print("Google available? ${google != null}");
    // Initialize Firebase for web
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyCr4lEug1ej_5kgPedU9XMsp5ap-DOtKHY",
          authDomain: "juclean-69af4.firebaseapp.com",
          projectId: "juclean-69af4",
          storageBucket: "juclean-69af4.firebasestorage.app",
          messagingSenderId: "206535405160",
          appId: "1:206535405160:web:be586469438d587cf615dd",
          measurementId: "G-LD3X3YV3Z9"
      ),
    );
    FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    /* setWebPageDetails(
        title: 'JUClean',
        description:
            'JUclean – „Wo Reinheit beginnt – und Eindruck bleibt.“Ihre Reinigungsfirma in Köln & NRW. Spezialisiert auf professionelle Reinigung von Kitas, Büros, Wohnungen & mehr. Gründlich, zuverlässig & kindersicher.',
        faviconPath: 'assets/images/logo.png');

     setWebPageDetails(
      title: 'JUClean',
      description:
          'JUclean – „Wo Reinheit beginnt – und Eindruck bleibt.“Ihre Reinigungsfirma in Köln & NRW. Spezialisiert auf professionelle Reinigung von Kitas, Büros, Wohnungen & mehr. Gründlich, zuverlässig & kindersicher.',
      faviconPath:
          'assets/images/logo.png', // Relative to the web directory
    );*/

    SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(
        label: 'JUClean',
      ),
    );
    print('Running on web. Screen security not activated.');
  }// firebase deploy --only hosting
  runApp(MyApp());
}
void initDeepLinkHandler() {
  // Handle app opened by a deep link
  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg.toString().contains('AppLifecycleState.resumed')) {
      _checkInitialLink();
    }
    return null;
  });

  // Check for initial link when app starts
  _checkInitialLink();
}

void _checkInitialLink() {
  // This is a simplified approach - you might need a package
  // like uni_links for more robust deep link handling
  Future.delayed(Duration(seconds: 1), () {
    // Check if app was opened with a deep link
    // You would implement this based on your deep link structure
  });
}
Future<void> setupFlutterNotifications() async {
  // Handle when notification is clicked while app is in foreground/background/terminated
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );


  await FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("Foreground message received: ${message.notification?.title}");

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      FlutterLocalNotificationsPlugin().show(
        notification.hashCode,
        notification.title,
        notification.body,
        // CORRECT
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            // Provide the name of the icon file from 'android/app/src/main/res/drawable/'
            icon: 'ic_notification', // <-- FIXED
          ),
        ),
      );
    }
  });

  // Background/terminated messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
// CORRECTED BACKGROUND HANDLER

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize with icon for background
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('ic_notification');

  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(android: initializationSettingsAndroid),
  );

  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          icon: 'ic_notification',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
/*void setWebPageDetails(
    {required String title,
      required String description,
      required String faviconPath}) {
  // Set the title
  html.document.title = title;

  // Set the meta description
  html.MetaElement meta = html.MetaElement()
    ..name = 'JUClean'
    ..content = description;

  html.document.head?.append(meta);

  // Update favicon
  html.LinkElement link = html.LinkElement()
    ..rel = 'icon'
    ..href = faviconPath;

  // Remove old favicon
  var oldIcons = html.document.querySelectorAll("link[rel='icon']");
  for (var icon in oldIcons) {
    icon.remove();
  }

  // Append new favicon
  html.document.head?.append(link);
}*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'JUClean',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SplashWithDeepLinkHandler(),
      ),
    );
  }
}

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
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
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final notificationId = message.data['id'];
      if (notificationId != null) {
        // Navigate to notification details or mark as read
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => NotificationsPage(),
        ));
      }
    });

// Handle when notification is clicked while app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        final notificationId = message.data['id'];
        if (notificationId != null) {
          // Navigate to notification details
          WidgetsBinding.instance.addPostFrameCallback((_) {

            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => NotificationsPage(),
            ));
          });
        }
      }
    });
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 700;
    final double buttonWidth = isWideScreen ? screenWidth * 0.3 : screenWidth * 0.8;
    final double buttonHeight = isWideScreen ? screenHeight * 0.06 : screenHeight * 0.07;
    final double fontSize = isWideScreen
        ? min(screenWidth * 0.02, screenHeight * 0.03)
        : min(screenWidth * 0.04, screenHeight * 0.04);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: screenHeight,
        color: isWideScreen ? Colors.white : Colors.white, // Blue background for wide screens
        child: SingleChildScrollView(
          child: SizedBox(
            height: screenHeight + 1,
            child: Stack(
                clipBehavior: Clip.none,
                children: [
                // Background Image (only show on narrow screens)
                if (!isWideScreen)
            Positioned(
            left: -screenWidth * 0.1,
            top: screenHeight * 0.3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              clipBehavior: Clip.hardEdge,
              child: Image.asset(
                'assets/images/back.png',
                width: screenWidth * 1.3,
                height: screenHeight * 0.7,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Logo Image
                  if (!isWideScreen)
                    Positioned(
                      left: screenWidth * 0.2,
                      top: screenHeight * 0.1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(43),
                        clipBehavior: Clip.hardEdge,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: screenWidth * 0.6,
                          height: screenHeight * 0.2,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  if (isWideScreen)
                    Container(
               width: double.infinity,
                      height: 300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(43),
                        clipBehavior: Clip.hardEdge,
                        child: Image.asset(
                          'assets/images/logo.png',

                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
          // SIGN UP Button
                  // SIGN UP Button
                  if (!isWideScreen)
                   Stack(
                    children: [
                      Positioned(
                        left: isWideScreen ? screenWidth * 0.35 : screenWidth * 0.1,
                        top: screenHeight * 0.6,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              ScaleTransition5(CreateAccount()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:  Colors.black,
                            minimumSize: Size(buttonWidth, buttonHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: translatedtranslatedText('SIGN UP',
                            style: GoogleFonts.getFont(
                              'Poppins',
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),

                      // SIGN IN Button
                      Positioned(
                        left: isWideScreen ? screenWidth * 0.35 : screenWidth * 0.1,
                        top: screenHeight * 0.7,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              ScaleTransition5(SignIn()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:  Colors.black,
                            foregroundColor:  Colors.white,
                            minimumSize: Size(buttonWidth, buttonHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: translatedtranslatedText('SIGN IN',
                            style: GoogleFonts.getFont(
                              'Poppins',
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),

                      // Welcome Text
                      Positioned(
                        left: isWideScreen ? screenWidth * 0.3 : screenWidth * 0.17,
                        top: screenHeight * 0.45,
                        child: translatedtranslatedText('Welcome to \nJUCleanApp',


                          style: GoogleFonts.getFont(
                            'Poppins',
                            color:  isWideScreen ? Colors.black: Colors.white,
                            fontSize: isWideScreen
                                ? min(screenWidth * 0.02, screenHeight * 0.04)
                                : min(screenWidth * 0.06, screenHeight * 0.06),
                            fontWeight: FontWeight.bold,

                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 60,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: _isRefreshing
                                ? const SizedBox(
                              width: 80,
                              child: LinearProgressIndicator(
                                minHeight: 2,
                                backgroundColor: Colors.transparent,
                                color: Colors.white,
                              ),
                            )
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // English Flag
                                _buildModernFlag3(
                                  flagColors: const [
                                    Color(0xFFFFFFFF),  // White background
                                    Color(0xFFCF142B),  // Red cross (traditional English red)
                                  ],
                                  isActive: !_isMalay,
                                  onTap: () => _toggleLanguage(false),
                                ),

                                // Animated toggle track
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: 40,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: _isMalay
                                          ? const Color(0xFFFFCE00).withOpacity(0.3)
                                          : const Color(0xFFC8102E).withOpacity(0.3),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: AnimatedAlign(
                                      duration: const Duration(milliseconds: 300),
                                      alignment: _isMalay ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        margin: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // German Flag
                                _buildModernFlag(
                                  flagColors: const [
                                    Color(0xFF000000),
                                    Color(0xFFDD0000),
                                    Color(0xFFFFCE00),
                                  ],
                                  isActive: _isMalay,
                                  onTap: () => _toggleLanguage(true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                   //   SizedBox(height: 16,),
                    ],
                  ),
                  if (isWideScreen)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.blue.shade900, Colors.blue.shade700],
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = constraints.maxWidth;
                          final screenHeight = constraints.maxHeight;
                          final isWideScreen = screenWidth > 600; // Adjust breakpoint as needed

                          // Responsive sizing calculations
                          double logoSize = isWideScreen
                              ? min(screenWidth * 0.15, screenHeight * 0.15)
                              : min(screenWidth * 0.3, screenHeight * 0.15);

                          double buttonWidth = isWideScreen
                              ? min(screenWidth * 0.3, 400)
                              : min(screenWidth * 0.8, 400);

                          double buttonHeight = max(screenHeight * 0.06, 50);
                          double fontSize = isWideScreen
                              ? screenWidth * 0.018
                              : screenWidth * 0.04;
                          double titleFontSize = isWideScreen
                              ? min(screenWidth * 0.03, 32)
                              : min(screenWidth * 0.06, 28);

                          return Stack(
                            children: [
                              // Logo with app name
                              Positioned(
                                top: screenHeight * 0.15,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          width: logoSize,
                                          height: logoSize,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.02),
                                      translatedtranslatedText('JUClean',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: titleFontSize * 1.2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Welcome text
                              Positioned(
                                top: screenHeight * 0.39,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                                  child: Text(
                                    'Welcome to \nJUCleanApp',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ),

                              // Buttons container
                              Positioned(
                                top: isWideScreen ? screenHeight * 0.5 : screenHeight * 0.55,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: buttonWidth,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // SIGN UP Button
                                        ElevatedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            ScaleTransition5(CreateAccount()),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.blue.shade900,
                                            minimumSize: Size(double.infinity, buttonHeight),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 3,
                                          ),
                                          child: translatedtranslatedText('SIGN UP',
                                            style: GoogleFonts.poppins(
                                              fontSize: fontSize,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        SizedBox(height: screenHeight * 0.02),

                                        // SIGN IN Button
                                        ElevatedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            ScaleTransition5(SignIn()),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            minimumSize: Size(double.infinity, buttonHeight),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(color: Colors.white, width: 2),
                                            ),
                                          ),
                                          child: translatedtranslatedText('SIGN IN',
                                            style: GoogleFonts.poppins(
                                              fontSize: fontSize,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 45,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],

                                    ),
                                    child: _isRefreshing
                                        ? const SizedBox(
                                      width: 80,
                                      child: LinearProgressIndicator(
                                        minHeight: 2,
                                        backgroundColor: Colors.transparent,
                                        color: Colors.white,
                                      ),
                                    )
                                        : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // English Flag
                                        _buildModernFlag(
                                          flagColors: const [
                                            Color(0xFF012169),
                                            Color(0xFFC8102E),
                                            Color(0xFFFFFFFF),
                                          ],
                                          isActive: !_isMalay,
                                          onTap: () => _toggleLanguage(false),
                                        ),
                                        SizedBox(width: 10,),
Container(
  height:15,
  width: 2,
   color: Colors.white,
),
                                        // Animated toggle track
                               SizedBox(width: 10,),

                                        // German Flag
                                        _buildModernFlag(
                                          flagColors: const [
                                            Color(0xFF000000),
                                            Color(0xFFDD0000),
                                            Color(0xFFFFCE00),
                                          ],
                                          isActive: _isMalay,
                                          onTap: () => _toggleLanguage(true),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                          // German Flag


// Helper method for flag buttons

                            ],
                          );
                        },
                      ),
                    )

            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildModernFlag3({
    required List<Color> flagColors,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    // Assuming flagColors[0] is background, flagColors[1] is cross color
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 24,
        decoration: BoxDecoration(
          color: flagColors[0],
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey,
            width: isActive ? 2 : 1,
          ),
        ),
        child: CustomPaint(
          painter: _EnglishFlagPainter(
            crossColor: flagColors[1],
          ),
        ),
      ),
    );
  }

// Add this to your main function or initState
  void initDeepLinkHandler() {
    // Handle app opened by a deep link
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg.toString().contains('AppLifecycleState.resumed')) {
        _checkInitialLink();
      }
      return null;
    });

    // Check for initial link when app starts
    _checkInitialLink();
  }

  void _checkInitialLink() {
    // This is a simplified approach - you might need a package
    // like uni_links for more robust deep link handling
    Future.delayed(Duration(seconds: 1), () {
      // Check if app was opened with a deep link
      // You would implement this based on your deep link structure
    });
  }

// Modern flag builder
  Widget _buildModernFlag({
  required List<Color> flagColors,
  required bool isActive,
  required VoidCallback onTap,
  }) {
  return GestureDetector(
  onTap: onTap,
  child: AnimatedContainer(
  duration: const Duration(milliseconds: 200),
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(6),
  border: Border.all(
  color: isActive
  ? Colors.white.withOpacity(0.8)
      : Colors.transparent,
  width: 1.5,
  ),
  ),
  child: ClipRRect(
  borderRadius: BorderRadius.circular(4),
  child: SizedBox(
  width: 28,
  height: 20,
  child: Column(
  children: flagColors.map((color) =>
  Expanded(
  child: Container(
  color: color,
  ),
  ),
  ).toList(),
  ),
  ),
  ),
  ),
  );
  }

  Widget _buildFlagWithText({
    required List<Color> flagColors,
    required String text,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isActive ? Colors.blue.shade50 : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: flagColors,
                stops: const [0.33, 0.66, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              color: isActive ? Colors.blue.shade800 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
class ScaleTransition5 extends PageRouteBuilder {
  final Widget page;

  ScaleTransition5(this.page)
      : super(
    pageBuilder: (context, animation, anotherAnimation) => page,
    transitionDuration: const Duration(milliseconds: 1000),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, anotherAnimation, child) {
      animation = CurvedAnimation(
          curve: Curves.fastLinearToSlowEaseIn,
          parent: animation,
          reverseCurve: Curves.fastOutSlowIn);
      return ScaleTransition(
        alignment: Alignment.center,
        scale: animation,
        child: child,
      );
    },
  );

Widget translatedtranslatedText(String text, {TextStyle? style}) {
  return Text(
    FastTranslationService.translate(text),
    style: style,
  );
}
}class _EnglishFlagPainter extends CustomPainter {
  final Color crossColor;

  _EnglishFlagPainter({required this.crossColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = crossColor;
    final crossWidth = size.width / 5;

// Draw vertical cross bar
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: crossWidth,
        height: size.height,
      ),
      paint,
    );

// Draw horizontal cross bar
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width,
        height: crossWidth,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}