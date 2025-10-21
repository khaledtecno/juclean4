import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../FastTranslationService.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  int _selectedTab = 0;
  bool _isLoading = true;
  bool _obscureText = true;

  bool _isMalay = false;bool isLoadingUser = true; // Loading state

  bool _isRefreshing = false;
  @override
  void initState() {
    super.initState();    _loadAnalyticsData();
    _initializeTranslations();  _getLanguagePreference();
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
  // Analytics data
  int _totalBookings = 0;
  int _totalRevenue = 0;
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _totalEmployees = 0;
  int _activeEmployees = 0;
  List<Map<String, dynamic>> _chartData = [];
  Map<String, int> _statusCounts = {};
  List<Map<String, dynamic>> _bookingsData = [];



  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadSummaryData(),
      _loadChartData(),
      _loadStatusCounts(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadSummaryData() async {
    // Load bookings count
    final bookingsQuery = FirebaseFirestore.instance.collection('bookings')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(_dateRange.start))
        .where('createdAt', isLessThan: Timestamp.fromDate(_dateRange.end.add(const Duration(days: 1))));

    final bookingsSnapshot = await bookingsQuery.get();
    _totalBookings = bookingsSnapshot.docs.length;
    _bookingsData = bookingsSnapshot.docs.map((doc) => doc.data()).toList();

    // Load users count
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').where('type', isEqualTo: 'User').get();
    _totalUsers = usersSnapshot.docs.length;

    // Load employees count
    final employeesSnapshot = await FirebaseFirestore.instance.collection('users').where('type', isEqualTo: 'Employee').get();
    _totalEmployees = employeesSnapshot.docs.length;
  }

  Future<void> _loadChartData() async {
    // Group bookings by day of week
    final bookingsQuery = FirebaseFirestore.instance.collection('bookings')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(_dateRange.start))
        .where('createdAt', isLessThan: Timestamp.fromDate(_dateRange.end.add(const Duration(days: 1))));

    final bookingsSnapshot = await bookingsQuery.get();

    // Initialize chart data with all days
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    _chartData = days.map((day) => {
      'day': day,
      'bookings': 0,
      'users': 0,
      'employees': 0,
    }).toList();

    // Count bookings by day of week
    for (final booking in bookingsSnapshot.docs) {
      final data = booking.data();
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      final dayIndex = (createdAt.weekday + 5) % 7; // Convert to 0-6 range (Mon-Sun)

      if (dayIndex >= 0 && dayIndex < _chartData.length) {
        _chartData[dayIndex]['bookings'] += 1;
      }
    }
  }

  Future<void> _loadStatusCounts() async {
    final bookingsSnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    _statusCounts = groupBy(bookingsSnapshot.docs, (doc) => doc['status']?.toString() ?? 'unknown')
        .map((key, value) => MapEntry(key, value.length));
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );
    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      _loadAnalyticsData();
    }
  }

  Future<void> _exportAsPdf() async {
    final pdf = pw.Document();
    final theme = await _getPdfTheme();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: theme,
        build: (context) => [
          pw.Header(
              level: 0,
              child: pw.Text('Analytics Report',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Text('Date Range: ${DateFormat('MMM d, y').format(_dateRange.start)} - ${DateFormat('MMM d, y').format(_dateRange.end)}'),
          pw.Divider(),
          pw.Header(level: 1, child: pw.Text('Summary Statistics')),
          _buildPdfSummaryTable(),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Bookings by Status')),
          _buildPdfStatusTable(),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('${_getSelectedTabName()} Data')),
          _buildPdfDataTable(),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  pw.Widget _buildPdfStatusTable() {
    return pw.Table.fromTextArray(
      headers: ['Status', 'Count'],
      data: _statusCounts.entries.map((e) => [e.key, e.value]).toList(),
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
    );
  }

  Future<pw.PageTheme> _getPdfTheme() async {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.openSansRegular(),
        bold: await PdfGoogleFonts.openSansBold(),
      ),
    );
  }

  pw.Widget _buildPdfSummaryTable() {
    return pw.Table.fromTextArray(
      headers: ['Metric', 'Value'],
      data: [
        ['Total Bookings', _totalBookings.toString()],
        ['Total Users', _totalUsers.toString()],
        ['Total Employees', _totalEmployees.toString()],
      ],
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
      },
    );
  }

  pw.Widget _buildPdfDataTable() {
    return pw.Table.fromTextArray(
      headers: ['Day', _getSelectedTabName()],
      data: _chartData.map((item) => [
        item['day'],
        item[_getDataKey()].toString(),
      ]).toList(),
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 25,
    );
  }

  Future<void> _exportAsExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Analytics Data'];

      // Add summary data
      sheet.appendRow(['Metric', 'Value']);
      sheet.appendRow(['Total Bookings', _totalBookings]);
      sheet.appendRow(['Total Users', _totalUsers]);
      sheet.appendRow(['Total Employees', _totalEmployees]);
      sheet.appendRow(['Active Users', _activeUsers]);
      sheet.appendRow(['Active Employees', _activeEmployees]);
      sheet.appendRow([]);

      // Add status counts
      sheet.appendRow(['Status', 'Count']);
      for (final entry in _statusCounts.entries) {
        sheet.appendRow([entry.key, entry.value]);
      }
      sheet.appendRow([]);

      // Add chart data
      sheet.appendRow(['Day', _getSelectedTabName()]);
      for (var item in _chartData) {
        sheet.appendRow([item['day'], item[_getDataKey()]]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Failed to generate Excel file');
      }


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: translatedtranslatedText('Excel exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: translatedtranslatedText('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  String _getSelectedTabName() {
    switch (_selectedTab) {
      case 0: return 'Bookings';
      case 1: return 'Users';
      case 2: return 'Employees';
      default: return 'Data';
    }
  }

  String _getDataKey() {
    switch (_selectedTab) {
      case 0: return 'bookings';
      case 1: return 'users';
      case 2: return 'employees';
      default: return 'bookings';
    }
  }

  Color _getChartColor() {
    switch (_selectedTab) {
      case 0: return Colors.blue;
      case 1: return Colors.green;
      case 2: return Colors.orange;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isSmallMobile = MediaQuery.of(context).size.width < 400;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            translatedtranslatedText('Analytics Overview',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            translatedtranslatedText('${DateFormat('MMM d, y').format(_dateRange.start)} - ${DateFormat('MMM d, y').format(_dateRange.end)}',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 12 : 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            // Summary Cards - Top Section
            _buildSummarySection(isMobile, isSmallMobile),
            const SizedBox(height: 24),

            // Date Range Picker with Export Button
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        translatedtranslatedText('Date Range',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _selectDateRange(context),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: translatedtranslatedText('Change',
                            style: GoogleFonts.poppins(),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        icon:  Icon(Icons.download, size: 20),
                        itemBuilder: (context) => [
                           PopupMenuItem(
                            value: 'pdf',
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf, color: Colors.red),
                                SizedBox(width: 8),
                                translatedtranslatedText('Export as PDF'),
                              ],
                            ),
                          ),
                       /*   const PopupMenuItem(
                            value: 'excel',
                            child: Row(
                              children: [
                                Icon(Icons.grid_on, color: Colors.green),
                                SizedBox(width: 8),
                                translatedtranslatedText('Export as Excel'),
                              ],
                            ),
                          ),*/
                        ],
                        onSelected: (value) {
                          if (value == 'pdf') {
                            _exportAsPdf();
                          } else {
                            _exportAsExcel();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Segmented Control
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: translatedtranslatedText('Bookings', style: GoogleFonts.poppins(fontSize: isSmallMobile ? 12 : 14)),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: translatedtranslatedText('Users', style: GoogleFonts.poppins(fontSize: isSmallMobile ? 12 : 14)),
                  ),
                  if (!isSmallMobile)
                    ButtonSegment(
                      value: 2,
                      label: translatedtranslatedText('Employees', style: GoogleFonts.poppins(fontSize: 14)),
                    ),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _selectedTab = newSelection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Main Chart
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    translatedtranslatedText(
                      _selectedTab == 0 ? 'Bookings This Week' :
                      _selectedTab == 1 ? 'User Activity' : 'Employee Status',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: isMobile ? 220 : 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _selectedTab == 0 ? _getMaxBookings() + 5 :
                          _selectedTab == 1 ? 20 : 5,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  rod.toY.toInt().toString(),
                                  GoogleFonts.poppins(
                                    color: _getChartColor(),
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: translatedtranslatedText(
                                      _chartData[value.toInt()]['day'],
                                      style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 10 : 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 10 : 12,
                                    ),
                                  );
                                },
                                reservedSize: isMobile ? 28 : 40,
                              ),
                            ),
                            rightTitles: AxisTitles(),
                            topTitles: AxisTitles(),
                          ),
                          borderData: FlBorderData(
                            show: false,
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: _selectedTab == 0 ? (_getMaxBookings() > 10 ? 5 : 2) :
                            _selectedTab == 1 ? 4 : 1,
                          ),
                          barGroups: _chartData.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: _selectedTab == 0
                                      ? entry.value['bookings'].toDouble()
                                      : _selectedTab == 1
                                      ? entry.value['users'].toDouble()
                                      : entry.value['employees'].toDouble(),
                                  color: _getChartColor(),
                                  width: isMobile ? 16 : 20,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status Distribution Pie Chart
            if (_selectedTab == 0) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      translatedtranslatedText('Bookings by Status',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            sections: _statusCounts.entries.map((entry) {
                              final color = _getStatusColor(entry.key);
                              return PieChartSectionData(
                                color: color,
                                value: entry.value.toDouble(),
                                title: '${entry.key}\n${entry.value}',
                                radius: 60,
                                titleStyle: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _getMaxBookings() {
    if (_chartData.isEmpty) return 10;
    return _chartData.map((e) => e['bookings']).reduce((a, b) => a > b ? a : b).toDouble();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.purple;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSummarySection(bool isMobile, bool isSmallMobile) {
    final crossAxisCount = isSmallMobile ? 2 : 3;
    final childAspectRatio = isSmallMobile ? 1.3 : 1.5;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: childAspectRatio,
      children: [
        _buildSummaryCard(
          context,
          'Total Bookings',
          _totalBookings.toString(),
          Icons.shopping_bag,
          Colors.blue,

        ),
        _buildSummaryCard(
          context,
          'Total Users',
          _totalUsers.toString(),
          Icons.people,
          Colors.green,

        ),
        if (!isSmallMobile)
          _buildSummaryCard(
            context,
            'Employees',
            _totalEmployees.toString(),
            Icons.badge,
            Colors.orange,

          ),
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color color,

      ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                if (!isMobile)
                  translatedtranslatedText(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                translatedtranslatedText(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 12 : 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                if (isMobile)
                  translatedtranslatedText(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 4),

              ],
            ),
          ],
        ),
      ),
    );
  }
}