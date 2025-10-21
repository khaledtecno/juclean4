import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../FastTranslationService.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all';
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;

  final List<String> _statusFilters = [
    'all',
    'pending',
    'confirmed',
    'in_progress',
    'completed',
    'cancelled'
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  translatedtranslatedText(
                    'Order Management',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  if (!isMobile) _buildFilterDropdown(),
                ],
              ),
              const SizedBox(height: 8),
              translatedtranslatedText(
                'View, manage, and process all customer orders',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 16,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (isMobile) ...[
                const SizedBox(height: 16),
                _buildFilterChips(),
              ],
              const SizedBox(height: 24),
              if (!isMobile) _buildOrderStats(),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildOrderTableHeader(isMobile),
                      const SizedBox(height: 16),
                      _buildOrderTable(isMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: const Icon(Icons.filter_list, size: 18),
          style: GoogleFonts.poppins(fontSize: 14),
          onChanged: (String? newValue) {
            setState(() {
              _selectedFilter = newValue!;
            });
          },
          items: _statusFilters.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: translatedtranslatedText(
                value == 'all' ? 'All Orders' : _formatStatus(value),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: translatedtranslatedText(
                filter == 'all' ? 'All' : _formatStatus(filter),
                style: TextStyle(
                  color: _selectedFilter == filter ? Colors.white : Colors.black,
                ),
              ),
              selected: _selectedFilter == filter,
              onSelected: (bool selected) {
                setState(() {
                  _selectedFilter = selected ? filter : 'all';
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').capitalize();
  }

  Widget _buildOrderTableHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        translatedtranslatedText(
          'Recent Orders',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        if (!isMobile) const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildOrderTable(bool isMobile) {
    Query query = _firestore.collection('bookings').orderBy('createdAt', descending: true);

    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: translatedtranslatedText('Error loading orders'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: translatedtranslatedText('No orders found'));
        }

        final orders = snapshot.data!.docs;

        if (isMobile) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              return _buildMobileOrderCard(order, orders[index].id);
            },
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              columns: [
                DataColumn(label: translatedtranslatedText('Order')),
                DataColumn(label: translatedtranslatedText('Customer')),
                DataColumn(label: translatedtranslatedText('Service')),
                DataColumn(label: translatedtranslatedText('Date')),
                DataColumn(label: translatedtranslatedText('Status')),
                DataColumn(label: translatedtranslatedText('Actions')),
              ],
              rows: orders.map((orderDoc) {
                final order = orderDoc.data() as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          translatedtranslatedText(
                            order['orderId'] ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          translatedtranslatedText(
                            _formatDate(order['createdAt']),
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          translatedtranslatedText(order['customerName'] ?? order['name'] ?? 'N/A'),
                          const SizedBox(height: 4),
                          translatedtranslatedText(
                            order['userEmail'] ?? 'N/A',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            translatedtranslatedText(order['serviceName'] ?? 'N/A'),
                            if (order['servicePrice'] != null) ...[
                              const SizedBox(height: 4),
                              translatedtranslatedText(
                                '${order['servicePrice']}',
                                style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      translatedtranslatedText(
                        _formatDate(order['bookingDateTime'] ?? order['createdAt']),
                      ),
                    ),
                    DataCell(
                      _buildStatusChip(order['status'] ?? 'pending'),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye, size: 20),
                            color: Colors.blue,
                            onPressed: () => _showOrderDetails(order, orderDoc.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            color: Colors.orange,
                            onPressed: () => _editOrder(orderDoc.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            color: Colors.red,
                            onPressed: () => _confirmDelete(orderDoc.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildMobileOrderCard(Map<String, dynamic> order, String orderId) {
    final bookingDate = order['bookingDateTime'] as Timestamp? ?? order['createdAt'] as Timestamp;
    final formattedDate = DateFormat('MMM dd, yyyy').format(bookingDate.toDate());
    final time = DateFormat('hh:mm a').format(bookingDate.toDate());
    final serviceImage = order['img'] as String?;
    final price = order['servicePrice']?.toString() ?? '0.00';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOrderDetails(order, orderId),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        order['orderId'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(order['status'] ?? 'pending'),
                  ],
                ),
                const SizedBox(height: 16),

                // Service Image and Basic Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Image
                    if (serviceImage != null)
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(serviceImage),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),

                    // Service Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Name
                          Text(
                            order['serviceName'] ?? 'N/A',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '\$$price',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Customer Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade50,
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order['customerName'] ?? order['name'] ?? 'N/A',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Date and Time
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange.shade50,
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scheduled',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$formattedDate at $time',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.remove_red_eye, size: 18, color: Colors.white,),
                        label: const Text('Details', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade600,            backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                        onPressed: () => _showOrderDetails(order, orderId),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.white,),
                        label: const Text('Edit', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade600,
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.orange.shade200),
                        ),
                        onPressed: () => _editOrder(orderId),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete, size: 18 , color: Colors.white,),
                        label: const Text('Delete' , style: TextStyle(color: Colors.white),),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                        onPressed: () => _confirmDelete(orderId),
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

  Widget _buildStatusChip(String status) {
    final statusData = _getStatusData(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusData.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusData.icon, size: 14, color: statusData.color),
          const SizedBox(width: 6),
          translatedtranslatedText(
            _formatStatus(status),
            style: TextStyle(
                fontSize: 12,
                color: statusData.color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  StatusData _getStatusData(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return StatusData(Colors.green, Icons.check_circle);
      case 'pending':
        return StatusData(Colors.blue, Icons.hourglass_top);
      case 'cancelled':
        return StatusData(Colors.red, Icons.cancel);
      case 'completed':
        return StatusData(Colors.purple, Icons.done_all);
      case 'in_progress':
        return StatusData(Colors.orange, Icons.local_shipping);
      default:
        return StatusData(Colors.grey, Icons.help_outline);
    }
  }

  Widget _buildOrderStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        int totalOrders = orders.length;
        int pending = 0;
        int confirmed = 0;
        int inProgress = 0;
        int completed = 0;
        int cancelled = 0;

        for (var order in orders) {
          final status = (order.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() ?? '';
          switch (status) {
            case 'pending':
              pending++;
              break;
            case 'confirmed':
              confirmed++;
              break;
            case 'in_progress':
              inProgress++;
              break;
            case 'completed':
              completed++;
              break;
            case 'cancelled':
              cancelled++;
              break;
          }
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                translatedtranslatedText(
                  'Order Statistics',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatItem('Total Orders', totalOrders.toString(), Icons.shopping_bag, Colors.blue),
                      _buildStatItem('Pending', pending.toString(), Icons.hourglass_top, Colors.blue),
                      _buildStatItem('Confirmed', confirmed.toString(), Icons.check_circle, Colors.green),
                      _buildStatItem('In Progress', inProgress.toString(), Icons.local_shipping, Colors.orange),
                      _buildStatItem('Completed', completed.toString(), Icons.done_all, Colors.purple),
                      _buildStatItem('Cancelled', cancelled.toString(), Icons.cancel, Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              translatedtranslatedText(
                value,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          translatedtranslatedText(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order, String orderId) {
    final bookingDate = order['bookingDateTime'] as Timestamp? ?? order['createdAt'] as Timestamp;
    final createdAt = order['createdAt'] as Timestamp;
    final formattedBookingDate = DateFormat('MMM dd, yyyy - hh:mm a').format(bookingDate.toDate());
    final formattedCreatedAt = DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt.toDate());

    // Extract location if available
    if (order['selectedCoordinates'] != null) {
      final coords = order['selectedCoordinates'] as GeoPoint;
      _selectedLocation = LatLng(coords.latitude, coords.longitude);
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                translatedtranslatedText(
                  'Order Details',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildStatusChip(order['status'] ?? 'pending'),
                                const Spacer(),
                                translatedtranslatedText(
                                  order['orderId'] ?? 'N/A',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailItem('Booking Date', formattedBookingDate),
                                      _buildDetailItem('Created At', formattedCreatedAt),
                                      if (order['servicePrice'] != null)
                                        _buildDetailItem('Price', order['servicePrice']),
                                    ],
                                  ),
                                ),
                                if (order['img'] != null) ...[
                                  const SizedBox(width: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: order['img'],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Service Details
                    _buildSectionTitle('Service Details'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetailItem('Service Name', order['serviceName'] ?? 'N/A'),
                            if (order['notes'] != null && order['notes'].toString().isNotEmpty)
                              _buildDetailItem('Customer Notes', order['notes']),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customer Details
                    _buildSectionTitle('Customer Details'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetailItem('Name', order['customerName'] ?? order['name'] ?? 'N/A'),
                            _buildDetailItem('Email', order['userEmail'] ?? 'N/A'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Details
                    if (_selectedLocation != null || order['selectedLocationAddress'] != null) ...[
                      _buildSectionTitle('Location Details'),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (order['selectedLocationAddress'] != null)
                                _buildDetailItem('Address', order['selectedLocationAddress']),
                              const SizedBox(height: 12),
                              if (_selectedLocation != null) ...[
                                SizedBox(
                                  height: 200,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: _selectedLocation!,
                                        zoom: 15,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId('orderLocation'),
                                          position: _selectedLocation!,
                                          infoWindow: InfoWindow(
                                            title: 'Service Location',
                                            snippet: order['selectedLocationAddress'] ?? '',
                                          ),
                                        ),
                                      },
                                      onMapCreated: (controller) {
                                        _mapController = controller;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.map, size: 16),
                                    label: translatedtranslatedText('Open in Maps'),
                                    onPressed: () {
                                    /*  if (order['mapLink'] != null) {
                                        launchUrl(Uri.parse(order['mapLink']));
                                      } else if (_selectedLocation != null) {
                                        launchUrl(Uri.parse(
                                            'https://www.google.com/maps/search/?api=1&query=${_selectedLocation!.latitude},${_selectedLocation!.longitude}'));
                                      }*/
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Employee Details
                    if (order['employee'] != null) ...[
                      _buildSectionTitle('Assigned Employee'),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildDetailItem('Name', order['employee']['Name']),
                              _buildDetailItem('Phone', order['employee']['Phone']),
                              _buildDetailItem('Email', order['employee']['Email']),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tools
                    if (order['employeeTools'] != null && (order['employeeTools'] as List).isNotEmpty) ...[
                      _buildSectionTitle('Required Tools'),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...(order['employeeTools'] as List).map((tool) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_box_outline_blank, size: 16),
                                    const SizedBox(width: 8),
                                    translatedtranslatedText(tool.toString()),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _editOrder(orderId),
                    child: translatedtranslatedText('Update Status'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(orderId);
                    },
                    child: translatedtranslatedText('Delete Order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: translatedtranslatedText(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16),
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: translatedtranslatedText(
              '$label:',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: translatedtranslatedText(
              value ?? 'Not specified',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: translatedtranslatedText('Confirm Delete'),
        content: translatedtranslatedText('Are you sure you want to delete this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: translatedtranslatedText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _firestore.collection('bookings').doc(orderId).delete();
              ElegantNotification.success(
                title: translatedtranslatedText('Order deleted'),
                description: translatedtranslatedText('The order has been successfully deleted.'),
              ).show(context);
            },
            child: translatedtranslatedText(
              'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _editOrder(String orderId) {
    final List<Map<String, dynamic>> statusOptions = [
      {'value': 'pending', 'label': 'Pending', 'icon': Icons.hourglass_top, 'color': Colors.blue},
      {'value': 'confirmed', 'label': 'Confirmed', 'icon': Icons.check_circle, 'color': Colors.green},
      {'value': 'in_progress', 'label': 'In Progress', 'icon': Icons.local_shipping, 'color': Colors.orange},
      {'value': 'completed', 'label': 'Completed', 'icon': Icons.done_all, 'color': Colors.purple},
      {'value': 'cancelled', 'label': 'Cancelled', 'icon': Icons.cancel, 'color': Colors.red},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            translatedtranslatedText(
              'Update Order Status',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...statusOptions.map((status) => ListTile(
              leading: Icon(
                status['icon'],
                color: status['color'],
              ),
              title: translatedtranslatedText(status['label']),
              onTap: () {
                Navigator.pop(context);
                _updateOrderStatus(orderId, status['value']);
              },
            )).toList(),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: translatedtranslatedText('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateOrderStatus(String orderId, String newStatus) {
    _firestore.collection('bookings').doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      ElegantNotification.success(
        title: translatedtranslatedText('Status updated'),
        description: translatedtranslatedText('Order status has been updated to ${_formatStatus(newStatus)}'),
      ).show(context);
    }).catchError((error) {
      ElegantNotification.error(
        title: translatedtranslatedText('Update failed'),
        description: translatedtranslatedText('Failed to update order status: $error'),
      ).show(context);
    });
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
  }
}

class StatusData {
  final Color color;
  final IconData icon;

  StatusData(this.color, this.icon);
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}