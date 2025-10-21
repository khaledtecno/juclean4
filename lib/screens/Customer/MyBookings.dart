import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../FastTranslationService.dart';
import '../FastTranslationService.dart';
class MyBookings extends StatefulWidget {
  const MyBookings({super.key});

  @override
  State<MyBookings> createState() => _MyBookingsState();
}

class _MyBookingsState extends State<MyBookings> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _user;
  String _searchQuery = '';
  String _sortBy = 'All';
  bool isLoadingUser = true; // Loading state
  bool _isMalay = false;
  bool _isRefreshing = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();    _user = _auth.currentUser!;
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


  @override
  Widget build(BuildContext context) {
    return  SafeArea(
        child: Column(
      children: [
        // Fixed height header section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
               bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  translatedtranslatedText('My Bookings',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2F3534),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 20),
              // Search Bar
              TextFormField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search bookings...',
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF787D7D),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFC9CCCC)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFEAEBEC)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              // Sort by Dropdown
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: InputDecoration(
                  hintText: 'Sort by',
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF787D7D),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFEAEBEC)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items:  [
                  DropdownMenuItem(value: 'All', child: translatedtranslatedText('All Bookings')),
                  DropdownMenuItem(value: 'pending', child: translatedtranslatedText('Pending')),
                  DropdownMenuItem(value: 'confirmed', child: translatedtranslatedText('Confirmed')),
                  DropdownMenuItem(value: 'completed', child: translatedtranslatedText('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: translatedtranslatedText('Cancelled')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Scrollable content section
        Container(
          height: MediaQuery.of(context).size.height-250,
          width: double.infinity,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('bookings')
                .where('userId', isEqualTo: _user.uid)
                .orderBy('bookingDateTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: translatedtranslatedText('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cleaning_services, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      translatedtranslatedText('No bookings yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      translatedtranslatedText('Book a service to see it here',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Filter and sort bookings
              var bookings = snapshot.data!.docs.where((doc) {
                final booking = doc.data() as Map<String, dynamic>;
                final matchesSearch = _searchQuery.isEmpty ||
                    booking['serviceName'].toString().toLowerCase().contains(_searchQuery) ||
                    booking['address']['address'].toString().toLowerCase().contains(_searchQuery);

                final matchesStatus = _sortBy == 'All' ||
                    booking['status'].toString().toLowerCase() == _sortBy.toLowerCase();

                return matchesSearch && matchesStatus;
              }).toList();

              if (bookings.isEmpty) {
                return Center(
                  child: translatedtranslatedText('No bookings match your search',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  var booking = bookings[index].data() as Map<String, dynamic>;
                  var bookingId = bookings[index].id;

                  // Parse booking date
                  Timestamp bookingTimestamp = booking['bookingDateTime'];
                  DateTime bookingDate = bookingTimestamp.toDate();
                  String formattedDate = DateFormat('MMM dd, yyyy').format(bookingDate);
                  String formattedTime = DateFormat('hh:mm a').format(bookingDate);

                  // Determine status display
                  String status = booking['status'] ?? 'pending';
                  Color statusColor;
                  IconData statusIcon;
                  String statusText;

                  switch (status.toLowerCase()) {
                    case 'pending':
                      statusColor = const Color(0x3DFFDC25);
                      statusIcon = Icons.access_time;
                      statusText = 'Pending';
                      break;
                    case 'confirmed':
                      statusColor = const Color(0x3D3B82F6);
                      statusIcon = Icons.check_circle_outline;
                      statusText = 'Confirmed';
                      break;
                    case 'completed':
                      statusColor = const Color(0x2822C55E);
                      statusIcon = Icons.check_circle;
                      statusText = 'Completed';
                      break;
                    case 'cancelled':
                      statusColor = const Color(0x3DDF0003);
                      statusIcon = Icons.cancel;
                      statusText = 'Cancelled';
                      break;
                    default:
                      statusColor = Colors.grey.withOpacity(0.2);
                      statusIcon = Icons.help_outline;
                      statusText = 'Unknown';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildBookingCard(
                      context,
                      booking:booking,
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
                      onTap: () {
                        _showBookingDetails(context, booking);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),

      ],
    ))

    ;
  }
  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    Timestamp bookingTimestamp = booking['bookingDateTime'];
    DateTime bookingDate = bookingTimestamp.toDate();
    String formattedDate = DateFormat('MMM dd, yyyy').format(bookingDate);
    String formattedTime = DateFormat('hh:mm a').format(bookingDate);
    Color statusColor = _getStatusColor(booking['status']);

    // Get employee info from the booking map
    Map<String, dynamic>? employeeInfo;
    if (booking['status'] == 'confirmed' && booking['employee'] != null) {
      employeeInfo = booking['employee'] as Map<String, dynamic>;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blueAccent[700]!,
                        Colors.blueAccent[400]!,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      translatedtranslatedText(
                        booking['serviceName'] ?? 'Booking Details',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: translatedtranslatedText(
                          '${booking['status'] ?? 'pending'}'.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildModernDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Date & Time',
                        value: '$formattedDate at $formattedTime',
                        iconColor: Colors.blueAccent,
                      ),
                      const SizedBox(height: 16),
                      _buildModernDetailRow(
                        icon: Icons.attach_money,
                        label: 'Price',
                        value: '\$${booking['servicePrice'] ?? ' '}',
                        iconColor: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildModernDetailRow(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: booking['selectedLocationAddress'] ?? 'Not specified',
                        iconColor: Colors.orange,
                      ),


                      if (booking['notes'] != null && booking['notes'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildModernDetailRow(
                            icon: Icons.notes,
                            label: 'Notes',
                            value: booking['notes'],
                            iconColor: Colors.teal,
                          ),
                        ),
                      // Show employee contact info if booking is confirmed and info exists
                      if (booking['status'] == 'confirmed' && employeeInfo != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              translatedtranslatedText('Your Cleaner',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    _buildModernDetailRow(
                                      icon: Icons.person,
                                      label: 'Name',
                                      value: employeeInfo['Name'] ?? 'Not specified',
                                      iconColor: Colors.blue,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildModernDetailRow(
                                      icon: Icons.phone,
                                      label: 'Phone',
                                      value: employeeInfo['Phone'] ?? 'Not specified',
                                      iconColor: Colors.green,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildModernDetailRow(
                                      icon: Icons.email,
                                      label: 'Email',
                                      value: employeeInfo['Email'] ?? 'Not specified',
                                      iconColor: Colors.red,
                                    ),
                                    if (employeeInfo['link'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: _buildModernDetailRow(
                                          icon: Icons.link,
                                          label: 'Contact Link',
                                          value: employeeInfo['ContactMethod'],
                                          iconColor: Colors.purple,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getStatusIcon(booking['status']),
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  translatedtranslatedText('Current Status',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  translatedtranslatedText('${booking['status'] ?? 'pending'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
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
                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: translatedtranslatedText('Close',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (booking['status'] == 'confirmed' && employeeInfo != null) {
                              // Show contact options
                              _showContactOptions(context, employeeInfo);
                            } else {
                              // For other statuses or when no employee info
                              ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                  content: translatedtranslatedText('Contact information not available yet'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: translatedtranslatedText('Contact',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContactOptions(BuildContext context, Map<String, dynamic> employeeInfo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            translatedtranslatedText('Contact Your Cleaner',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            if (employeeInfo['Phone'] != null)
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: translatedtranslatedText('Call ${employeeInfo['Name'] ?? 'Cleaner'}'),
                subtitle: translatedtranslatedText(employeeInfo['Phone']),
                onTap: () {
                  Navigator.pop(context);
                  // launchUrl(Uri.parse('tel:${employeeInfo['Phone']}'));
                },
              ),
            if (employeeInfo['Email'] != null)
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: translatedtranslatedText('Email ${employeeInfo['Name'] ?? 'Cleaner'}'),
                subtitle: translatedtranslatedText(employeeInfo['Email']),
                onTap: () {
                  Navigator.pop(context);
                 // launchUrl(Uri.parse('mailto:${employeeInfo['Email']}'));
                },
              ),
            if (employeeInfo['link'] != null)
              ListTile(
                leading:  Icon(Icons.link, color: Colors.purple),
                title:  translatedtranslatedText('Contact Link'),
                subtitle:  translatedtranslatedText('Open contact link'),
                onTap: () {
                  Navigator.pop(context);
                 // launchUrl(Uri.parse(employeeInfo['link']));
                },
              ),
             SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:  translatedtranslatedText('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(
      BuildContext context, {
        required Map<String, dynamic> booking,
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
        String notes = '',
        VoidCallback? onTap,
      }) {
    Timestamp bookingTimestamp = booking['bookingDateTime'];
  DateTime bookingDate = bookingTimestamp.toDate();
  String formattedDate = DateFormat('MMM dd, yyyy').format(bookingDate);
  String formattedTime = DateFormat('hh:mm a').format(bookingDate);
  Color statusColor = _getStatusColor(booking['status']);

  // Get employee info from the booking map



  return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Gradient Overlay
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Status Tag
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          translatedtranslatedText(
                            status,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content Area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            translatedtranslatedText(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade900,
                              ),

                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      translatedtranslatedText(
                                        date,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      translatedtranslatedText(
                                        time,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on,
                          size: 20,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            translatedtranslatedText('Location',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            translatedtranslatedText(
                              address,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),

                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Price and Action
                  Row(
                    children: [
  /*  ElevatedButton(
    onPressed: () {

    // Show contact options


    },
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blueAccent,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
    ),
    child: translatedtranslatedText('Contact Cleaner',
    style: GoogleFonts.poppins(
    color: Colors.white,
    fontWeight: FontWeight.w500,
    ),
    ),
    ),*/
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10,),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildModernDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              translatedtranslatedText(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              translatedtranslatedText(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                translatedtranslatedText(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                translatedtranslatedText(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}