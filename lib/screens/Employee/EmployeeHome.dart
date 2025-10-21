import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:juclean/screens/Employee/DetailServiceEmployee.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../../main.dart';
import '../FastTranslationService.dart';
import 'MaterialRequestsPage.dart';

class EmployeeHome extends StatefulWidget {
  const EmployeeHome({super.key});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> with SingleTickerProviderStateMixin {
  bool _isOnline = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _user;
  String _searchQuery = '';
  String _sortBy = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    _loadUserSelectedService();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Service selection variables
  String? _currentServiceId;
  String _currentServiceName = 'No service selected';
  String _currentServiceDescription = '';
  String _currentServiceImage = '';
  Map<String, dynamic>? _currentServiceData;

  Future<void> _loadUserSelectedService() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.email)
        .collection('selectedService')
        .doc('current')
        .get();

    if (doc.exists) {
      setState(() {
        _currentServiceId = doc.data()?['serviceId'];
        _currentServiceName = doc.data()?['name'] ?? 'No service selected';
        _currentServiceDescription = doc.data()?['description'] ?? '';
        _currentServiceImage = doc.data()?['imgurl'] ?? '';
        _currentServiceData = doc.data();
      });
    }
  }

  Future<void> _selectService(Map<String, dynamic> serviceData, String serviceId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('selectedService')
          .doc('current')
          .set({
        'serviceId': serviceId,
        'name': serviceData['name'],
        'description': serviceData['description'],
        'imgurl': serviceData['imgurl'],
        'price': serviceData['price'],
        'selectedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _currentServiceId = serviceId;
        _currentServiceName = serviceData['name'] ?? 'No name';
        _currentServiceDescription = serviceData['description'] ?? '';
        _currentServiceImage = serviceData['imgurl'] ?? '';
        _currentServiceData = serviceData;

      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Failed to save service selection: $e')),
      );
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: translatedtranslatedText('Booking status updated to $newStatus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Failed to update booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded, size: 22, color: Color(0xFF2F3534)),
          ),
          onPressed: () => logout(context),
        ),
        title: translatedtranslatedText('Employee Home',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2F3534),
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1),
        actions: [


          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: ColorTween(
              begin: Colors.grey.shade100,
              end: _isOnline ? Colors.green.shade50 : Colors.grey.shade100,
            ),
            builder: (context, color, child) {
              return Container(
                margin: const EdgeInsets.only(right: 12, left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isOnline ? Colors.green.shade200 : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child:translatedtranslatedText(
                        _isOnline ? 'ONLINE' : 'OFFLINE',

                        style: GoogleFonts.poppins(
                          color: _isOnline ? Colors.green.shade800 : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.9,
                      child: Switch.adaptive(
                        value: _isOnline,
                        onChanged: (value) {
                          setState(() => _isOnline = value);
                          _updateEmployeeStatus(value);
                        },
                        activeColor: Colors.white,
                        activeTrackColor: Colors.green,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade400,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              );
            },
          ).animate().fadeIn(delay: 200.ms),
        ],
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader().animate().slideY(begin: 0.2, duration: 400.ms),
                        const SizedBox(height: 24),
                        _buildServiceCard().animate().slideY(begin: 0.3, duration: 450.ms),
                        const SizedBox(height: 24),

                        _buildBookingsList().animate().slideY(begin: 0.5, duration: 550.ms),
                        const SizedBox(height: 72),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),floatingActionButton: FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaterialRequestsPage(),
          ),
        );
      },
      child: const Icon(Icons.history , color: Colors.white,),
      backgroundColor: Colors.blueAccent,
