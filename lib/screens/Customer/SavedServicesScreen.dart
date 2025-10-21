import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../FastTranslationService.dart';
import 'DetailService.dart';

class SavedServicesScreen extends StatefulWidget {
  const SavedServicesScreen({Key? key}) : super(key: key);

  @override
  _SavedServicesScreenState createState() => _SavedServicesScreenState();
}

class _SavedServicesScreenState extends State<SavedServicesScreen> {bool isLoadingUser = true; // Loading state
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: translatedtranslatedText('Saved Services',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _buildSavedServicesList(),
      ),
    );
  }

  Widget _buildSavedServicesList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            translatedtranslatedText('Please sign in to view saved services',
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {

                // Navigate to login screen
              },
              child: translatedtranslatedText('Sign In'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('saved_services')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: translatedtranslatedText('Error loading saved services'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data?.docs.isEmpty ?? true) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                translatedtranslatedText('No saved services yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8),
                translatedtranslatedText('Tap the bookmark icon to save services',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          physics: BouncingScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final service = snapshot.data!.docs[index];
            return _buildSavedServiceCard(service);
          },
        );
      },
    );
  }

  Widget _buildSavedServiceCard(DocumentSnapshot service) {
    final data = service.data() as Map<String, dynamic>;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  Detailservice(
                    name: data['name'],
                    description: data['description'],
                    price: data['price'],
                    imgurl: data['imgurl'], additional:  data['rooms'], rooms:  data['additional'],
                    id: data['serviceId'],
                  ),
            ),
          );
          // Navigate to service details
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Service Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    data['imgurl'] ?? '',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.cleaning_services, size: 30, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(width: 16),

              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    translatedtranslatedText(
                      data['name'] ?? 'Service',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    translatedtranslatedText(
                      data['additional'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                   /* Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        translatedtranslatedText(
                          '4.8', // You can fetch rating from your database
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.access_time, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        translatedtranslatedText(
                          '30 min', // You can add duration to your service data
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),*/
                  ],
                ),
              ),

              // Price and Remove Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  translatedtranslatedText('\\${data['price'] ?? '0'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF407981),
                    ),
                  ),
                  SizedBox(height: 8),
                  IconButton(
                    icon: Icon(Icons.bookmark, color: Colors.blue),
                    onPressed: () => _removeSavedService(service.id),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    iconSize: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeSavedService(String serviceId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('saved_services')
          .doc(serviceId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:translatedtranslatedText('Service removed from saved'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: translatedtranslatedText('Failed to remove service'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}