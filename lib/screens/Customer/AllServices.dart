import 'package:flutter/cupertino.dart';import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:iconly/iconly.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:juclean/screens/Customer/CleanerSearchScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../FastTranslationService.dart';
import 'DetailService.dart';
import 'MyBookings.dart';
import 'Profile.dart';
import 'SearchC.dart';
import 'package:flutter/material.dart';
class Allservices extends StatefulWidget {
  const Allservices({super.key});

  @override
  State<Allservices> createState() => _AllservicesState();
}

class _AllservicesState extends State<Allservices> {
  bool isLoadingUser = true; // Loading state
  bool _isMalay = false;
  bool _isRefreshing = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
 _getLanguagePreference();_initializeTranslations();
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    // Back Arrow Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_sharp,
                          color: Colors.grey.shade800,
                          size: 20,
                        ),
                      ),
                    ).animate().fadeIn(delay: 50.ms),

                    const SizedBox(width: 16),

                    translatedtranslatedText('All Services',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.8,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchC(),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade50,
                        ),
                        child: Icon(
                          IconlyBroken.search,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                    ).animate().scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 300.ms,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('services').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator().animate().scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
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
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final booking = snapshot.data!.docs[index];
                        final bookingData = booking.data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
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
                                    id: booking.id,
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
                              imgurl: bookingData['imgurl'],
                            ),
                          ).animate().fadeIn(delay: (100 * index).ms),
                        );
                      },
                      childCount: snapshot.data!.docs.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildModernServiceCard({
    required String title,
    required String description,
    required String imgurl,
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
                  translatedtranslatedText(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2F3534),
                    ),

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
}
