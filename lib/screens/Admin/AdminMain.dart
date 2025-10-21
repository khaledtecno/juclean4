import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/animation.dart';
import 'package:juclean/screens/Admin/AdminRequestMaterial.dart';

import 'package:juclean/screens/Admin/services/image_upload_service.dart';
import 'package:juclean/screens/Admin/services/service_repository.dart';
import 'package:juclean/screens/Admin/services/services_list_page.dart';
import 'package:juclean/screens/Admin/tool_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../FastTranslationService.dart';
import 'AddMaterial.dart';
import 'AnalyticsScreen.dart';
import 'EmailsPage.dart';
import 'EmployeesScreen.dart';
import 'NoticationPage.dart';
import 'OrdersScreen.dart';
import 'SettingsAdmin.dart';
import 'UsersScreen.dart';

// Constants for drawer
const double kDesktopDrawerWidth = 280;
const double kMobileDrawerWidth = 260;
const double kDrawerHeaderHeight = 180;
const Duration kDrawerAnimationDuration = Duration(milliseconds: 300);

class NeoAdminDashboard extends StatefulWidget {
  const NeoAdminDashboard({super.key});

  @override
  State<NeoAdminDashboard> createState() => _NeoAdminDashboardState();
}

class _NeoAdminDashboardState extends State<NeoAdminDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  bool _isFabOpen = false;
  int _selectedIndex = 0;
  bool _isHovering = false;

  // Screens for navigation
  final List<Widget> _screens = [
     DashboardScreen(),
    const UsersScreen(),
    const EmployeesScreen(),
    const OrdersScreen(),
    const AnalyticsScreen(),
    const MaterialsScreen(),

    const EmailsPage(),
    const ToolHistoryScreen(),
    ServicesListPage(
      serviceRepository: ServiceRepository(),
      imageUploadService: ImageUploadService(),
    ),
    const AdminRequestsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );  _initializeTranslations();  _getLanguagePreference();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }  bool _obscureText = true;
  bool _isLoading = false;
  bool _isMalay = false;bool isLoadingUser = true; // Loading state

  bool _isRefreshing = false;

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

  Future<void> _showLogoutDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: ModalRoute.of(context)!.animation!,
            curve: Curves.fastOutSlowIn,
          ),
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
                const Icon(Icons.logout, size: 50, color: Colors.blueAccent),
                const SizedBox(height: 20),
                translatedtranslatedText('Logout Confirmation',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 10),
                translatedtranslatedText('Are you sure you want to logout?',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
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
                        onPressed: () => logout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                        ),
                        child: translatedtranslatedText('Logout',
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
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    Navigator.pop(context); // Close dialog
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => const GetStarted(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Logout error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(isMobile),
      drawer: isMobile ? _buildDrawer() : null,
      body: Row(
        children: [
          if (!isMobile) _buildDesktopDrawer(),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      floatingActionButton: _buildSmartFab(isMobile),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      title: translatedtranslatedText(
        _getAppBarTitle(),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      centerTitle: false,
      actions: [
        if (!isMobile)
          Container(
            width: 240,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        IconButton(
          icon: Icon(
            isMobile ? Icons.search : Icons.notifications_none,
            color: const Color(0xFF1E293B),
          ),
          onPressed: () {},
        ),
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: translatedtranslatedText('AD', style: TextStyle(color: Colors.blue.shade800)),
            ),
          ),
      ],
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'User Management';
      case 2:
        return 'Employee Management';
      case 3:
        return 'Order Management';
      case 4:
        return 'Analytics';
      case 5:
        return 'Add materials';
      case 6:
        return 'Emails';
      case 7:
        return 'Analytics Materials';
      case 8:
        return 'Add Service';
      case 9:
        return 'Material Requests';

      default:
        return 'Dashboard';
    }
  }

  Widget _buildDesktopDrawer() {
    return AnimatedContainer(
      width: kDesktopDrawerWidth,
      duration: kDrawerAnimationDuration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: _buildDrawerContent(),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: kMobileDrawerWidth,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: _buildDrawerContent(),
    );
  }

  Widget _buildDrawerContent() {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          // Drawer Header with animation
SizedBox(height: 70,),

          // Drawer Items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
                  _buildDrawerItem(Icons.people_alt, 'Users', 1),
                  _buildDrawerItem(Icons.badge, 'Employees', 2),
                  _buildDrawerItem(Icons.shopping_bag, 'Orders', 3),
                  _buildDrawerItem(Icons.analytics, 'Analytics', 4),
                  _buildDrawerItem(Icons.add_circle_sharp, 'Add materials', 5),
                  _buildDrawerItem(Icons.email_outlined, 'Send Emails', 6),
                  _buildDrawerItem(Icons.analytics_outlined, 'Analytics Material', 7),
                  _buildDrawerItem(Icons.cleaning_services, 'Services', 8),
                  _buildDrawerItem(Icons.add_alarm, 'Material Requests', 9),
                  const Divider(
                    height: 32,
                    color: Color(0xFFF1F5F9),
                    indent: 16,
                    endIndent: 16,
                  ),

                ],
              ),
            ),
          ),

          // Logout button at bottom
          _buildLogoutButton(),
        ],
      ),
    );
  }



  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedContainer(
        duration: kDrawerAnimationDuration,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.withOpacity(0.1),
        ),
        child: ListTile(
          leading: Icon(
            Icons.logout,
            color: Colors.red.shade600,
          ),
          title: translatedtranslatedText('Logout',
            style: GoogleFonts.poppins(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () => _showLogoutDialog(context),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AnimatedContainer(
        duration: kDrawerAnimationDuration,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _selectedIndex == index
              ? Colors.blue.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: _selectedIndex == index
                ? Colors.blue
                : const Color(0xFF64748B),
          ),
          title: translatedtranslatedText(
            title,
            style: GoogleFonts.poppins(
              color: _selectedIndex == index
                  ? Colors.blue
                  : const Color(0xFF1E293B),
              fontWeight: _selectedIndex == index
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          trailing: _selectedIndex == index
              ? Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
          )
              : null,
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            if (MediaQuery.of(context).size.width < 600) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSmartFab(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isFabOpen)
          ScaleTransition(
            scale: _fabAnimation,
            child: FadeTransition(
              opacity: _fabAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FloatingActionButton.extended(
                  heroTag: 'users',
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                      _isFabOpen = false;
                      _fabController.reverse();
                    });
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.people, color: Colors.blue),
                  label: translatedtranslatedText('Manage Users',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        if (_isFabOpen)
          ScaleTransition(
            scale: _fabAnimation,
            child: FadeTransition(
              opacity: _fabAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FloatingActionButton.extended(
                  heroTag: 'orders',
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 3;
                      _isFabOpen = false;
                      _fabController.reverse();
                    });
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.shopping_bag, color: Colors.green),
                  label: translatedtranslatedText('Process Orders',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        if (_isFabOpen)
          ScaleTransition(
            scale: _fabAnimation,
            child: FadeTransition(
              opacity: _fabAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FloatingActionButton.extended(
                  heroTag: 'Logout',
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.logout, color: Colors.blueAccent),
                  label: translatedtranslatedText('Logout Account',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        FloatingActionButton(
          heroTag: 'main',
          onPressed: _toggleFab,
          backgroundColor: Colors.blue,
          elevation: _isFabOpen ? 0 : 4,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _fabAnimation,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatelessWidget {
   DashboardScreen({super.key});
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isTablet = MediaQuery.of(context).size.width < 1000;
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
    return WillPopScope(
        onWillPop: _onWillPop,
        child:SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // In your app bar or bottom navigation

            _buildWelcomeHeader(isMobile),
            const SizedBox(height: 24),
            _buildStatsGrid(isMobile, isTablet, context),
            const SizedBox(height: 24),
            _buildQuickActions(isMobile, isTablet, context),
            const SizedBox(height: 24),
            const SizedBox(height: 32),
          ],
        ),
      )),
    );
  }

  Widget _buildWelcomeHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            translatedtranslatedText('Welcome back,',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 14 : 16,
                color: const Color(0xFF64748B),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('notifications')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data?.docs.length ?? 0;
                return Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  child: IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications,
                        size: 26,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsPage(),
                        fullscreenDialog: true,  // Adds a nice transition
                      ),
                    ),
                    splashRadius: 20,  // Better splash effect
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        translatedtranslatedText('Neo Admin Dashboard',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        translatedtranslatedText('Everything you need to manage your platform.',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 14 : 16,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isMobile, bool isTablet, context) {
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
    final childAspectRatio = isMobile ? 1.8 : (isTablet ? 1.5 : 0.8);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        if (!usersSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Calculate user counts
        final totalUsers = usersSnapshot.data!.docs.length;
        final totalEmployees = usersSnapshot.data!.docs.where((user) {
          final data = user.data() as Map<String, dynamic>;
          return data['type'] == 'Employee';
        }).length;
        final totalRegularUsers = usersSnapshot.data!.docs.where((user) {
          final data = user.data() as Map<String, dynamic>;
          return data['type'] == 'User';
        }).length;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
          builder: (context, bookingsSnapshot) {
            if (!bookingsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final totalBookings = bookingsSnapshot.data!.docs.length;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const UsersScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: _buildStatCard('Total Users', totalRegularUsers.toString(), Icons.people, const Color(0xFF3B82F6)),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const EmployeesScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: _buildStatCard('Employees', totalEmployees.toString(), Icons.badge, const Color(0xFFF59E0B)),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const OrdersScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: _buildStatCard('Bookings', totalBookings.toString(), Icons.shopping_bag, const Color(0xFF10B981)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 15),
              translatedtranslatedText(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              translatedtranslatedText(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  translatedtranslatedText('View all',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isMobile, bool isTablet, context) {
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        translatedtranslatedText('Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const UsersScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: _buildActionButton('Add User', Icons.person_add, Colors.blue),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const MaterialsScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: _buildActionButton('New Material', Icons.shopping_cart, Colors.green),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const EmployeesScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: _buildActionButton('Add Employee', Icons.person_add_alt, Colors.orange),
            ),
            if (!isMobile)
              _buildActionButton('Generate Report', Icons.analytics, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color) {
    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              translatedtranslatedText(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              translatedtranslatedText('Tap to create',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}