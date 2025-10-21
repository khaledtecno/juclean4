import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:juclean/main.dart';
import 'package:juclean/screens/Create%20account.dart';
import 'package:juclean/screens/SignIn.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Color primaryColor = const Color(0xFF0066CC);
  final Color accentColor = const Color(0xFF4CAF50);
  final Color secondaryColor = const Color(0xFF00CC99);
  final Color kDarkBlueColor = const Color(0xFF053149);

  // Responsive layout values
  late double _imageSize;
  late double _titleFontSize;
  late double _descriptionFontSize;
  late double _buttonFontSize;
  late EdgeInsets _pagePadding;
  late int _featureGridCrossAxisCount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateResponsiveValues();
  }

  void _updateResponsiveValues() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjust values based on screen size
    if (screenWidth > 600) { // Web/tablet layout
      _imageSize = screenHeight * 0.3;
      _titleFontSize = 32.0;
      _descriptionFontSize = 18.0;
      _buttonFontSize = 18.0;
      _pagePadding = EdgeInsets.symmetric(horizontal: screenWidth * 0.15);
      _featureGridCrossAxisCount = 4;
    } else { // Mobile layout
      _imageSize = screenHeight * 0.2;
      _titleFontSize = 25.0;
      _descriptionFontSize = 14.0;
      _buttonFontSize = 16.0;
      _pagePadding = const EdgeInsets.symmetric(horizontal: 40);
      _featureGridCrossAxisCount = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateResponsiveValues(); // Ensure values are up-to-date

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return OnBoardingSlider(
              finishButtonText: 'Registrieren',
              onFinish: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  GetStarted()),
                );
              },
              finishButtonStyle: FinishButtonStyle(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              skipTextButton: Text('Überspringen',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Text('Anmelden',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailingFunction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  SignIn()),
                );
              },
              controllerColor: primaryColor,
              indicatorAbove: true,
              totalPage: 3,
              headerBackgroundColor: Colors.white,
              pageBackgroundColor: Colors.white,
              speed: 1.5,
              background: [
                _buildImageWithBackground('assets/images/logo.png', context),
                _buildImageWithBackground('assets/images/logo.png', context),
                _buildImageWithBackground('assets/images/logo.png', context),

              ],
              pageBodies: [
                _buildOnboardingPage(
                    context,
                    'Willkommen bei JUClean',
                    'Ihr zuverlässiger Partner für professionelle Reinigungsdienstleistungen',
                    Icons.cleaning_services,
                    'assets/images/logo.png'
                ),
                _buildOnboardingPage(
                    context,
                    'Kostenlose Besichtigung',
                    'Vereinbaren Sie einen Termin und wir erstellen ein individuelles Angebot',
                    Icons.calendar_today,
                    'assets/slide_2.png'
                ),
                _buildOnboardingPage(
                    context,
                    'Premium Reinigungsservice',
                    'Professionelle Reinigung mit hochwertigen Produkten für Ihr Zuhause oder Büro',
                    Icons.star,
                    'assets/slide_3.png'
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageWithBackground(String imagePath, BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: _imageSize,
          decoration: BoxDecoration(

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container()
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      String image,
      ) {
    return Padding(
      padding: _pagePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Container(
            width: _imageSize,
            height: _imageSize,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              image,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryColor,
              fontSize: _titleFontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 60 : 20,
            ),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: _descriptionFontSize,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildFeatureGrid(),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {'icon': Icons.people, 'text': 'Professionelles Team'},
      {'icon': Icons.eco, 'text': 'Ökologische Mittel'},
      {'icon': Icons.schedule, 'text': 'Flexible Termine'},
      {'icon': Icons.verified, 'text': 'Garantierte Qualität'},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _featureGridCrossAxisCount,
      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 4 : 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: features.map((feature) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(feature['icon'] as IconData, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  feature['text'] as String,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}