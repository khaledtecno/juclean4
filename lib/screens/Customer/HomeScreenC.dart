import 'dart:async';

import 'package:features_tour/features_tour.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:iconly/iconly.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_links/app_links.dart';
import 'package:juclean/screens/Customer/AllServices.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../FastTranslationService.dart';
import 'DetailService.dart';
import 'MyBookings.dart';
import 'Profile.dart';
import 'SearchC.dart';
class HomeScreenC extends StatefulWidget {
  const HomeScreenC({super.key});

  @override
  State<HomeScreenC> createState() => _HomeScreenCState();
}

class _HomeScreenCState extends State<HomeScreenC> with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  int _selectedItemPosition = 0;
  String userName = '';
  bool isLoadingUser = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
 // Loading state
  bool _isMalay = false;
  bool _isRefreshing = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
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
  }
  Widget translatedtranslatedText(String text, {TextStyle? style}) {
    return Text(
      FastTranslationService.translate(text),
      style: style,
    );
  }

  final tourController = FeaturesTourController('App');
  @override
  void initState() {
    super.initState();
    _fetchUserName();


      tourController.start(context);

    _initDeepLinks();
    _getLanguagePreference();_initializeTranslations();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {_linkSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Listen for incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    print('Received deep link while app running: $uri');

    String? serviceId = _extractServiceIdFromUri(uri);

    if (serviceId != null && serviceId.isNotEmpty && mounted) {
      _navigateToService(serviceId);
    }
  }

  String? _extractServiceIdFromUri(Uri uri) {
    // Handle GitHub Pages links: https://khaledtecno.github.io/socialshop-links/service.html?id=123
    if (uri.scheme == 'https' &&
        uri.host == 'JUClean.github.io' &&
        uri.path.contains('/JUCLEAN/service.html')) {

      return uri.queryParameters['id'];
    }
    // Handle custom scheme: juclean://service/123
    else if (uri.scheme == 'juclean' && uri.host == 'service') {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments[0];
      }
    }
    return null;
  }

  void _navigateToService(String serviceId) {
    // Fetch service details from Firestore using serviceId
    FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .get()
        .then((doc) {
      if (doc.exists && mounted) {
        final serviceData = doc.data() as Map<String, dynamic>;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Detailservice(
              name: serviceData['name'],
              description: serviceData['description'],
              price: serviceData['price'],
              imgurl: serviceData['imgurl'],
              id: serviceId,
              additional: serviceData['rooms'] ?? '',
              rooms: serviceData['additional'] ?? '',
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service not found')),
        );
      }
    }).catchError((error) {
      print('Error fetching service: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading service')),
        );
      }
    });
  }

