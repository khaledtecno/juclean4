import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../FastTranslationService.dart';
import 'DetailServiceEmployee.dart';

class SearchWorkScreen extends StatefulWidget {
  const SearchWorkScreen({super.key});

  @override
  State<SearchWorkScreen> createState() => _SearchWorkScreenState();
}

class _SearchWorkScreenState extends State<SearchWorkScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All'; // Default selected status
  String _sortBy = 'All'; // For Firestore filtering

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _statusFilters => ['All', 'pending', 'confirmed', 'completed', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: translatedtranslatedText('My Works',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Search and Filter Row
            Row(
              children: [
                // Search Field
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search jobs, clients...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Button
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.black87),
                    onPressed: () {
                      _showAdvancedFilters(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Status Filter Chips
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _statusFilters.map((status) {
                  final isActive = _sortBy == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStatusChip(
                      status == 'All' ? 'All' : status.capitalize(),
                      isActive,
                      onTap: () {
                        setState(() {
                          _sortBy = isActive ? 'All' : status;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Work List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _sortBy == 'pending'
                    ? FirebaseFirestore.instance
                    .collection('bookings')
                    .where('status', isEqualTo: 'pending')
                    .orderBy('bookingDateTime', descending: true)
                    .snapshots()
                    : FirebaseFirestore.instance
                    .collection('bookings')
                    .where('employeeEm', isEqualTo: FirebaseAuth.instance.currentUser?.email ?? '')
                    .where('status', isNotEqualTo: 'pending')
                    .orderBy('bookingDateTime', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: translatedtranslatedText('Error loading bookings'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return  Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return Center(child: translatedtranslatedText('No bookings found for your account'));
                  }

                  var bookings = snapshot.data!.docs.where((doc) {
                    final booking = doc.data() as Map<String, dynamic>;

                    // Apply search filter
                    final matchesSearch = _searchController.text.isEmpty ||
                        booking['serviceName'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
                        booking['address']['address'].toString().toLowerCase().contains(_searchController.text.toLowerCase());

                    // Apply status filter
                    final matchesStatus = _sortBy == 'All' ||
                        booking['status'].toString().toLowerCase() == _sortBy.toLowerCase();

                    return matchesSearch && matchesStatus;
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
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          translatedtranslatedText('Try adjusting your filters or search',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty || _sortBy != 'All')
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _sortBy = 'All';
                                });
                              },
                              child: translatedtranslatedText('Clear filters',
                                style: GoogleFonts.poppins(
                                  color: Colors.blue.shade800,
                                ),
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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _buildWorkCard(
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
                          statusValue: status,
                          onTap: () {
                            _navigateToBookingDetails(
                              context,
                              bookingId: bookingId,
                              bookingData: booking,
                              status: status,
                            );
                            // Navigate to booking details
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }  void _navigateToBookingDetails(BuildContext context, {
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

  void _showAdvancedFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              translatedtranslatedText('Advanced Filters',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption(
                title: 'Price Range',
                icon: Icons.attach_money,
                currentValue: '\$25 - \$100',
              ),
              _buildFilterOption(
                title: 'Date Range',
                icon: Icons.calendar_today,
                currentValue: 'Last 30 days',
              ),
              _buildFilterOption(
                title: 'Service Type',
                icon: Icons.cleaning_services,
                currentValue: 'All Services',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Apply filters here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: translatedtranslatedText('Apply Filters',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption({
    required String title,
    required IconData icon,
    required String currentValue,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blue.shade800),
      title:translatedtranslatedText(title),
      subtitle:translatedtranslatedText(
        currentValue,
        style: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Show filter options
      },
    );
  }

  Widget _buildStatusChip(String text, bool isActive, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child:translatedtranslatedText(
          text,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkCard(
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
        required String statusValue,
        required VoidCallback onTap,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Service Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Icon(Icons.cleaning_services, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   translatedtranslatedText(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                       translatedtranslatedText(
                          price.startsWith('\$') ? price.substring(1) : price,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 16, color: Colors.grey.shade800),
                              const SizedBox(width: 6),
                             translatedtranslatedText(
                                status,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
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
          const SizedBox(height: 12),
          // Address
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child:translatedtranslatedText(
                  address,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date and Time
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
             translatedtranslatedText(
                date,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
             translatedtranslatedText(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action Buttons
          if (statusValue == 'pending')
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal:  16,
                  vertical:  10,
                ),
                elevation: 2,
              ),
              child: translatedtranslatedText('View Details',
                style: GoogleFonts.poppins(
                  fontSize:  12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          if (statusValue == 'confirmed')
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal:  16,
                  vertical:  10,
                ),
                elevation: 2,
              ),
              child: translatedtranslatedText('View Details',
                style: GoogleFonts.poppins(
                  fontSize:  12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          if (statusValue == 'completed')
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: translatedtranslatedText('View Details',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (statusValue == 'cancelled')
            OutlinedButton(
              onPressed: () {
                // Book again action
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: translatedtranslatedText('Book Again',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}