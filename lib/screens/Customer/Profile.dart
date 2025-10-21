import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:juclean/screens/Customer/AddressListScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../FastTranslationService.dart';
import 'SavedServicesScreen.dart';



class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {  String userName = ''; // To store the user's name
bool isLoadingUser = true; // Loading state
bool _isMalay = false;
bool _isRefreshing = false;
bool _isBiometricEnabled = false;
bool _isBiometricAvailable = false;

@override
void initState() {
  super.initState();
  _fetchUserName();  _getLanguagePreference();_initializeTranslations();
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

Future<void> _fetchUserName() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (doc.exists) {
        setState(() {
          userName = doc.data()?['Name'] ?? 'User'; // Assuming 'name' field exists
          isLoadingUser = false;
        });
      } else {
        setState(() {
          userName = 'User';
          isLoadingUser = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = 'User';
        isLoadingUser = false;
      });
    }
  } else {
    setState(() {
      isLoadingUser = false;
    });
  }
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
// Load language preference from SharedPreferences
Future<void> _loadLanguagePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final savedLangPref = prefs.getBool('malys') ?? false; // Default to false (English)
  setState(() {
    _isMalay = savedLangPref;
  });
}
@override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth,
      height: screenHeight,
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        child: Column(
          children: [

            // Top Section
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.3,
              decoration: const BoxDecoration(
                color: Color(0xFF0B0C1A),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  // Background decorative element
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.03,
                    top: MediaQuery.of(context).size.height * 0.04,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.height * 0.22,
                      child: Image.asset(
                        'assets/images/user.png',
                        fit: BoxFit.contain,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),

                  // Profile content centered
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile image with responsive sizing
                        Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: MediaQuery.of(context).size.width * 0.3,
                          constraints: const BoxConstraints(
                            maxWidth: 150,
                            maxHeight: 150,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(27),
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/header.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.person,
                                size: MediaQuery.of(context).size.width * 0.15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // User name with responsive text sizing
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child:translatedtranslatedText(
                            userName,
                            style: GoogleFonts.titilliumWeb(
                              color: const Color(0xFFEFF3FF),
                              fontSize: MediaQuery.of(context).size.width * 0.03,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),

                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Information Card
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                final isSmallScreen = screenWidth < 375;
                final isLargeScreen = screenWidth > 600;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  child: Card(
                    elevation: 4,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: EdgeInsets.zero, // Remove default card margin
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [     translatedtranslatedText('Information',
                              style: GoogleFonts.titilliumWeb(
                                color: const Color(0xFF0B0C1A),
                                fontSize: isLargeScreen ? 16 : 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                              Container(

                                child: _isRefreshing
                                    ? const Center(child: CircularProgressIndicator())
                                    : Center(
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

                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          translatedtranslatedText('Customer',
                                            style: GoogleFonts.titilliumWeb(
                                              color: const Color(0xFF0B0C1A),
                                              fontSize: isLargeScreen ? 20 : 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.4,
                                            ),
                                          ),

                                        ],
                                      ),
                                      SizedBox(height: isSmallScreen ? 4 : 6),
                                      translatedtranslatedText('Type of user',
                                        style: GoogleFonts.titilliumWeb(
                                          color: const Color(0xFFB5B6C4),
                                          fontSize: isLargeScreen ? 14 : 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isSmallScreen)
                                  VerticalDivider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                    indent: 4,
                                    endIndent: 4,
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      translatedtranslatedText('0',
                                        style: GoogleFonts.titilliumWeb(
                                          color: const Color(0xFF0B0C1A),
                                          fontSize: isLargeScreen ? 20 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 4 : 6),
                                      translatedtranslatedText('Orders Done',
                                        style: GoogleFonts.titilliumWeb(
                                          color: const Color(0xFFB5B6C4),
                                          fontSize: isLargeScreen ? 14 : 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Address Card
            /* InkWell(
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddressListScreen()),
              );
            },child:  Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child:Container(

              width:double.infinity ,child:  Card(
              elevation: 4,color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        translatedtranslatedText('Address',
                          style: GoogleFonts.getFont(
                            'Titillium Web',
                            color: const Color(0xFF0B0C1A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        translatedtranslatedText('Show address',
                          style: GoogleFonts.getFont(
                            'Titillium Web',
                            color: const Color(0xFFB5B6C4),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    Icon(IconlyBroken.location)
                  ],
                ),
              ),
            ),
            ),),),*/
            // Tasks Card
            /* Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
          child:Container(

            width:double.infinity ,child:  Card(
            elevation: 4,color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  translatedtranslatedText('Tasks',
                    style: GoogleFonts.getFont(
                      'Titillium Web',
                      color: const Color(0xFF0B0C1A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  translatedtranslatedText('Show your done, waiting tasks',
                    style: GoogleFonts.getFont(
                      'Titillium Web',
                      color: const Color(0xFFB5B6C4),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),),*/


// Helper widget

            // Logout Card
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isSmallScreen = screenWidth < 375;
                final isLargeScreen = screenWidth > 600;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: isSmallScreen ? 8 : 12,
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SavedServicesScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Card(
                      elevation: 4,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: EdgeInsets.zero,
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  translatedtranslatedText('Saved',
                                    style: GoogleFonts.titilliumWeb(
                                      color: const Color(0xFF0B0C1A),
                                      fontSize: isLargeScreen ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  translatedtranslatedText('Show saved services',
                                    style: GoogleFonts.titilliumWeb(
                                      color: const Color(0xFFB5B6C4),
                                      fontSize: isLargeScreen ? 14 : 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              IconlyBroken.bookmark,
                              size: isLargeScreen ? 28 : 24,
                              color: Colors.blue[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bottom Navigation Indicator
            Container(
              width: screenWidth,
              height: 34,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 135,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }  Widget _buildModernFlag({
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
       translatedtranslatedText(
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
}Widget _buildModernFlag3({
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
}
class _EnglishFlagPainter extends CustomPainter {
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

