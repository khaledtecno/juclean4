import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart' as loca;
import 'package:mailer/mailer.dart' as mail;
import 'package:mailer/smtp_server.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:table_calendar/table_calendar.dart';

import '../FastTranslationService.dart';

class BookingScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final double servicePrice;
  final String serviceImg;

  const BookingScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceImg,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User user;
  final TextEditingController _searchPlaceController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _notes = '';
  bool _isLoading = false;
  LatLng? _currentLocation;
  String? _locationAddress;
  var link;
  Map<String, dynamic>? _selectedPlaceDetails;
  bool isLoadingUser = true;
  bool _isMalay = false;
  bool _isRefreshing = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  final searchController = TextEditingController();
  final String token = '1234567890';
  var uuid = const Uuid();
  List<dynamic> listOfLocation = [];
  final _sessionToken = Uuid().v4();
  Timer? _debounceTimer;

  // Calendar variables
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime? _selectedDay;
  Set<DateTime> _bookedDates = {};
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _placesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser!;
    _getCurrentLocation();
    _getLanguagePreference();
    _initializeTranslations();
    _addressController.addListener(_onChange);

    // Initialize calendar
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = null;
    _loadBookedDates();
  }

  Future<void> _loadBookedDates() async {
    setState(() => _isLoading = true);

    try {
      final bookings = await _firestore
          .collection('bookings')
          .where('serviceId', isEqualTo: widget.serviceId)
          .get();

      final bookedDates = bookings.docs.map((doc) {
        final bookingData = doc.data();
        final bookingDateTime = (bookingData['bookingDateTime'] as Timestamp).toDate();
        return DateTime(bookingDateTime.year, bookingDateTime.month, bookingDateTime.day);
      }).toSet();

      setState(() {
        _bookedDates = bookedDates;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading booked dates: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!_bookedDates.contains(DateTime(selectedDay.year, selectedDay.month, selectedDay.day))) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedDate = selectedDay;
                });
              }
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              disabledDecoration: BoxDecoration(
                color: Colors.red.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            enabledDayPredicate: (day) {
              final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
              final isBooked = _bookedDates.contains(DateTime(day.year, day.month, day.day));
              return !isPast && !isBooked;
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              formatButtonTextStyle: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDate != null)
            Text(
              'Selected: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kIsWeb) {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw 'Location permissions denied';
        }

        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          link = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
          _isLoading = false;
        });

        await _updateLocationAddress(_currentLocation!);
        return;
      }

      // Mobile implementation
      final location = loca.Location();
      bool serviceEnabled;
      loca.PermissionStatus permissionGranted;

      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == loca.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loca.PermissionStatus.granted) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final locationData = await location.getLocation();
      setState(() {
        _currentLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        link = 'https://www.google.com/maps?q=${locationData.latitude},${locationData.longitude}';
        _isLoading = false;
      });

      await _updateLocationAddress(_currentLocation!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location obtained successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateLocationAddress(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _locationAddress = '${place.street}, ${place.postalCode} ${place.locality}, ${place.country}';
          _addressController.text = _locationAddress!;
        });
      }
    } catch (e) {
      setState(() {
        _locationAddress = '${location.latitude}, ${location.longitude}';
        _addressController.text = _locationAddress!;
      });
    }
  }

  Future<void> _toggleLanguage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('malys', value);
    setState(() {
      _isMalay = value;
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _getLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMalay = prefs.getBool('malys') ?? false;
    });
  }

  Future<void> _initializeTranslations() async {
    final prefs = await SharedPreferences.getInstance();
    final isMalay = prefs.getBool('malys') ?? false;
    await FastTranslationService.init(isMalay);
  }

  void _onChange() {
    placeSuggestion(_addressController.text);
  }

  void placeSuggestion(String input) async {
    if (input.isEmpty || input.length < 3) {
      setState(() => listOfLocation = []);
      return;
    }

    try {
      const apiKey = "AIzaSyAL9E3CEvdhlTAwN2oE2ROH1G6UgmPZ4Mk";
      const baseUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json";

      final uri = Uri.parse('$baseUrl?input=$input&key=$apiKey'
          '&components=country:de'
          '&language=en'
          '&types=address'
          '&sessiontoken=$_sessionToken');

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            listOfLocation = (data['predictions'] as List).map((prediction) {
              return {
                'description': prediction['description'],
                'place_id': prediction['place_id'],
                'main_text': prediction['structured_formatting']['main_text'],
                'secondary_text': prediction['structured_formatting']['secondary_text'],
              };
            }).toList();
          });
        } else {
          debugPrint("API Error: ${data['status']}");
          setState(() => listOfLocation = []);
        }
      } else {
        throw Exception("HTTP Error ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching places: $e");
      setState(() => listOfLocation = []);
    }
  }

  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    const apiKey = "AIzaSyAL9E3CEvdhlTAwN2oE2ROH1G6UgmPZ4Mk";
    const baseUrl = "https://maps.googleapis.com/maps/api/place/details/json";

    try {
      final uri = Uri.parse('$baseUrl?place_id=$placeId&key=$apiKey'
          '&fields=formatted_address,geometry'
          '&sessiontoken=$_sessionToken');

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          return {
            'address': result['formatted_address'],
            'latitude': result['geometry']['location']['lat'],
            'longitude': result['geometry']['location']['lng'],
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint("Place details error: $e");
      return null;
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedTime == null || _currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date, time, and location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      final bookingDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _firestore.collection('bookings').doc(orderId).set({
        'orderId': orderId,
        'userId': user.uid,
        'userEmail': user.email,
        'serviceId': widget.serviceId,
        'serviceName': widget.serviceName,
        'servicePrice': widget.servicePrice.toString(),
        'bookingDateTime': bookingDateTime,
        'img': widget.serviceImg,
        'notes': _notes,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'selectedCoordinates': GeoPoint(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        ),
        'mapLink': link.toString(),
        'selectedLocationAddress': _locationAddress,
      });

      // Send notifications
      sendTestNotification(user.email ?? 'id', widget.serviceName);
      sendTestNotification1(user.email ?? 'id', widget.serviceName);
      sendNotificationToAdmin(user.email ?? 'id', widget.serviceName);

      // Add to notifications collection
      final notificationId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('notifications').doc(notificationId).set({
        'id': notificationId,
        'userId': user.uid,
        'title': 'Booking Confirmation',
        'message': 'Your booking for ${widget.serviceName} has been received',
        'type': 'booking',
        'relatedId': orderId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': widget.serviceImg,
      });

      // Send confirmation email
      final gmailSmtp = SmtpServer(
        'smtp.gmail.com',
        username: 'juclean988@gmail.com',
        password: 'fknp eufo jpjf wplh',
        port: 465,
        ssl: true,
      );

      final message = mail.Message()
        ..from = mail.Address(dotenv.env["GMAIL_MAIL"]!, 'JUCLEAN')
        ..recipients.add(user.email!)
        ..subject = 'Booking Confirmation - You\'re on the Waiting List'
        ..html = '''
      <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Confirmation</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
            background-color: #f5f7fa;
            margin: 0;
            padding: 0;
            color: #333;
        }
        
        .container {
            max-width: 600px;
            margin: 30px auto;
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
        }
        
        .header {
            background: linear-gradient(135deg, #6e8efb, #a777e3);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 600;
        }
        
        .confirmation-icon {
            font-size: 60px;
            margin-bottom: 15px;
        }
        
        .content {
            padding: 30px;
        }
        
        .details-card {
            background: #f9fafc;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 25px;
            border-left: 4px solid #6e8efb;
        }
        
        .detail-row {
            display: flex;
            margin-bottom: 15px;
            align-items: center;
        }
        
        .detail-label {
            font-weight: 500;
            color: #666;
            width: 100px;
            flex-shrink: 0;
        }
        
        .detail-value {
            font-weight: 600;
            color: #333;
        }
        
        .status-badge {
            display: inline-block;
            background: #e1f5e8;
            color: #28a745;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: 500;
            margin-left: 10px;
        }
        
        .footer {
            text-align: center;
            padding: 20px;
            background: #f5f7fa;
            color: #666;
            font-size: 14px;
        }
        
        .divider {
            height: 1px;
            background: #eee;
            margin: 25px 0;
        }
        
        .action-btn {
            display: inline-block;
            background: #6e8efb;
            color: white;
            text-decoration: none;
            padding: 12px 25px;
            border-radius: 6px;
            font-weight: 500;
            margin-top: 10px;
            transition: all 0.3s ease;
        }
        
        .action-btn:hover {
            background: #5a7df4;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(106, 142, 251, 0.3);
        }
        
        .qr-code {
            text-align: center;
            margin: 20px 0;
        }
        
        .qr-code img {
            width: 150px;
            height: 150px;
            border: 1px solid #eee;
            padding: 10px;
            background: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="confirmation-icon">✓</div>
            <h1>Your Booking is Confirmed!</h1>
        </div>
        
        <div class="content">
            <p style="text-align: center; margin-bottom: 25px;">Thank you for your booking. Here are your appointment details:</p>
            
            <div class="details-card">
                <div class="detail-row">
                    <span class="detail-label">Service:</span>
                    <span class="detail-value">${widget.serviceName} <span class="status-badge">Confirmed</span></span>
                </div>
                
                <div class="detail-row">
                    <span class="detail-label">Date:</span>
                    <span class="detail-value">${DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate!)}</span>
                </div>
                
                <div class="detail-row">
                    <span class="detail-label">Time:</span>
                    <span class="detail-value">${_selectedTime!.format(context)} (Duration: 60 mins)</span>
                </div>
                
                <div class="detail-row">
                    <span class="detail-label">Location:</span>
                    <span class="detail-value">$_locationAddress</span>
                </div>
                
                <div class="detail-row">
                    <span class="detail-label">Booking ID:</span>
                    <span class="detail-value">#${Random().nextInt(900000) + 100000}</span>
                </div>
            </div>
            
            <div class="qr-code">
                <!-- QR code would be generated here in a real implementation -->
                <div style="width: 150px; height: 150px; margin: 0 auto; background: #eee; display: flex; align-items: center; justify-content: center;">
                    [QR Code]
                </div>
                <p style="font-size: 13px; color: #666;">Scan this code at check-in</p>
            </div>
            
            <div class="divider"></div>
            
            <h3 style="margin-bottom: 15px;">Next Steps</h3>
            <ul style="padding-left: 20px; color: #555; line-height: 1.6;">
                <li>You'll receive a reminder 24 hours before your appointment</li>
                <li>Please arrive 10 minutes early to complete any necessary paperwork</li>
                <li>Bring any required documents or materials</li>
            </ul>
            
            <div style="text-align: center; margin-top: 30px;">
                <a href="#" class="action-btn">Add to Calendar</a>
                <a href="#" class="action-btn" style="background: #f1f3f6; color: #555; margin-left: 10px;">Contact Support</a>
            </div>
        </div>
        
        <div class="footer">
            <p>If you have any questions, please contact us at support@example.com</p>
            <p>© 2023 Your Company Name. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
        ''';

      try {
        await mail.send(message, gmailSmtp);
        debugPrint('Email sent successfully');
      } catch (e) {
        debugPrint('Failed to send email: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> sendTestNotification(String useremail, String serviceName) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendTestNotification');
      await callable({
        'title': 'New Booking $serviceName',
        'message': 'You have new booking request service: $serviceName orderid: $useremail',
      });
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  Future<void> sendTestNotification1(String useremail, String serviceName) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendTestNotification1');
      await callable({
        'title': 'New Booking $serviceName',
        'message': 'You have new booking request, Service: $serviceName, User_email: $useremail',
      });
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  Future<void> sendNotificationToAdmin(String orderId, String serviceName) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('sendAdminNotification');
      await callable.call(<String, dynamic>{
        'orderId': orderId,
        'serviceName': serviceName,
      });
    } catch (e) {
      debugPrint('Error sending admin notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Book ${widget.serviceName}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Switch(
            value: _isMalay,
            onChanged: _toggleLanguage,
            activeColor: Colors.white,
            activeTrackColor: Colors.teal[300],
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[400],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isRefreshing
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.serviceImg,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.serviceName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),

                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Date Selection
            _buildDateSelector(),

            const SizedBox(height: 24),

            // Time Selection
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.teal, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Time',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _selectTime(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select Time',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Location Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.teal, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Service Location',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: 'Enter address in Germany...',
                      prefixIcon: const Icon(Icons.search, color: Colors.teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.teal, width: 2),
                      ),
                    ),
                    onChanged: (value) => _onSearchChangedWEB(value),
                  ),
                  if (listOfLocation.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: listOfLocation.length,
                        itemBuilder: (context, index) {
                          final location = listOfLocation[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.teal),
                            title: Text(location['main_text']),
                            subtitle: Text(location['secondary_text'] ?? ''),
                            onTap: () async {
                              final details = await _getPlaceDetails(location['place_id']);
                              if (details != null) {
                                setState(() {
                                  _addressController.text = details['address'];
                                  _currentLocation = LatLng(
                                    details['latitude'],
                                    details['longitude'],
                                  );
                                  link = 'https://www.google.com/maps?q=${details['latitude']},${details['longitude']}';
                                  _selectedPlaceDetails = {
                                    'address': details['address'],
                                    'latitude': details['latitude'],
                                    'longitude': details['longitude'],
                                  };
                                  listOfLocation = [];
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                  if (_selectedPlaceDetails != null || _locationAddress != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.teal, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Selected Location',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedPlaceDetails?['address'] ?? _locationAddress ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                         /* if (_currentLocation != null)
                            InkWell(
                              onTap: () => launchUrl(Uri.parse(link)),
                              child: Text(
                                'View on Map',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.teal,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),*/
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getCurrentLocation,
                      icon: _isLoading
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.my_location, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Getting location...' : 'Use Current Location',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notes Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.note_add, color: Colors.teal, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Additional Notes',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    maxLines: 4,
                    onChanged: (value) => _notes = value,
                    decoration: InputDecoration(
                      hintText: 'Any special instructions or requirements...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.teal, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  'Submit Booking Request',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your booking request will be reviewed and confirmed within 24 hours. You will receive a confirmation email shortly.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChangedWEB(String query) async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() => listOfLocation = []);
        return;
      }

      try {
        const apiKey = "AIzaSyAL9E3CEvdhlTAwN2oE2ROH1G6UgmPZ4Mk";
        const baseUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json";

        final uri = Uri.parse('$baseUrl?input=$query&key=$apiKey'
            '&components=country:de'
            '&language=en'
            '&types=address'
            '&sessiontoken=$_sessionToken');

        final response = await http.get(uri).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            setState(() {
              listOfLocation = (data['predictions'] as List).map((prediction) {
                return {
                  'description': prediction['description'],
                  'place_id': prediction['place_id'],
                  'main_text': prediction['structured_formatting']['main_text'],
                  'secondary_text': prediction['structured_formatting']['secondary_text'],
                };
              }).toList();
            });
          } else {
            debugPrint("API Error: ${data['status']}");
            setState(() => listOfLocation = []);
          }
        } else {
          throw Exception("HTTP Error ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("Error in _onSearchChangedWEB: $e");
        setState(() => listOfLocation = []);
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _placesController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}