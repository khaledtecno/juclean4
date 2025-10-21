import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart' as mail;
import 'package:mailer/smtp_server.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../FastTranslationService.dart';

class DetailServiceEmployee extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final String status;
  final Function(String)? onStatusChanged;

  const DetailServiceEmployee({
    super.key,
    required this.bookingId,
    required this.bookingData,
    required this.status,
    this.onStatusChanged,
  });

  @override
  State<DetailServiceEmployee> createState() => _DetailServiceEmployeeState();
}

class _DetailServiceEmployeeState extends State<DetailServiceEmployee> {
  List<String> tools = [];
  List<bool> selectedTools = [];
  List<TextEditingController> quantityControllers = [];
  bool _isLoadingTools = false;
  final TextEditingController _toolController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _contactMethodController = TextEditingController();

  Position? _currentPosition;
  String? _distanceText;
  bool _isCheckingDistance = false;
  bool _isWithinRange = false;
  var userNAME = 'Not provided';

  @override
  void initState() {
    super.initState();
    _checkDistance();
    _fetchToolsFromFirestore();

    if (widget.bookingData['employeePhone'] != null) {
      _phoneController.text = widget.bookingData['employeePhone'];
    }
    if (widget.bookingData['employeeContactMethod'] != null) {
      _contactMethodController.text = widget.bookingData['employeeContactMethod'];
    }
  }

  @override
  void dispose() {
    for (var controller in quantityControllers) {
      controller.dispose();
    }
    _toolController.dispose();
    _phoneController.dispose();
    _contactMethodController.dispose();
    super.dispose();
  }

