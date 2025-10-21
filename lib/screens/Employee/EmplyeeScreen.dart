import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:juclean/screens/Employee/EmployeeHome.dart';
import 'package:juclean/screens/Employee/MyOrders.dart';
import 'package:juclean/screens/Employee/ProfileE.dart';
import 'package:juclean/screens/Employee/pdf_preview_screen.dart';
import '';
import '../FastTranslationService.dart';
class EmplyeeScreen extends StatefulWidget {
  const EmplyeeScreen({super.key});

  @override
  State<EmplyeeScreen> createState() => _EmplyeeScreenState();
}

class _EmplyeeScreenState extends State<EmplyeeScreen> {
  int _selectedItemPosition = 0;

  final List<Widget> _screens = [
    const EmployeeHome(),
     SearchWorkScreen(), // You'll need to create this
     ProfileE(),    // You'll need to create this
  ];
  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.exit_to_app, size: 50, color: Colors.blueAccent),
              const SizedBox(height: 20),
              translatedtranslatedText('Exit App',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 10),
              translatedtranslatedText('Are you sure you want to exit?',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: translatedtranslatedText('Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      child: translatedtranslatedText('Exit',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child:Scaffold(
      body: _screens[_selectedItemPosition],
      bottomNavigationBar: SnakeNavigationBar.color(
        behaviour: SnakeBarBehaviour.floating,
        snakeShape: SnakeShape.rectangle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(12),
        snakeViewColor: Colors.blueAccent,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.blueGrey,
        elevation: 5,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        currentIndex: _selectedItemPosition,
        onTap: (index) => setState(() => _selectedItemPosition = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(IconlyBroken.home),
              label: 'Home'
          ),
          BottomNavigationBarItem(
              icon: Icon(IconlyBroken.activity),
              label: 'Orders'
          ),
          BottomNavigationBarItem(
              icon: Icon(IconlyBroken.profile),
              label: 'Profile'
          ),
        ],
      ),
    /*  floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>  PdfPreviewScreen()),
        );
      },
      icon:  Icon(Icons.picture_as_pdf),
      label:  translatedtranslatedText('Generate Invoice'),
    ),*/
    ));
  }
}
