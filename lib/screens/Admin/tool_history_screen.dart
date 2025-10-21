import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../FastTranslationService.dart';

class ToolHistoryScreen extends StatefulWidget {
  const ToolHistoryScreen({super.key});

  @override
  State<ToolHistoryScreen> createState() => _ToolHistoryScreenState();
}

class _ToolHistoryScreenState extends State<ToolHistoryScreen> {
  DateTimeRange? _dateRange;
  String? _selectedTool;
  String? _selectedEmployee;
  List<String> _tools = [];
  List<String> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadFilters();
    // Default to last 30 days
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
  }

  Future<void> _loadFilters() async {
    // Get unique tools
    final toolsSnapshot = await FirebaseFirestore.instance
        .collection('toolUsageHistory')
        .orderBy('toolName')
        .get();

    final tools = toolsSnapshot.docs
        .map((doc) => doc['toolName'] as String)
        .toSet()
        .toList();

    // Get unique employees
    final employeesSnapshot = await FirebaseFirestore.instance
        .collection('toolUsageHistory')
        .orderBy('employeeName')
        .get();

    final employees = employeesSnapshot.docs
        .map((doc) => doc['employeeName'] as String)
        .toSet()
        .toList();

    setState(() {
      _tools = tools;
      _employees = employees;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  translatedtranslatedText('Tool Usage History & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          _buildSummaryCards(),
          // Charts
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Usage History'),
                      Tab(text: 'Analytics'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildHistoryList(),
                        _buildAnalyticsCharts(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }

        final docs = snapshot.data!.docs;
        final totalUsage = docs.fold<int>(0, (sum, doc) => sum + (doc['quantityUsed'] as int));
        final uniqueTools = docs.map((doc) => doc['toolName']).toSet().length;
        final uniqueEmployees = docs.map((doc) => doc['employeeName']).toSet().length;

        return SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildSummaryCard('Total Usage', '$totalUsage items', Icons.inventory),
              _buildSummaryCard('Tools Used', '$uniqueTools tools', Icons.construction),
              _buildSummaryCard('Employees', '$uniqueEmployees people', Icons.people),
              _buildSummaryCard(
                  'Date Range',
                  '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                  Icons.calendar_today
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.blue),
            const SizedBox(height: 8),
            translatedtranslatedText(title, style: GoogleFonts.poppins(fontSize: 12)),
            translatedtranslatedText(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return  Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return  Center(child: translatedtranslatedText('No records found for selected filters'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final date = (data['dateUsed'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.construction, color: Colors.blue),
                title: translatedtranslatedText(data['toolName']),
                subtitle: translatedtranslatedText(
                  '${data['quantityUsed']} used by ${data['employeeName']}\n'
                      '${DateFormat('MMM d, yyyy - hh:mm a').format(date)}',
                ),
                trailing: translatedtranslatedText('Booking #${data['bookingId'].toString().substring(0, 6)}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                onTap: () {
                  // Show details dialog
                  _showUsageDetails(context, data);
                },
              ),
            );
          },
        );
      },
    );
  }

// Replace the _buildAnalyticsCharts method with this:
  Widget _buildAnalyticsCharts() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Tool Usage Chart
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredQuery().snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return  Center(child: translatedtranslatedText('No data available for charts'));
                }

                // Group by tool
                final toolUsage = <String, int>{};
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final tool = data['toolName'] as String;
                  final quantity = data['quantityUsed'] as int;
                  toolUsage[tool] = (toolUsage[tool] ?? 0) + quantity;
                }

                final chartData = toolUsage.entries
                    .map((e) => BarChartGroupData(
                  x: toolUsage.keys.toList().indexOf(e.key),
                  barRods: [
                    BarChartRodData(
                      toY: e.value.toDouble(),
                      color: Colors.blue,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                  showingTooltipIndicators: [0],
                ))
                    .toList();

                final toolNames = toolUsage.keys.toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: toolUsage.values.reduce(max).toDouble() * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(


                          getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                              BarTooltipItem(
                                '${toolNames[group.x]}\n${rod.toY.toInt()}',
                                const TextStyle(color: Colors.white),
                              ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: translatedtranslatedText(
                                toolNames[value.toInt()],
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),

                              ),
                            ),
                            reservedSize: 40,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => translatedtranslatedText(
                              value.toInt().toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                            ),
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: chartData,
                      gridData: FlGridData(show: false),
                    ),
                  ),
                );
              },
            ),
          ),
          // Employee Usage Chart
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredQuery().snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return  Center(child: translatedtranslatedText('No data available for charts'));
                }

                // Group by employee
                final employeeUsage = <String, int>{};
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final employee = data['employeeName'] as String;
                  final quantity = data['quantityUsed'] as int;
                  employeeUsage[employee] = (employeeUsage[employee] ?? 0) + quantity;
                }

                final chartData = employeeUsage.entries
                    .map((e) => PieChartSectionData(
                  color: Colors.primaries[
                  employeeUsage.keys.toList().indexOf(e.key) %
                      Colors.primaries.length],
                  value: e.value.toDouble(),
                  title: '${e.value}',
                  radius: 80,
                  titleStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ))
                    .toList();

                return PieChart(
                  PieChartData(
                    sections: chartData,
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                      enabled: true,
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 500),
                );
              },
            ),
          ),
          // Time Series Chart
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredQuery().snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return  Center(child: translatedtranslatedText('No data available for charts'));
                }

                // Group by date
                final dateUsage = <DateTime, int>{};
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['dateUsed'] as Timestamp).toDate();
                  final dateOnly = DateTime(date.year, date.month, date.day);
                  final quantity = data['quantityUsed'] as int;
                  dateUsage[dateOnly] = (dateUsage[dateOnly] ?? 0) + quantity;
                }

                final sortedDates = dateUsage.keys.toList()..sort();
                final spots = sortedDates
                    .map((date) => FlSpot(
                    date.millisecondsSinceEpoch.toDouble(),
                    dateUsage[date]!.toDouble()))
                    .toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(

                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  spot.x.toInt());
                              return LineTooltipItem(
                                '${DateFormat('MMM d').format(date)}\n${spot.y.toInt()}',
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final date =
                              DateTime.fromMillisecondsSinceEpoch(value.toInt());
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: translatedtranslatedText(
                                  DateFormat('MMM d').format(date),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => translatedtranslatedText(
                              value.toInt().toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                            ),
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: sortedDates.first.millisecondsSinceEpoch.toDouble(),
                      maxX: sortedDates.last.millisecondsSinceEpoch.toDouble(),
                      minY: 0,
                      maxY: dateUsage.values.reduce(max).toDouble() * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:  translatedtranslatedText('Filter History'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title:  translatedtranslatedText('Date Range'),
                  subtitle: translatedtranslatedText('${DateFormat('MMM d, yyyy').format(_dateRange!.start)} - '
                        '${DateFormat('MMM d, yyyy').format(_dateRange!.end)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDateRange(context),
                ),
                const Divider(),
                DropdownButtonFormField<String>(
                  value: _selectedTool,
                  decoration: const InputDecoration(labelText: 'Filter by Tool'),
                  items: [
                     DropdownMenuItem(value: null, child: translatedtranslatedText('All Tools')),
                    ..._tools.map((tool) => DropdownMenuItem(
                      value: tool,
                      child: translatedtranslatedText(tool),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTool = value;
                    });
                    Navigator.pop(context);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedEmployee,
                  decoration: const InputDecoration(labelText: 'Filter by Employee'),
                  items: [
                     DropdownMenuItem(value: null, child: translatedtranslatedText('All Employees')),
                    ..._employees.map((emp) => DropdownMenuItem(
                      value: emp,
                      child: translatedtranslatedText(emp),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedEmployee = value;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTool = null;
                  _selectedEmployee = null;
                  _dateRange = DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 30)),
                    end: DateTime.now(),
                  );
                });
                Navigator.pop(context);
              },
              child:  translatedtranslatedText('Reset Filters'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:  translatedtranslatedText('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showUsageDetails(BuildContext context, Map<String, dynamic> data) {
    final date = (data['dateUsed'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: translatedtranslatedText('Usage Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tool Name', data['toolName']),
              _buildDetailRow('Quantity Used', data['quantityUsed'].toString()),
              _buildDetailRow('Employee', data['employeeName']),
              _buildDetailRow('Employee Email', data['employeeEmail']),
              _buildDetailRow('Booking ID', data['bookingId']),
              _buildDetailRow('Service', data['serviceName']),

              _buildDetailRow('Customer Email', data['customerEmail']),
              _buildDetailRow('Date', DateFormat('MMM d, yyyy - hh:mm a').format(date)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:  translatedtranslatedText('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          translatedtranslatedText('$label: ',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: translatedtranslatedText(
              value,
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Query _getFilteredQuery() {
    Query query = FirebaseFirestore.instance.collection('toolUsageHistory');

    // Apply date filter
    if (_dateRange != null) {
      query = query.where(
        'dateUsed',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange!.start),
      ).where(
        'dateUsed',
        isLessThanOrEqualTo: Timestamp.fromDate(_dateRange!.end),
      );
    }

    // Apply tool filter
    if (_selectedTool != null) {
      query = query.where('toolName', isEqualTo: _selectedTool);
    }

    // Apply employee filter
    if (_selectedEmployee != null) {
      query = query.where('employeeName', isEqualTo: _selectedEmployee);
    }

    return query.orderBy('dateUsed', descending: true);
  }
}

class ChartData {
  final String x;
  final int y;

  ChartData(this.x, this.y);
}

class TimeSeriesData {
  final DateTime date;
  final int value;

  TimeSeriesData(this.date, this.value);
}