isExtended: true,
      tooltip: 'Request Material',
    ),
    );
  }
  Widget _buildServiceCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;
        final bool isMediumScreen = constraints.maxWidth > 400;
        final double cardPadding = isLargeScreen ? 28.0 : 20.0;
        final double imageHeight = isLargeScreen ? 180.0 : 140.0;

        return Card(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 24 : 1,
            vertical: 5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with subtle floating effect
                    MouseRegion(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade100.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_mosaic_rounded,
                              color: Colors.blue.shade600,
                              size: isMediumScreen ? 24 : 22,
                            ),
                            const SizedBox(width: 12),
                            translatedtranslatedText('Current Service',
                              style: GoogleFonts.poppins(
                                fontSize: isMediumScreen ? 17 : 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Service Card with glass morphism effect
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.7),
                            Colors.grey.shade50.withOpacity(0.4),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          translatedtranslatedText('SELECTED SERVICE',
                            style: GoogleFonts.poppins(
                              fontSize: isMediumScreen ? 11 : 10,
                              color: Colors.blueGrey.shade400,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_currentServiceImage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      _currentServiceImage,
                                      width: double.infinity,
                                      height: imageHeight,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.05),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn().scale(
                                  duration: 500.ms,
                                  curve: Curves.easeOutBack,
                                ),
                              ),
                            ),

                         translatedtranslatedText(
                            _currentServiceName,
                            style: GoogleFonts.poppins(
                              fontSize: isMediumScreen ? 18 : 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                            ),

                          ),

                          if (_currentServiceDescription.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child:translatedtranslatedText(
                                _currentServiceDescription,
                                style: GoogleFonts.poppins(
                                  fontSize: isMediumScreen ? 14 : 12,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),

                              ),
                            ),

                          if (_currentServiceData != null &&
                              _currentServiceData!['price'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  translatedtranslatedText('Price: ',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMediumScreen ? 14 : 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),

                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Animated Gradient Button
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade100,
                              Colors.blue.shade200,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade100.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _showServiceSelectionDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              vertical: isLargeScreen ? 18 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: isMediumScreen ? 22 : 20,
                                color: Colors.blue.shade800,
                              ),
                              const SizedBox(width: 10),
                              translatedtranslatedText('Change Service',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMediumScreen ? 15 : 13,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                            .shimmer(
                          duration: 2000.ms,
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 768;
        final bool isMediumScreen = constraints.maxWidth > 480;
        final double listHeight = isLargeScreen
            ? MediaQuery.of(context).size.height - 320
            : MediaQuery.of(context).size.height - 280;

        // Status filter options
        final List<Map<String, dynamic>> statusFilters = [
          {'label': 'All', 'value': 'All', 'color': Colors.grey},
          {'label': 'Pending', 'value': 'pending', 'color': Colors.orange},
          {'label': 'Confirmed', 'value': 'confirmed', 'color': Colors.blue},
          {'label': 'Completed', 'value': 'completed', 'color': Colors.green},
          {'label': 'Cancelled', 'value': 'cancelled', 'color': Colors.red},
        ];

        return Column(
          children: [
            // Header with Filter Chips
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 24 : 16,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      translatedtranslatedText('My Bookings',
                        style: GoogleFonts.poppins(
                          fontSize: isLargeScreen ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.filter_alt_rounded, size: isLargeScreen ? 28 : 24),
                        onPressed: () {
                          // Optional: Show filter dialog/sheet
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status Filter Chips
                  SizedBox(
                    height: isLargeScreen ? 50 : 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: statusFilters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = statusFilters[index];
                        final isSelected = _sortBy == filter['value'];
                        return ChoiceChip(
                          label:translatedtranslatedText(
                            filter['label'],
                            style: GoogleFonts.poppins(
                              fontSize: isLargeScreen ? 14 : 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : filter['color'],
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _sortBy = selected ? filter['value'].toString() : 'All';
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: filter['color'],
                          side: BorderSide(
                            color: isSelected ? filter['color'] : Colors.grey.shade300,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: isSelected ? 2 : 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 16 : 12,
                            vertical: isLargeScreen ? 8 : 6,
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Bookings List

       Container(
         width: double.infinity,height: MediaQuery.of(context).size.height-150,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 24 : 16,
                ),
         child: StreamBuilder<QuerySnapshot>(
           stream: _firestore
               .collection('bookings')
               .orderBy('bookingDateTime', descending: true)
               .snapshots(),
           builder: (context, snapshot) {
             if (snapshot.hasError) {
               return Center(
                 child: translatedtranslatedText('Error loading bookings',
                   style: GoogleFonts.poppins(
                     fontSize: 16,
                     color: Colors.red.shade600,
                   ),
                 ),
               );
             }

             if (snapshot.connectionState == ConnectionState.waiting) {
               return Center(
                   child: CircularProgressIndicator()
               );
             }

             if (snapshot.data!.docs.isEmpty) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     translatedtranslatedText('No Bookings Found',
                       style: GoogleFonts.poppins(
                         fontSize: isLargeScreen ? 22 : 18,
                         fontWeight: FontWeight.w600,
                         color: Colors.grey.shade600,
                       ),
                     ),
                     const SizedBox(height: 8),
                     translatedtranslatedText('When you book a service, it will appear here',
                       style: GoogleFonts.poppins(
                         fontSize: isLargeScreen ? 16 : 14,
                         color: Colors.grey.shade500,
                       ),
                     ),
                     const SizedBox(height: 20),
                     ElevatedButton(
                       onPressed: () {
                         // Navigate to booking screen
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blue.shade600,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(12),),
                         padding: EdgeInsets.symmetric(
                           horizontal: 24,
                           vertical: isLargeScreen ? 16 : 12,
                         ),
                         elevation: 3,
                       ),
                       child: translatedtranslatedText('Book a Service',
                         style: GoogleFonts.poppins(
                           fontSize: isLargeScreen ? 16 : 14,
                           fontWeight: FontWeight.w600,
                           color: Colors.white,
                         ),
                       ),
                     ),
                   ],
                 ),
               );

             }

             // Get current user email
             final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

             var bookings = snapshot.data!.docs.where((doc) {
             final booking = doc.data() as Map<String, dynamic>;
             final status = booking['status']?.toString().toLowerCase() ?? 'pending';

             // Always show pending bookings
             if (status == 'pending') {
             return true;
             }

             // For non-pending bookings, check employee email
             final hasEmployeeEmail = booking.containsKey('employeeEm');
             final employeeMatches = hasEmployeeEmail
             ? booking['employeeEm'] == userEmail
                 : true; // Show if employeeEm field doesn't exist

             final matchesSearch = _searchQuery.isEmpty ||
             booking['serviceName'].toString().toLowerCase().contains(_searchQuery) ||
             booking['address']['address'].toString().toLowerCase().contains(_searchQuery);

             final matchesStatus = _sortBy == 'All' ||
             status == _sortBy.toLowerCase();

             return employeeMatches && matchesSearch && matchesStatus;
             }).toList();

             if (bookings.isEmpty) {
             return Center(
             child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
             Icon(
             Icons.search_off_rounded,
             size: 60,
             color: Colors.grey.shade400,
             ),
             const SizedBox(height: 16),
             translatedtranslatedText('No matching bookings',
             style: GoogleFonts.poppins(
             fontSize: isLargeScreen ? 20 : 16,
             fontWeight: FontWeight.w600,
             color: Colors.grey.shade600,
             ),
             ),
             const SizedBox(height: 8),
             translatedtranslatedText('Try adjusting your filters or search',
             style: GoogleFonts.poppins(
             fontSize: isLargeScreen ? 16 : 14,
             color: Colors.grey.shade500,
             ),
             ),
             ],
             ),
             );
             }

             return ListView.builder(
             physics: const BouncingScrollPhysics(),
             itemCount: bookings.length,
             itemBuilder: (context, index) {
             var booking = bookings[index].data() as Map<String, dynamic>;
             var bookingId = bookings[index].id;

             Timestamp bookingTimestamp = booking['bookingDateTime'];
             DateTime bookingDate = bookingTimestamp.toDate();
             String formattedDate = DateFormat('MMM dd, yyyy').format(bookingDate);
             String formattedTime = DateFormat('hh:mm a').format(bookingDate);

             String status = booking['status'] ?? 'pending';
             Color statusColor;
             IconData statusIcon;
             String statusText;

             switch (status.toLowerCase()) {
             case 'pending':
             statusColor = Colors.orange.shade100;
             statusIcon = Icons.access_time;
             statusText = 'Pending';
             break;
             case 'confirmed':
             statusColor = Colors.blue.shade100;
             statusIcon = Icons.check_circle_outline;
             statusText = 'Confirmed';
             break;
             case 'completed':
             statusColor = Colors.green.shade100;
             statusIcon = Icons.check_circle;
             statusText = 'Completed';
             break;
             case 'cancelled':
             statusColor = Colors.red.shade100;
             statusIcon = Icons.cancel;
             statusText = 'Cancelled';
             break;
             default:
             statusColor = Colors.grey.shade100;
             statusIcon = Icons.help_outline;
             statusText = 'Unknown';
             }

             if(_currentServiceId.toString().contains(booking['serviceId'])) {
               if(status.toString().contains('pending')){
                 return Padding(
                   padding: EdgeInsets.only(bottom: isLargeScreen ? 20 : 16),
                   child: _buildBookingCard(
                     context,
                     bookingId: bookingId,
                     title: booking['serviceName'] ?? 'Unknown Service',
                     price: booking['servicePrice']?.toString() ?? ' ',
                     status: statusText,
                     statusColor: statusColor,
                     icon: statusIcon,
                     address: booking['selectedLocationAddress'] ?? 'No address provided',
                     date: formattedDate,
                     time: formattedTime,
                     imageUrl: booking['img'],
                     notes: booking['notes'] ?? '',
                     coordinates: booking['coordinates'] as GeoPoint?,
                     mapLink: booking['mapLink'],
                     isLargeScreen: isLargeScreen,
                     onTap: () {
                       _navigateToBookingDetails(
                         context,
                         bookingId: bookingId,
                         bookingData: booking,
                         status: status,
                       );
                     },
                   ).animate().fadeIn(delay: (100 * index).ms),
                 );
               }else{
                 if(booking['employeeEm'].toString().contains(FirebaseAuth.instance.currentUser!.email.toString())){
                   return Padding(
                     padding: EdgeInsets.only(bottom: isLargeScreen ? 20 : 16),
                     child: _buildBookingCard(
                       context,
                       bookingId: bookingId,
                       title: booking['serviceName'] ?? 'Unknown Service',
                       price: booking['servicePrice']?.toString() ?? ' ',
                       status: statusText,
                       statusColor: statusColor,
                       icon: statusIcon,
                       address: booking['selectedLocationAddress'] ?? 'No address provided',
                       date: formattedDate,
                       time: formattedTime,
                       imageUrl: booking['img'],
                       notes: booking['notes'] ?? '',
                       coordinates: booking['selectedCoordinates'] as GeoPoint?,
                       mapLink: booking['mapLink'],
                       isLargeScreen: isLargeScreen,
                       onTap: () {
                         _navigateToBookingDetails(
                           context,
                           bookingId: bookingId,
                           bookingData: booking,
                           status: status,
                         );
                       },
                     ).animate().fadeIn(delay: (100 * index).ms),
                   );
                 }else{
                   return Container();
                 }
               }

             } else {
             return Container();
             }
             },
             );
           },
         ),

            ),
          ],
        );
      },
    );
  }

  Widget _buildBookingCard(
      BuildContext context, {
        required String bookingId,
        required String title,
        required String price,
        required String status,
        required Color statusColor,
        required IconData icon,
        required String address,
        required String date,
        required String time,
        required String imageUrl,
        required String notes,
        required GeoPoint? coordinates,
        required String mapLink,
        required bool isLargeScreen,
        required VoidCallback onTap,
      }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Image
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: isLargeScreen ? 100 : 80,
                              height: isLargeScreen ? 100 : 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        if (imageUrl.isNotEmpty) SizedBox(width: isLargeScreen ? 16 : 12),

                        // Booking Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child:translatedtranslatedText(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontSize: isLargeScreen ? 18 : 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade900,
                                      ),

                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isLargeScreen ? 12 : 8,
                                      vertical: isLargeScreen ? 6 : 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          icon,
                                          size: isLargeScreen ? 16 : 14,
                                          color: Colors.grey.shade800,
                                        ),
                                        SizedBox(width: isLargeScreen ? 6 : 4),
                                       translatedtranslatedText(
                                          status,
                                          style: GoogleFonts.poppins(
                                            fontSize: isLargeScreen ? 14 : 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isLargeScreen ? 12 : 8),

                              // Date and Time
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: isLargeScreen ? 18 : 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: isLargeScreen ? 8 : 6),
                                 translatedtranslatedText(
                                    date,
                                    style: GoogleFonts.poppins(
                                      fontSize: isLargeScreen ? 14 : 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(width: isLargeScreen ? 16 : 12),

                                ],
                              ),
                              SizedBox(height: isLargeScreen ? 12 : 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: isLargeScreen ? 18 : 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: isLargeScreen ? 8 : 6),
                                 translatedtranslatedText(
                                    time,
                                    style: GoogleFonts.poppins(
                                      fontSize: isLargeScreen ? 14 : 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isLargeScreen ? 10 : 8),
                              // Address
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: isLargeScreen ? 18 : 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: isLargeScreen ? 8 : 6),
                                  Expanded(
                                    child:translatedtranslatedText(
                                      address,
                                      style: GoogleFonts.poppins(
                                        fontSize: isLargeScreen ? 14 : 12,
                                        color: Colors.grey.shade700,
                                      ),

                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isLargeScreen ? 16 : 12),

                    // Price and Action Button
                    Row(
                      children: [


                        const Spacer(),
                        ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeScreen ? 20 : 16,
                              vertical: isLargeScreen ? 12 : 10,
                            ),
                            elevation: 2,
                          ),
                          child: translatedtranslatedText('View Details',
                            style: GoogleFonts.poppins(
                              fontSize: isLargeScreen ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
        ),
      ),
    );
  }


  void _navigateToBookingDetails(BuildContext context, {
    required String bookingId,
    required Map<String, dynamic> bookingData,
    required String status,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailServiceEmployee(
          bookingId: bookingId,
          bookingData: bookingData,
          status: status,
        ),
      ),
    );
  }
  void _showBookingDetails(BuildContext context, {
    required String bookingId,
    required Map<String, dynamic> bookingData,
    required String status,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Booking Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      bookingData['img'] ?? '',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Booking Details
                 translatedtranslatedText(
                    bookingData['serviceName'] ?? 'Unknown Service',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child:translatedtranslatedText(
                      status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date and Time
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 10),
                     translatedtranslatedText(
                        DateFormat('MMM dd, yyyy').format((bookingData['bookingDateTime'] as Timestamp).toDate()),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.access_time, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 10),
                     translatedtranslatedText(
                        DateFormat('hh:mm a').format((bookingData['bookingDateTime'] as Timestamp).toDate()),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price

                  const SizedBox(height: 20),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            translatedtranslatedText('Address',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                           translatedtranslatedText(
                              bookingData['address']['address'] ?? 'No address provided',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                // Open map link
                                if (bookingData['address']['mapLink'] != null) {
                                  // You'll need to implement this function
                                  _launchMap(bookingData['address']['mapLink']);
                                }
                              },
                              child: translatedtranslatedText('View on Map',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  if (bookingData['notes'] != null && bookingData['notes'].toString().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        translatedtranslatedText('Notes',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:translatedtranslatedText(
                            bookingData['notes'].toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),

                  // Action Buttons
                  if (status.toLowerCase() == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _updateBookingStatus(bookingId, 'confirmed');
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: translatedtranslatedText('Accept',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1000.ms),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _updateBookingStatus(bookingId, 'cancelled');
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: translatedtranslatedText('Reject',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (status.toLowerCase() == 'confirmed')
                    ElevatedButton(
                      onPressed: () {
                        _updateBookingStatus(bookingId, 'completed');
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: translatedtranslatedText('Mark as Completed',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1000.ms),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                translatedtranslatedText('Hello there,',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF787D7D),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                translatedtranslatedText('Ready to work today?',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2F3534),
                    fontSize: 17.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:translatedtranslatedText(
                    DateFormat('h:mm a • MMM d, y').format(DateTime.now()),
                    style: GoogleFonts.poppins(
                      color: Colors.blue.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              ],
            ),
            // Profile Avatar with Status Indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'assets/images/Emp7.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Online status indicator
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            translatedtranslatedText('Recently (history)',
              style: GoogleFonts.poppins(
                color: const Color(0xFF2F3534),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            translatedtranslatedText('See All',
              style: GoogleFonts.poppins(
                color: const Color(0xFF2F3534),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildHistoryCard(
                color: const Color(0xFF1D568C),
                name: 'Ahmed',
                service: 'Cleaning house',
                price: '25',
                icon: Icons.check,
                isWhite: true,
              ),
              const SizedBox(width: 16),
              _buildHistoryCard(
                color: Colors.white,
                name: 'Ali',
                service: 'Cleaning Villa',
                price: '1200',
                icon: Icons.access_time,
                isWhite: false,
              ),
            ].animate(interval: 100.ms).slideX(begin: 0.2),
          ),
        ),
      ],
    );
  }  Future<void> _launchMap(String url) async {
    try {
      Uri uri;

      if (url.startsWith('http')) {
        uri = Uri.parse(url);
      } else if (RegExp(r'^-?\d+\.\d+,-?\d+\.\d+$').hasMatch(url)) {
        uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$url');
      } else {
        uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(url)}');
      }

   /*   if (await canLaunchUrl(uri)) {
        /*await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );*/
      } else {
     /*   await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );*/
      }*/
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: translatedtranslatedText('Could not open map',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _launchMap(url),
          ),
          backgroundColor: Colors.blue.shade700,
        ),
      );
    }
  }

  Widget _buildHistoryCard({
    required Color color,
    required String name,
    required String service,
    required String price,
    required IconData icon,
    required bool isWhite,
  }) {
    return Container(
      width: 240,
      height: 170,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: isWhite ? Colors.white : const Color(0xFF25396F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            right: -60,
            bottom: -60,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: isWhite ? Colors.white : const Color(0xFF25396F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 27,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D6D5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 8),
                 translatedtranslatedText(
                    name,
                    style: GoogleFonts.poppins(
                      color: isWhite ? Colors.white : const Color(0xFF25396F),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    icon,
                    color: isWhite ? Colors.white : const Color(0xFF25396F),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
             translatedtranslatedText(
                service,
                style: GoogleFonts.poppins(
                  color: isWhite ? Colors.white : const Color(0xFF25396F),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              translatedtranslatedText('Paid: ${price}',
                style: GoogleFonts.poppins(
                  color: isWhite ? Colors.white : const Color(0xFF25396F),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              translatedtranslatedText('Click for more details',
                style: GoogleFonts.poppins(
                  color: isWhite ? Colors.white : const Color(0xFF25396F),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showServiceSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              translatedtranslatedText('Select a Service',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: double.infinity,
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('services').snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final service = snapshot.data!.docs[index];
                        final serviceData = service.data() as Map<String, dynamic>;

                        return ListTile(
                          onTap: () {
                            setState(() {
                              _currentServiceId = service.id;
                              _currentServiceName = serviceData['name'] ?? 'No name';
                              _currentServiceDescription = serviceData['description'] ?? '';
                              _currentServiceImage = serviceData['imgurl'] ?? '';
                            });

                            _selectService(serviceData, service.id);
                            Navigator.pop(context);
                          },
                          leading: serviceData['imgurl'] != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              serviceData['imgurl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.cleaning_services, color: Colors.grey.shade400),
                          ),
                          title:translatedtranslatedText(
                            serviceData['name'] ?? 'No name',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle:translatedtranslatedText(
                            serviceData['description'] ?? 'No description',
                            style: GoogleFonts.poppins(),
                       
                          ),
                          trailing: _currentServiceId == service.id
                              ? Icon(Icons.check_circle, color: Colors.blue)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: translatedtranslatedText('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateEmployeeStatus(bool isOnline) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .update({
          'isOnline': isOnline,
          'lastOnline': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Failed to update status: ${e.toString()}')),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: translatedtranslatedText('Confirm Logout'),
          content: translatedtranslatedText('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: translatedtranslatedText('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: translatedtranslatedText('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            ScaleTransition5(GetStarted()),
          );
        }
      } catch (e) {
        print("Logout error: $e");
      }
    }
  }
}