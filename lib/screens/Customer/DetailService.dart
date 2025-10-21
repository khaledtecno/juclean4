import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:juclean/screens/Customer/BookingScreen.dart';
import 'package:juclean/screens/Customer/CleanerDetails.dart';
import 'package:juclean/screens/Customer/CleanerSearchScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../FastTranslationService.dart';

class Detailservice extends StatefulWidget {
  final String name;
  final String description;
  final String price;
  final String imgurl;
  final String id;
  final String additional;
  final String rooms;

  const Detailservice({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    required this.imgurl,
    required this.id,
    required this.additional,
    required this.rooms,
  });

  @override
  State<Detailservice> createState() => _DetailserviceState();
}

class _DetailserviceState extends State<Detailservice> {  int _hours = 1;
double _totalPrice = 0;
final TextEditingController _hoursController = TextEditingController(text: '1');
bool isSaved = false;
bool isLoadingUser = true; // Loading state
bool _isMalay = false;
bool _isRefreshing = false;
bool _isBiometricEnabled = false;
bool _isBiometricAvailable = false;


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
void initState() {
  super.initState(); _getLanguagePreference();_initializeTranslations();
  // Parse the price string to double (remove 'EUR' if present)
  final priceValue = double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  _totalPrice = priceValue * _hours;
  _hoursController.addListener(_calculateTotal); _checkIfSaved();
}
Future<void> _checkIfSaved() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.email)
        .collection('saved_services')
        .doc(widget.id) // assuming you pass serviceId to the widget
        .get();
    setState(() {
      isSaved = doc.exists;
    });
  }
}
@override
void dispose() {
  _hoursController.dispose();
  super.dispose();
}

void _calculateTotal() {
  final hours = int.tryParse(_hoursController.text) ?? 1;
  final priceValue = double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  setState(() {
    _hours = hours.clamp(1, 24); // Limit hours between 1 and 24
    _totalPrice = priceValue * _hours;
  });
}
Future<void> _toggleSave() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // Optionally show login dialog or navigate to login screen
    return;
  }

  final savedRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.email)
      .collection('saved_services')
      .doc(widget.id);

  if (isSaved) {
    // Remove from saved
    await savedRef.delete();

  } else {
    // Add to saved
    await savedRef.set({
      'serviceId': widget.id,
      'name': widget.name,
      'price': widget.price,
      'imgurl': widget.imgurl,
      'additional': widget.additional,
      'description': widget.description,
      'rooms': widget.rooms,
      'savedAt': FieldValue.serverTimestamp(),
    });

  }

  setState(() {
    isSaved = !isSaved;
  });
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'service-${widget.id}',
              child: Image.network(
                widget.imgurl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: isSaved ? Colors.amber : Colors.white,
                  ),
                  onPressed: _toggleSave,
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Title and Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          translatedtranslatedText(
                            widget.name,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          translatedtranslatedText('by JUClean Company',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: translatedtranslatedText(
                        widget.price,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Service Details
                translatedtranslatedText('Service Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                translatedtranslatedText(
                  widget.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 24),

                // Service Features
                translatedtranslatedText('What\\\'s Included',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureItem('Room Count', widget.rooms),
                _buildFeatureItem('Additional Services', widget.additional),
                _buildFeatureItem('Professional Equipment', 'Included'),
                _buildFeatureItem('Eco-Friendly Products', 'Available'),



/*
                // Total Price
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      translatedtranslatedText('Total Price',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      translatedtranslatedText(' ',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ],
                  ),
                ),*/

                const SizedBox(height: 32),

                // Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            serviceId: widget.id,
                            serviceName: widget.name,
                            servicePrice: _totalPrice,
                            serviceImg: widget.imgurl,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: Colors.teal.shade200,
                    ),
                    child: translatedtranslatedText('Book Now',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildFeatureItem(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          color: Colors.teal.shade600,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              translatedtranslatedText(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              translatedtranslatedText(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildDurationSelector() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove, color: Colors.teal.shade700),
          onPressed: () {
            if (_hours > 1) {
              setState(() {
                _hours--;
                _calculateTotal();
              });
            }
          },
        ),
        Expanded(
          child: Center(
            child: translatedtranslatedText('$_hours hour${_hours > 1 }',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: Colors.teal.shade700),
          onPressed: () {
            if (_hours < 24) {
              setState(() {
                _hours++;
                _calculateTotal();
              });
            }
          },
        ),
      ],
    ),
  );
}
}


