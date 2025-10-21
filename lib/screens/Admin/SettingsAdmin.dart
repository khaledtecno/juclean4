import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../FastTranslationService.dart';



class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System Default';
  String _selectedPayment = 'PayPal';

  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  final List<String> _themes = ['System Default', 'Light', 'Dark'];
  final List<String> _paymentMethods = ['PayPal', 'Credit Card', 'Bank Transfer', 'Crypto'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: translatedtranslatedText('Admin Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
              'https://randomuser.me/api/portraits/men/32.jpg',
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            'https://randomuser.me/api/portraits/men/32.jpg',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            translatedtranslatedText('Admin User',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            translatedtranslatedText('Administrator',
                              style: GoogleFonts.inter(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    translatedtranslatedText('Profile Information',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Full Name', 'Admin User'),
                    const SizedBox(height: 12),
                    _buildTextField('Email', 'admin@example.com'),
                    const SizedBox(height: 12),
                    _buildTextField('Phone Number', '+49 174 4012556'),
                    const SizedBox(height: 12),
                    _buildTextField('Bio', 'I manage the admin panel and system configurations'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: translatedtranslatedText('Update Profile',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Account Settings
            translatedtranslatedText('Account Settings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      value: _selectedLanguage,
                      onTap: () => _showLanguagePicker(),
                    ),
                    const Divider(height: 24),
                    _buildSettingsRow(
                      icon: Icons.palette_outlined,
                      title: 'App Theme',
                      value: _selectedTheme,
                      onTap: () => _showThemePicker(),
                    ),
                    const Divider(height: 24),
                    _buildToggleRow(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() {
                          _notificationsEnabled = val;
                        });
                      },
                    ),
                    const Divider(height: 24),
                    _buildToggleRow(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      value: _darkModeEnabled,
                      onChanged: (val) {
                        setState(() {
                          _darkModeEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Payment & Security
            translatedtranslatedText('Payment & Security',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: Icons.payment_outlined,
                      title: 'Payment Method',
                      value: _selectedPayment,
                      onTap: () => _showPaymentPicker(),
                    ),
                    const Divider(height: 24),
                    _buildSettingsRow(
                      icon: Icons.security_outlined,
                      title: 'Change Password',
                      value: 'Last changed 2 weeks ago',
                      onTap: () {},
                    ),
                    const Divider(height: 24),
                    _buildSettingsRow(
                      icon: Icons.two_wheeler_outlined,
                      title: 'Two-Factor Authentication',
                      value: 'Enabled',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Social Links
            translatedtranslatedText('Social Links',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSocialLinkField('Twitter', 'twitter.com/admin'),
                    const SizedBox(height: 12),
                    _buildSocialLinkField('LinkedIn', 'linkedin.com/in/admin'),
                    const SizedBox(height: 12),
                    _buildSocialLinkField('GitHub', 'github.com/admin'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.indigo.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, size: 18),
                          const SizedBox(width: 8),
                          translatedtranslatedText('Add Social Link',
                            style: GoogleFonts.inter(
                              color: Colors.indigo,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Danger Zone
            translatedtranslatedText('Danger Zone',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDangerButton(
                      'Delete Account',
                      'Permanently delete your account',
                      Icons.delete_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildDangerButton(
                      'Deactivate Account',
                      'Temporarily deactivate your account',
                      Icons.pause_circle_outline,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      controller: TextEditingController(text: value),
      style: GoogleFonts.inter(fontSize: 15),
    );
  }

  Widget _buildSocialLinkField(String platform, String value) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: translatedtranslatedText('$platform:',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
      controller: TextEditingController(text: value),
      style: GoogleFonts.inter(fontSize: 15),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.indigo),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  translatedtranslatedText(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  translatedtranslatedText(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 24, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.indigo),
        const SizedBox(width: 16),
        Expanded(
          child: translatedtranslatedText(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildDangerButton(String title, String subtitle, IconData icon) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                translatedtranslatedText(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                translatedtranslatedText(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              translatedtranslatedText('Select Language',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ..._languages.map((language) => ListTile(
                title: translatedtranslatedText(language),
                trailing: _selectedLanguage == language
                    ? const Icon(Icons.check, color: Colors.indigo)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = language;
                  });
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              translatedtranslatedText('Select Theme',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ..._themes.map((theme) => ListTile(
                title: translatedtranslatedText(theme),
                trailing: _selectedTheme == theme
                    ? const Icon(Icons.check, color: Colors.indigo)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedTheme = theme;
                  });
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              translatedtranslatedText('Select Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ..._paymentMethods.map((method) => ListTile(
                title: translatedtranslatedText(method),
                trailing: _selectedPayment == method
                    ? const Icon(Icons.check, color: Colors.indigo)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedPayment = method;
                  });
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}