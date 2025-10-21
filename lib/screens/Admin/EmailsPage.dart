import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../FastTranslationService.dart';

class EmailsPage extends StatefulWidget {
  const EmailsPage({Key? key}) : super(key: key);

  @override
  _EmailsPageState createState() => _EmailsPageState();
}

class _EmailsPageState extends State<EmailsPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isSending = false;
  String? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:  translatedtranslatedText('Email Management',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              indicatorColor: Theme.of(context).primaryColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Send Email'),
              //  Tab(text: 'Templates'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendEmailForm(),

          _buildEmailHistory(),
        ],
      ),
    );
  }

  Widget _buildSendEmailForm() {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(_isSending ? 0 : 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isSending ? 0 : null,
              child: Column(
                children: [
                  _buildInputField(
                    controller: _emailController,
                    label: 'Recipient Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _subjectController,
                    label: 'Subject',
                    icon: Icons.subject_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _bodyController,
                    label: 'Email Body (HTML)',
                    icon: Icons.text_fields_outlined,
                    maxLines: 10,
                    minLines: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isSending
                  ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
                  : ElevatedButton(
                onPressed: _sendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child:  translatedtranslatedText('         Send Email         ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           translatedtranslatedText('Email Templates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
           translatedtranslatedText('Select a template to preview and use',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: kIsWeb ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: [
                _buildTemplateCard(
                  'Booking Confirmation',
                  'Send when a booking is confirmed',
                  Icons.calendar_today_outlined,
                  Colors.blue,
                  _bookingConfirmationTemplate,
                ),
                _buildTemplateCard(
                  'Welcome Email',
                  'Send to new users after signup',
                  Icons.waving_hand_outlined,
                  Colors.green,
                  _welcomeEmailTemplate,
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
      String title,
      String description,
      IconData icon,
      Color color,
      String Function() templateGenerator,
      ) {
    return Container(

      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showTemplatePreview(templateGenerator(), title);
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                translatedtranslatedText(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                translatedtranslatedText(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),

                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  void _useTemplate(String template) {
    _bodyController.text = template;
    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:  translatedtranslatedText('Template loaded into editor'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

// Add this import

  void _showTemplatePreview(String htmlContent, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: translatedtranslatedText('$title Template'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child:  translatedtranslatedText('CLOSE'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _useTemplate(htmlContent);
                        },
                        child:  translatedtranslatedText('USE TEMPLATE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _bookingConfirmationTemplate() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Confirmation | JUclean</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background-color: #f5f7fa;
        }
        .email-container {
            max-width: 640px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.08);
        }
        .header {
            background: linear-gradient(135deg, #0d9488 0%, #115e59 100%);
            padding: 40px 20px;
            text-align: center;
            color: white;
            position: relative;
        }
        .header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 700;
        }
        .content {
            padding: 32px;
        }
        .confirmation-badge {
            background: #10b981;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: 600;
            display: inline-block;
            margin-bottom: 16px;
        }
        .booking-card {
            background: #f8fafc;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
            border-left: 4px solid #0d9488;
        }
        .booking-row {
            display: flex;
            margin-bottom: 12px;
        }
        .booking-label {
            width: 120px;
            color: #64748b;
            font-weight: 500;
        }
        .booking-value {
            flex: 1;
            font-weight: 500;
        }
        .footer {
            text-align: center;
            padding: 24px;
            background: #f8fafc;
            color: #64748b;
            font-size: 14px;
        }
        .button {
            display: inline-block;
            background: linear-gradient(135deg, #0d9488 0%, #115e59 100%);
            color: white !important;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            margin-top: 16px;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>Your Booking Is Confirmed!</h1>
            <p>We're looking forward to serving you</p>
        </div>

        <div class="content">
            <div class="confirmation-badge">CONFIRMED</div>
            <p>Thank you for booking with JUclean. Below are the details of your upcoming service.</p>

            <div class="booking-card">
                <div class="booking-row">
                    <div class="booking-label">Service:</div>
                    <div class="booking-value">Deep Cleaning</div>
                </div>
                <div class="booking-row">
                    <div class="booking-label">Date:</div>
                    <div class="booking-value">June 15, 2023</div>
                </div>
                <div class="booking-row">
                    <div class="booking-label">Time:</div>
                    <div class="booking-value">10:00 AM - 12:00 PM</div>
                </div>
                <div class="booking-row">
                    <div class="booking-label">Address:</div>
                    <div class="booking-value">123 Main St, Apt 4B, New York, NY 10001</div>
                </div>
                <div class="booking-row">
                    <div class="booking-label">Price:</div>
                    <div class="booking-value">\$120.00</div>
                </div>
            </div>

            <p style="margin-top: 32px;">Your cleaner will contact you before the appointment. If you need to make any changes, please reply to this email.</p>
            <p>Best regards,<br><strong>The JUclean Team</strong></p>
        </div>

        <div class="footer">
            <p>JUclean Cleaning Services © ${DateTime.now().year}. All rights reserved.</p>
            <p><a href="mailto:support@juclean.com" style="color: #0d9488;">support@juclean.com</a></p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _welcomeEmailTemplate() {
    return  '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to JUclean - Your Sparkling Journey Begins!</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Inter', sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background-color: #f9fafb;
        }
        .email-container {
            max-width: 640px;
            margin: 20px auto;
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
        }
        .header {
            background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
            padding: 40px 20px;
            text-align: center;
            color: white;
            position: relative;
        }
        .header::after {
            content: "";
            position: absolute;
            bottom: -30px;
            left: 0;
            right: 0;
            height: 30px;
            background: white;
            border-radius: 24px 24px 0 0;
        }
        .logo {
            width: 120px;
            margin-bottom: 20px;
        }
        h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 700;
        }
        .tagline {
            margin: 8px 0 0;
            font-weight: 400;
            opacity: 0.9;
        }
        .content {
            padding: 40px;
        }
        .welcome-text {
            font-size: 16px;
            margin-bottom: 24px;
        }
        .company-info {
            background: #f8fafc;
            border-radius: 8px;
            padding: 24px;
            margin: 24px 0;
            border-left: 4px solid #3b82f6;
        }
        .info-title {
            color: #1d4ed8;
            margin-top: 0;
            font-size: 18px;
        }
        .features {
            display: flex;
            flex-wrap: wrap;
            gap: 16px;
            margin: 24px 0;
        }
        .feature {
            flex: 1 1 200px;
            background: #f8fafc;
            padding: 16px;
            border-radius: 8px;
            text-align: center;
        }
        .feature-icon {
            font-size: 24px;
            color: #3b82f6;
            margin-bottom: 8px;
        }
        .feature-title {
            font-weight: 600;
            margin: 8px 0 4px;
        }
        .button-container {
            text-align: center;
            margin: 32px 0;
        }
        .button {
            display: inline-block;
            background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
            color: white !important;
            padding: 14px 28px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.25);
            transition: all 0.3s ease;
        }
        .button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(59, 130, 246, 0.35);
        }
        .credentials {
            background: #f8fafc;
            padding: 16px;
            border-radius: 8px;
            margin: 16px 0;
            font-family: monospace;
            border-left: 3px solid #3b82f6;
        }
        .footer {
            text-align: center;
            padding: 24px;
            background: #f8fafc;
            color: #64748b;
            font-size: 14px;
        }
        .social-links {
            margin: 16px 0;
        }
        .social-links a {
            margin: 0 8px;
            color: #3b82f6;
            text-decoration: none;
        }
        .highlight {
            color: #1d4ed8;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>Welcome to JUclean!</h1>
            <p class="tagline">Where cleanliness meets perfection</p>
        </div>

        <div class="content">
            <p class="welcome-text">Dear Valued Customer,</p>
            <p class="welcome-text">Thank you for choosing <span class="highlight">JUclean</span> for your cleaning needs! We're thrilled to have you on board and can't wait to transform your space into a spotless sanctuary.</p>

            <div class="company-info">
                <h3 class="info-title">About JUclean</h3>
                <p>Founded in 2015, JUclean has been delivering exceptional cleaning services to thousands of satisfied customers. Our eco-friendly products and professional team ensure your space isn't just clean, but truly refreshed.</p>
            </div>

            <div class="features">
                <div class="feature">
                    <div class="feature-icon">✨</div>
                    <h4 class="feature-title">Eco-Friendly</h4>
                    <p>We use only environmentally safe cleaning products</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">🛡️</div>
                    <h4 class="feature-title">Fully Insured</h4>
                    <p>Your property is protected with our comprehensive insurance</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">⭐</div>
                    <h4 class="feature-title">5-Star Service</h4>
                    <p>Consistently rated excellent by our customers</p>
                </div>
            </div>

            <div class="button-container">
                <a href="{BookingLink}" class="button">Book Your First Cleaning</a>
            </div>

            <p>If you have any questions about our services or need assistance with your booking, our customer service team is available 7 days a week.</p>
            <p>Welcome to the JUclean family!</p>
            <p>Best regards,<br><strong>The JUclean Team</strong></p>
        </div>

        <div class="footer">
            <div class="social-links">
                <a href="{FacebookLink}">Facebook</a>
                <a href="{InstagramLink}">Instagram</a>
                <a href="{TwitterLink}">Twitter</a>
                <a href="{LinkedInLink}">LinkedIn</a>
            </div>
            <p>JUclean Cleaning Services ©. All rights reserved.</p>
            <p><a href="{PrivacyPolicyLink}" style="color: #3b82f6;">Privacy Policy</a> | <a href="{TermsLink}" style="color: #3b82f6;">Terms of Service</a></p>
            <p>123 Clean Street, Sparkle City, SC 12345</p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _paymentReceiptTemplate() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        /* Payment receipt template styles */
    </style>
</head>
<body>
    <!-- Payment receipt template HTML -->
</body>
</html>
''';
  }

  String _serviceReminderTemplate() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        /* Service reminder template styles */
    </style>
</head>
<body>
    <!-- Service reminder template HTML -->
</body>
</html>
''';
  }



  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int minLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: minLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
              width: 1.0,
            ),
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmailHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emailssent')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                const SizedBox(height: 16),
                translatedtranslatedText('Failed to load emails',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, color: Colors.grey[400], size: 48),
                const SizedBox(height: 16),
                translatedtranslatedText('No sent emails yet',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            var emailData = snapshot.data!.docs[index];
            var date = (emailData['timestamp'] as Timestamp).toDate();
            bool isSuccess = emailData['status'] == 'success';

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _showEmailDetails(emailData);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                      Row(
                        children: [
                          Expanded(
                            child: translatedtranslatedText(
                              emailData['subject'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),

                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSuccess
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSuccess
                                      ? Icons.check_circle_outlined
                                      : Icons.error_outline,
                                  size: 14,
                                  color: isSuccess
                                      ? Colors.green[600]
                                      : Colors.red[600],
                                ),
                                const SizedBox(width: 4),
                                translatedtranslatedText(
                                  isSuccess ? 'Sent' : 'Failed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSuccess
                                        ? Colors.green[600]
                                        : Colors.red[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      translatedtranslatedText('To: ${emailData['recipient']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      translatedtranslatedText(
                        DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEmailDetails(DocumentSnapshot emailData) {
    var date = (emailData['timestamp'] as Timestamp).toDate();
    bool isSuccess = emailData['status'] == 'success';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: translatedtranslatedText(
                      emailData['subject'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              translatedtranslatedText('To: ${emailData['recipient']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    isSuccess
                        ? Icons.check_circle_outlined
                        : Icons.error_outline,
                    size: 16,
                    color: isSuccess ? Colors.green[600] : Colors.red[600],
                  ),
                  const SizedBox(width: 4),
                  translatedtranslatedText(
                    isSuccess ? 'Sent successfully' : 'Failed to send',
                    style: TextStyle(
                      color: isSuccess ? Colors.green[600] : Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  translatedtranslatedText(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (!isSuccess) ...[
                const SizedBox(height: 8),
                translatedtranslatedText('Error: ${emailData['error'] ?? 'Unknown error'}',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
               translatedtranslatedText('Email Content:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  emailData['body'],
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child:  translatedtranslatedText('Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendEmail() async {
    if (_emailController.text.isEmpty ||
        _subjectController.text.isEmpty ||
        _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:  translatedtranslatedText('Please fill all fields'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final recipient = _emailController.text;
    final subject = _subjectController.text;
    final htmlBody = _bodyController.text;

    try {
      // Configure SMTP server
      final gmailSmtp = SmtpServer(
        'smtp.gmail.com',
        username: 'juclean988@gmail.com',
        password: 'fknp eufo jpjf wplh',
        port: 465,
        ssl: true,
      );

      // Create email message
      final message = Message()
        ..from = const Address('juclean988@gmail.com', 'JUCLEAN')
        ..recipients.add(recipient)
        ..subject = subject
        ..html = htmlBody;

      // Send email
      final sendReport = await send(message, gmailSmtp);
      print('Message sent: $sendReport');

      // Save to Firestore
      await FirebaseFirestore.instance.collection('emailssent').add({
        'recipient': recipient,
        'subject': subject,
        'body': htmlBody,
        'status': 'success',
        'timestamp': Timestamp.now(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:  translatedtranslatedText('Email sent successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Colors.green[400],
        ),
      );

      // Clear form
      _emailController.clear();
      _subjectController.clear();
      _bodyController.clear();
    } catch (e) {
      // Save error to Firestore
      await FirebaseFirestore.instance.collection('emailssent').add({
        'recipient': recipient,
        'subject': subject,
        'body': htmlBody,
        'status': 'failed',
        'error': e.toString(),
        'timestamp': Timestamp.now(),
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: translatedtranslatedText('Failed to send email: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
}