  Future<void> _fetchToolsFromFirestore() async {
    setState(() {
      _isLoadingTools = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('materials')
          .where('isVisible', isEqualTo: true)
          .get();

      final List<String> fetchedTools = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        fetchedTools.add(data['name'] as String);
      }

      setState(() {
        tools = fetchedTools;
        selectedTools = List.generate(tools.length, (index) => false);
        quantityControllers = List.generate(
          tools.length,
              (index) => TextEditingController(text: '1'),
        );

        if (widget.bookingData['employeeToolsWithQuantities'] != null) {
          final List<dynamic> existingTools =
          widget.bookingData['employeeToolsWithQuantities'];
          for (var toolData in existingTools) {
            if (tools.contains(toolData['name'])) {
              int index = tools.indexOf(toolData['name']);
              selectedTools[index] = true;
              quantityControllers[index].text = toolData['quantity'].toString();
            }
          }
        }
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Error loading tools: $e')),
      );
    } finally {
      setState(() {
        _isLoadingTools = false;
      });
    }
  }

  Future<void> _updateBookingStatus(String newStatus) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: translatedtranslatedText('You must be logged in to update bookings')),
        );
        return;
      }

      if (widget.status.toLowerCase() == 'pending' &&
          (_phoneController.text.isEmpty || _contactMethodController.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: translatedtranslatedText('Please provide your contact information')),
        );
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: translatedtranslatedText('User details not found')),
        );
        return;
      }

      List<Map<String, dynamic>> selectedToolsWithQuantities = [];
      List<String> selectedToolNames = [];

      for (int i = 0; i < tools.length; i++) {
        if (selectedTools[i]) {
          final quantity = int.tryParse(quantityControllers[i].text) ?? 1;

          selectedToolsWithQuantities.add({
            'name': tools[i],
            'quantity': quantity,
          });
          selectedToolNames.add(tools[i]);

          await _updateToolQuantity(tools[i], quantity);
        }
      }

      await _createToolUsageHistory(selectedToolsWithQuantities, user);

      Map<String, dynamic> employeeData = {
        'employeeId': user.uid,
        'Name': userDoc['Name'] ?? 'Unknown Employee',
        'lastOnline': userDoc['lastOnline'] ?? '',
        'Email': user.email,
        'Phone': _phoneController.text,
        'ContactMethod': _contactMethodController.text,
        'assignedAt': FieldValue.serverTimestamp(),
      };

      Map<String, dynamic> updates = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'confirmed') {
        updates.addAll({
          'employee': employeeData,
          'employeeEm': user.email,
          'employeeTools': selectedToolNames,
          'employeeToolsWithQuantities': selectedToolsWithQuantities,
          'employeePhone': _phoneController.text,
          'employeeContactMethod': _contactMethodController.text,
        });
      }

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update(updates);

      if (widget.onStatusChanged != null) {
        widget.onStatusChanged!(newStatus);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: translatedtranslatedText('Booking $newStatus successfully'),
          backgroundColor: Colors.green,
        ),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: translatedtranslatedText('Failed to update booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateToolQuantity(String toolName, int usedQuantity) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('materials')
          .where('name', isEqualTo: toolName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final currentQuantity = doc['quantity'] ?? 0;
        final newQuantity = currentQuantity - usedQuantity;

        if (newQuantity < 0) {
          throw Exception('Not enough quantity available for $toolName');
        }

        await doc.reference.update({
          'quantity': newQuantity,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating tool quantity: $e');
      throw e;
    }
  }

  Future<void> _createToolUsageHistory(
      List<Map<String, dynamic>> toolsUsed, User user) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      for (var tool in toolsUsed) {
        await FirebaseFirestore.instance.collection('toolUsageHistory').add({
          'employeeId': user.uid,
          'employeeName': userDoc['Name'] ?? 'Unknown Employee',
          'employeeEmail': user.email,
          'toolName': tool['name'],
          'quantityUsed': tool['quantity'],
          'bookingId': widget.bookingId,
          'serviceName': widget.bookingData['serviceName'],
          'dateUsed': FieldValue.serverTimestamp(),
          'customerName': widget.bookingData['customerName'] ?? 'Unknown Customer',
          'customerEmail': widget.bookingData['userEmail'],
        });
      }
    } catch (e) {
      print('Error creating tool usage history: $e');
      throw e;
    }
  }

  void _addTool() {
    if (_toolController.text.isNotEmpty) {
      setState(() {
        tools.add(_toolController.text);
        selectedTools.add(false);
        quantityControllers.add(TextEditingController(text: '1'));
        _toolController.clear();
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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

  Future<void> _launchMap(String url) async {
    try {
      if (kIsWeb) {
        // Web-specific implementation
      /*  Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }*/
      } else {
       /* Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }*/
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Could not open map: $e')),
      );
    }
  }

  Future<void> _checkDistance() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.email.toString())
        .get();

    setState(() {
      _isCheckingDistance = true;
      _distanceText = null;
      _isWithinRange = false;
      userNAME = userDoc['Name'];
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      if (kIsWeb) {
        // Web-specific geolocation check
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: translatedtranslatedText('Location services are disabled')),
          );
          return;
        }

        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: translatedtranslatedText('Location permissions are denied')),
            );
            return;
          }
        }
      } else {
        // Mobile geolocation check
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: translatedtranslatedText('Location services are disabled')),
          );
          return;
        }

        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: translatedtranslatedText('Location permissions are denied')),
            );
            return;
          }
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
              content: translatedtranslatedText('Location permissions are permanently denied')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      if (widget.bookingData['selectedLocationAddress'] != null) {
        GeoPoint bookingLocation = widget.bookingData['selectedCoordinates'];
        double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          bookingLocation.latitude,
          bookingLocation.longitude,
        );

        bool isWithinRange = distanceInMeters >= 1 && distanceInMeters <= 150;

        setState(() {
          _distanceText = '${distanceInMeters.toString()} meters away';
          _isWithinRange = isWithinRange;
        });

        if (!isWithinRange) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: translatedtranslatedText('Location is too far (${distanceInMeters.toString()} meters)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Error checking distance: $e')),
      );
    } finally {
      setState(() {
        _isCheckingDistance = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.bookingData;
    final status = widget.status;
    final statusColor = _getStatusColor(status);
    GeoPoint bookingLocation = widget.bookingData['selectedCoordinates'];

    Timestamp bookingTimestamp = booking['bookingDateTime'];
    DateTime bookingDate = bookingTimestamp.toDate();
    String formattedDate = DateFormat('MMM dd, yyyy').format(bookingDate);
    String formattedTime = DateFormat('hh:mm a').format(bookingDate);

    return Scaffold(
      appBar: AppBar(
        title: translatedtranslatedText('Service Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                booking['img'] ?? '',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.cleaning_services, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status and Distance Info
            Row(
              children: [
                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:translatedtranslatedText(
                    status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                // Distance Info
                if (_distanceText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isWithinRange
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child:translatedtranslatedText(
                      _distanceText!,
                      style: GoogleFonts.poppins(
                        color: _isWithinRange ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Distance Check Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isCheckingDistance ? null : _checkDistance,
                      icon: Icon(
                        _isCheckingDistance ? Icons.hourglass_top : Icons.location_on,
                        color: Colors.white,
                      ),
                      label:translatedtranslatedText(
                        _isCheckingDistance ? 'Checking Distance...' : 'Check Distance',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_distanceText != null)
                     translatedtranslatedText(
                        _isWithinRange
                            ? 'Location is within acceptable range (1-150m)'
                            : 'Location is too far from service area',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _isWithinRange ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Service Title and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     translatedtranslatedText(
                        booking['serviceName'] ?? 'Unknown Service',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (booking['serviceDescription'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child:translatedtranslatedText(
                            booking['serviceDescription'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              ],
            ),
            const SizedBox(height: 20),

            // Client Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    translatedtranslatedText('CLIENT INFORMATION',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal[700],
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.teal[100],
                          child: Icon(Icons.person, size: 30, color: Colors.teal[700]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                             translatedtranslatedText(
                                userNAME ?? 'Unknown Customer',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                             translatedtranslatedText(
                                booking['customerPhone'] ?? 'No phone provided',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),),
                     /*
                        IconButton(
                          icon: Icon(Icons.phone, color: Colors.teal[700]),
                          onPressed: booking['customerPhone'] != null
                              ? () => launchUrl(Uri.parse('tel:${booking['customerPhone']}'))
                              : null,
                        ),*/
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(Icons.email,
                        booking['userEmail'] ?? 'No email provided'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Booking Details Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    translatedtranslatedText('BOOKING DETAILS',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal[700],
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Date',
                      formattedDate,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.access_time,
                      'Time',
                      formattedTime,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.location_on,
                      'Address',
                      '${booking['selectedLocationAddress'] ?? 'No address provided'} (Show in map)',
                      onTap: booking['selectedCoordinates'] != null
                          ? () => _launchMap('https://www.google.com/maps?q=${bookingLocation.latitude},${bookingLocation.longitude}')
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Notes Section
            if (booking['notes'] != null && booking['notes'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  translatedtranslatedText('CUSTOMER NOTES',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal[700],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:translatedtranslatedText(
                      booking['notes'].toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Tools Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                translatedtranslatedText('TOOLS REQUIRED',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal[700],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                translatedtranslatedText('Select tools and quantities you will need for this service:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),

                if (_isLoadingTools)
                  const Center(child: CircularProgressIndicator()),
                if (!_isLoadingTools && tools.isEmpty)
                  translatedtranslatedText('No tools available',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                if (!_isLoadingTools && tools.isNotEmpty)
                  Column(
                    children: tools.asMap().entries.map((entry) {
                      int index = entry.key;
                      String tool = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: selectedTools[index],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedTools[index] = value!;
                                      });
                                    },
                                    activeColor: Colors.teal[700],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child:translatedtranslatedText(
                                      tool,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              if (selectedTools[index])
                                Padding(
                                  padding: const EdgeInsets.only(left: 48.0, top: 8),
                                  child: TextField(
                                    controller: quantityControllers[index],
                                    decoration: InputDecoration(
                                      labelText: 'Quantity',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (widget.status.toLowerCase() == 'pending')
              Column(
                children: [
                  // Contact Information Section for Pending Bookings
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          translatedtranslatedText('YOUR CONTACT INFORMATION',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal[700],
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Your Phone Number',
                              hintText: 'Enter your contact number',
                              prefixIcon: Icon(Icons.phone, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _contactMethodController,
                            decoration: InputDecoration(
                              labelText: 'Preferred Contact Method',
                              hintText: 'e.g., WhatsApp, SMS, Call',
                              prefixIcon: Icon(Icons.contact_phone, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  if (_isWithinRange)
                    ElevatedButton(
                      onPressed: () => _updateBookingStatus('confirmed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: translatedtranslatedText('ACCEPT BOOKING',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (_isWithinRange) const SizedBox(height: 12),
                ],
              ),

            if (widget.status.toLowerCase() == 'confirmed')
              ElevatedButton(
                onPressed: () => _updateBookingStatus('completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: translatedtranslatedText('MARK AS COMPLETED',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child:translatedtranslatedText(
              text,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value,
      {VoidCallback? onTap}) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             translatedtranslatedText(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onTap,
                child:translatedtranslatedText(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: onTap != null ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}