// Add this to your dispose method




  Widget _buildServiceCard({
    required String title,
    required String company,
    required String price,
    required String description,
    required Color color,
    required Color textColor,
    required Gradient gradient,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              translatedtranslatedText(
                company,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              translatedtranslatedText(
                title,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              translatedtranslatedText(
                description,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              translatedtranslatedText(
                price,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                  .shake(delay: 1000.ms, hz: 2),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2);
  }

  Widget _buildRecentServiceCard({
    required String title,
    required String description,
    required String price,
    required String imgurl,
  }) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Hero(
              tag: 'service-image-$title',
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Image.network(
                  imgurl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.cleaning_services, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  translatedtranslatedText(
                    title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2F3534),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  translatedtranslatedText(
                    description,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF787D7D),
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  translatedtranslatedText(
                    price,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF787E7D),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey)
                .animate().shake(delay: 500.ms, hz: 3),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.exit_to_app, size: 50, color: Colors.blueAccent),
              const SizedBox(height: 20),
              translatedtranslatedText('Exit App',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 10),
              translatedtranslatedText('Are you sure you want to exit?',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: translatedtranslatedText('Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      child: translatedtranslatedText('Exit',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child:Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) {
    return Column(
          children: [
            if(_selectedItemPosition == 0)
              FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                      scale: _scaleAnimation,
                      child:Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blueAccent[700]!,
                      Colors.blueAccent[400]!,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          // App Bar
                          Row(
                            children: [
                              translatedtranslatedText('Home',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ).animate().fadeIn(delay: 100.ms),
                              const Spacer(),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(43),
                                clipBehavior: Clip.hardEdge,
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ).animate().scale(delay: 150.ms),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Welcome Text
                          translatedtranslatedText('Hi, $userName',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 8),
                          translatedtranslatedText('Wo Reinheit beginnt - und Eindruck bleibt.',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                              height: 1.4,
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: 20),

                          // Search Bar
                      FeaturesTour(
                        controller: tourController,
                        index: 0, introduce: translatedtranslatedText(
                        'Here you can Search for service',
                      ),
                        child:  InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 300),
                                  pageBuilder: (_, __, ___) => const SearchC(),
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
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IgnorePointer(
                                child: TextFormField(
                                  controller: searchController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: 'Search for services...',
                                    prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),
                          ), ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // Popular Cleaning Services
                    FeaturesTour(
                      controller: tourController,
                      index: 1, introduce: translatedtranslatedText(
                      'Here you can see all services available',
                    ),
                      child:  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(25),
                          topLeft: Radius.circular(25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, -5),
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                        children: [
        SizedBox(height: 16,),
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    translatedtranslatedText('Recent Services',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF2F3534),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ).animate().slideX(
                                      begin: -10,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () {
                                        // Add navigation to all services
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) =>  Allservices(),
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              return ScaleTransition(
                                                scale: animation,
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: translatedtranslatedText('See All',
                                        style: GoogleFonts.poppins(
                                          color: Colors.blue.shade600,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: 100.ms),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Modern Recent Services List
                              StreamBuilder(
                                stream: FirebaseFirestore.instance.collection('services').snapshots(),
                                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return  Center(
                                      child: CircularProgressIndicator().animate().scale(
                                        begin: Offset(0.8, 0.8),
                                        end: Offset(1, 1),
                                        curve: Curves.easeInOut,
                                      ),
                                    );
                                  }

                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.cleaning_services_outlined,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 8),
                                          translatedtranslatedText('No services available',
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ).animate().fadeIn(),
                                    );
                                  }

                                  return ListView.separated(
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: snapshot.data!.docs.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final booking = snapshot.data!.docs[index];
                                      final bookingData = booking.data() as Map<String, dynamic>;

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              transitionDuration: const Duration(milliseconds: 400),
                                              pageBuilder: (_, __, ___) => Detailservice(
                                                name: bookingData['name'],
                                                description: bookingData['description'],
                                                price: bookingData['price'],
                                                imgurl: bookingData['imgurl'],
                                                id: booking.id.toString(),
                                                additional: bookingData['rooms'],
                                                rooms: bookingData['additional'],
                                              ),
                                              transitionsBuilder: (_, animation, __, child) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin: const Offset(0, 0.1),
                                                      end: Offset.zero,
                                                    ).animate(CurvedAnimation(
                                                      parent: animation,
                                                      curve: Curves.fastOutSlowIn,
                                                    )),
                                                    child: child,
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        child: _buildModernServiceCard(
                                          title: bookingData['name'],
                                          description: bookingData['description'],
                                          imgurl: bookingData['imgurl'], id: booking.id,
                                        ),
                                      ).animate().fadeIn(delay: (100 * index).ms);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          // Popular Services Cards

                          const SizedBox(height: 20),

// Popular Services - Horizontal List with modern enhancements
                          translatedtranslatedText('Popular Services',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),


                          SizedBox(
                            height: 250, // Optimal height for visual impact
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              controller: ScrollController(initialScrollOffset: _calculateMiddleOffset()),
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                final services = [
                                  {
                                    'title': 'Deep Clean',
                                    'price': 'From \$120',
                                    'icon': Icons.cleaning_services_rounded,
                                    'gradient': [Color(0xFF6A11CB), Color(0xFF2575FC)], // Purple to blue
                                    'highlight': Colors.amber.shade100,
                                    'time': '3-5 hours',
                                  },
                                  {
                                    'title': 'Office Clean',
                                    'price': 'From \$200',
                                    'icon': Icons.workspace_premium_rounded,
                                    'gradient': [Color(0xFF11998E), Color(0xFF38EF7D)], // Teal to green
                                    'highlight': Colors.lightBlue.shade100,
                                    'time': '5-8 hours',
                                  },
                                  {
                                    'title': 'Carpet Clean',
                                    'price': 'From \$150',
                                    'icon': Icons.carpenter_rounded,
                                    'gradient': [Color(0xFFFC466B), Color(0xFF3F5EFB)], // Pink to purple
                                    'highlight': Colors.pink.shade100,
                                    'time': '2-4 hours',
                                  },
                                ];

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    // Add navigation or dialog here
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 24),
                                    child: AspectRatio(
                                      aspectRatio: 0.85,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(28),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: services[index]['gradient'] as List<Color>,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (services[index]['gradient'] as List<Color>)[0]
                                                  .withOpacity(0.3),
                                              blurRadius: 24,
                                              spreadRadius: -8,
                                              offset: const Offset(0, 16),
                                            )
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            // Decorative elements
                                            Positioned(
                                              top: -30,
                                              right: -30,
                                              child: Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: (services[index]['highlight'] as Color)
                                                      .withOpacity(0.15),
                                                ),
                                              ).animate(onPlay: (controller) => controller.repeat())
                                                  .scale(
                                                begin: const Offset(1, 1),
                                                end: const Offset(1.3, 1.3),
                                                duration: 3000.ms,
                                                curve: Curves.easeInOut,
                                              ),
                                            ),

                                            // Main content
                                            Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Icon with floating effect
                                                  Container(
                                                    width: 56,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(18),
                                                    ),
                                                    child: Icon(
                                                      services[index]['icon'] as IconData,
                                                      color: Colors.white,
                                                      size: 30,
                                                    ),
                                                  ).animate(onPlay: (controller) => controller.repeat())
                                                      .moveY(
                                                    begin: 0,
                                                    end: -10,
                                                    duration: 2000.ms,
                                                    curve: Curves.easeInOut,
                                                  ),

                                                  const Spacer(),

                                                  // Service details
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Title with subtle animation
                                                      translatedtranslatedText(
                                                        services[index]['title'] as String,
                                                        style: GoogleFonts.poppins(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.w700,
                                                          height: 1.2,
                                                        ),
                                                      ).animate().fadeIn(delay: 100.ms),

                                                      const SizedBox(height: 6),

                                                      // Time indicato
                                                      const SizedBox(height: 8),

                                                      // Price with shimmer effect

                                                    ],
                                                  ),

                                                  const Spacer(),

                                                  // Book Now button with improved interaction
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          PageRouteBuilder(
                                                            pageBuilder: (context, animation, secondaryAnimation) =>  Allservices(),
                                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                              return ScaleTransition(
                                                                scale: animation,
                                                                child: child,
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      borderRadius: BorderRadius.circular(14),
                                                      child: Ink(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 20, vertical: 12),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.25),
                                                          borderRadius: BorderRadius.circular(14),
                                                          border: Border.all(
                                                            color: Colors.white.withOpacity(0.4),
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            translatedtranslatedText('Book Now',
                                                              style: GoogleFonts.poppins(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 15,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Icon(
                                                              Icons.arrow_forward_rounded,
                                                              color: Colors.white,
                                                              size: 18,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ).animate().slideX(
                                                    begin: 0.5,
                                                    end: 0,
                                                    curve: Curves.easeOutBack,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ).animate()
                                          .scaleXY(
                                        begin: 0.9,
                                        end: 1,
                                        duration: 400.ms,
                                        curve: Curves.easeOutBack,
                                      )
                                          .fadeIn(delay: 200.ms),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          const SizedBox(height: 20),
                        ],
                      ),
                    )),

                  ],
                ),
              ))),

            if(_selectedItemPosition == 1)
               Container(child: MyBookings()),
            if(_selectedItemPosition == 2)
            FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
            scale: _scaleAnimation,
            child:Profile(),)),

          ],
        );


    }
      ),
      ),
      floatingActionButton: Row(
        children: [   SizedBox(width: 25,),
          FloatingActionButton.extended(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: Colors.blueAccent),
            label: translatedtranslatedText('Logout',
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 3,
          ).animate().scale(delay: 300.ms),
          SizedBox(width: 10,),
          FloatingActionButton(
            onPressed: _showContactOptions,
            backgroundColor: Colors.green, // WhatsApp green
            child: const Icon(Icons.contact_support, color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: SnakeNavigationBar.color(
        behaviour: SnakeBarBehaviour.floating,
        snakeShape: SnakeShape.rectangle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(12),
        snakeViewColor: Colors.blueAccent,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.blueGrey,
        elevation: 5,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        currentIndex: _selectedItemPosition,
        onTap: (index) => setState(() => _selectedItemPosition = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(IconlyBroken.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(IconlyBroken.activity), label: 'My Booking'),
          BottomNavigationBarItem(icon: Icon(IconlyBroken.profile), label: 'Profile'),
        ],
      ).animate().scaleXY(
        begin: 0.9,
        end: 1,
        curve: Curves.elasticOut,
      ),
    ));
  }double _calculateMiddleOffset() {
    final cardWidth = MediaQuery.of(context).size.width * 0.50; // AspectRatio 0.85
    final spacing = 24.0; // Your padding.right value
    return (cardWidth + spacing) * 1; // 1 is the middle index (0-based)
  }
  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            translatedtranslatedText('Contact Us',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: translatedtranslatedText('Email Support'),
              onTap: () {
                Navigator.pop(context);
                _launchEmail();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: translatedtranslatedText('WhatsApp Chat'),
              onTap: () {
                Navigator.pop(context);
                _launchWhatsApp();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: translatedtranslatedText('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'juclean988@gmail.com',
      queryParameters: {
        'subject': 'JUClean Support Request',
        'body': 'Hello JUClean team,',
      },
    );

   /* if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Could not launch email client')),
      );
    }*/
  }

  Future<void> _launchWhatsApp() async {
    const phone = '+491744012556'; // Replace with your WhatsApp business number
    const message = 'Hello JUClean team, I need assistance with...';

    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

  /*  if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('WhatsApp not installed')),
      );
    }*/
  }

  Widget _buildModernServiceCard({
    required String title,
    required String description,
    required String imgurl,
    required String id, // Add ID parameter
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Service Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: CachedNetworkImage(
              imageUrl: imgurl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.error_outline),
              ),
            ),
          ),

          // Service Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: translatedtranslatedText(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2F3534),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.share, size: 20),
                        onPressed: () => _shareService(id, title, description),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  translatedtranslatedText(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: translatedtranslatedText('View Details',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Add the share function
  void _shareService(String serviceId, String title, String description) async {
    try {
      // Replace with your actual GitHub Pages URL
      final String githubPagesUrl = 'https://juclean.github.io/JUCLEAN/service.html?id=$serviceId';

      final String shareText = 'Check out this cleaning service from JUClean: $title\n'
          '$description\n'
          'View details: $githubPagesUrl';

      await Share.share(
        shareText,
        subject: 'JUClean Service: $title',
      );
    } catch (e) {
      print('Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share. Please try again.')),
        );
      }
    }
  }
  Future<void> _showLogoutDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: ModalRoute.of(context)!.animation!,
            curve: Curves.fastOutSlowIn,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, size: 50, color: Colors.blueAccent),
                const SizedBox(height: 20),
                translatedtranslatedText('Logout Confirmation',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 10),
                translatedtranslatedText('Are you sure you want to logout?',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: translatedtranslatedText('Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => logout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                        ),
                        child: translatedtranslatedText('Logout',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}