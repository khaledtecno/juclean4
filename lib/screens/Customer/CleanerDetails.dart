import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../FastTranslationService.dart';

class DetailCleaner extends StatefulWidget {
  const DetailCleaner({super.key});

  @override
  State<DetailCleaner> createState() => _DetailCleanerState();
}

class _DetailCleanerState extends State<DetailCleaner> {bool isLoadingUser = true; // Loading state
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 16),
              _buildAppBar(context),
              SizedBox(height: 24),
              _buildProfileSection(),
              SizedBox(height: 24),
              _buildUserInfoSection(),
              SizedBox(height: 24),
              _buildDescriptionSection(),
              SizedBox(height: 24),
              _buildLocationSection(),
              SizedBox(height: 24),
              _buildReviewsSection(),
              SizedBox(height: 24),
              _buildDoneButton(context),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Center(
            child: translatedtranslatedText('Detail Cleaner',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF183A33)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                'https://media.istockphoto.com/id/1417833172/photo/professional-cleaner-holding-a-basket-of-cleaning-products.jpg?s=612x612&w=0&k=20&c=bqhz1jDqSxEQB1OAvm9DP_7SWNKR2F8t7Mzfr4Hchm4=', // Replace with actual image URL
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 16),
          translatedtranslatedText('Laura Franco',
            style: GoogleFonts.poppins(
              color: const Color(0xFF407981),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Column(
      children: [
        _buildInfoRow('User Name', 'jamesfranco'),
        SizedBox(height: 16),
        _buildInfoRow('Telephone', 'james@gmail.com'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            translatedtranslatedText(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFF303535),
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            translatedtranslatedText(
              value,
              style: GoogleFonts.poppins(
                color: const Color(0xFF6F8BA4),
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        Divider(color: const Color(0xFFECF5F3)),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        translatedtranslatedText('Description',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1F1F39),
            fontSize: 14,
            height: 1.1,
          ),
        ),
        SizedBox(height: 8),
        translatedtranslatedText('Experience +5 years',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6F8BA4),
            fontSize: 14,
            height: 1.7,
          ),
        ),
        Divider(color: const Color(0xFFECF5F3)),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        translatedtranslatedText('Location',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1F1F39),
            fontSize: 14,
            height: 1.1,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: const Color(0xFF6F8BA4)),
            SizedBox(width: 8),
            translatedtranslatedText('Room 123, Brooklyn St, Kepler District',
              style: GoogleFonts.poppins(
                color: const Color(0xFF6F8BA4),
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ],
        ),
        Divider(color: const Color(0xFFECF5F3)),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        translatedtranslatedText('Reviews',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1F1F39),
            fontSize: 14,
            height: 1.1,
          ),
        ),
        SizedBox(height: 16),
        _buildReviewCard(),
      ],
    );
  }

  Widget _buildReviewCard() {
    return Card(
     elevation: 2,     color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                translatedtranslatedText('Kristin Watson',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: 'Roboto',
                  ),
                ),
                Spacer(),
                translatedtranslatedText('🇲🇽 Mexico',
                  style: TextStyle(
                    color: const Color(0x60000000),
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            translatedtranslatedText('Verified Buyer',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.7,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 16),
            translatedtranslatedText('DELICIOUS',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.6,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 8),
            translatedtranslatedText('This is 💯 one hundred percent the best lip mask duo ever !!! The scent is delicious and it’s so smooth from the scrub & mask ~ This is perfection~ Smells just like honey 🍯 & the packaging is so adorable ~ I’m so very happy with this product 🐻 🍯 ~',
              style: TextStyle(
                color: const Color(0x99000000),
                fontSize: 12,
                height: 1.7,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 16),
            translatedtranslatedText('Nov 12, 2022',
              style: TextStyle(
                color: const Color(0x60000000),
                fontSize: 12,
                height: 1.7,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF407981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: translatedtranslatedText('DONE',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}