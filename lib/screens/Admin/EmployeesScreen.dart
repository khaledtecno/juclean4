import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../FastTranslationService.dart';
import 'AnalyticsScreen.dart';
import 'SettingsAdmin.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateUserType(String email, String newType) async {
    try {
      await _firestore.collection('users').doc(email).update({
        'type': newType,
      });
      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: translatedtranslatedText('User type updated to $newType')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Error updating user type: $e')),
      );
    }
  }
  Future<void> _showConfirmationDialog(String email) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: translatedtranslatedText('Confirm Action', style: GoogleFonts.poppins()),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                translatedtranslatedText('Are you sure you want to make this employee a regular user?',
                    style: GoogleFonts.poppins()),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: translatedtranslatedText('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: translatedtranslatedText('Confirm', style: GoogleFonts.poppins(color: Colors.orange)),
              onPressed: () {
                _updateUserType(email, 'User');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              translatedtranslatedText('Employee Management',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),),
                  const SizedBox(height: 16),
                  translatedtranslatedText('Manage all employees and their permissions',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 14 : 16,
                        color: const Color(0xFF64748B),
                      ),),
                      const SizedBox(height: 24),
                      // Search Bar
                      _buildSearchBar(isMobile),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildEmployeeTableHeader(isMobile),
                              const SizedBox(height: 16),
                              _buildEmployeeTable(isMobile),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!isMobile) _buildEmployeeStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employees by name or email...',
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.grey,
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 14 : 16,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTableHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        translatedtranslatedText('All Employees',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
       /* ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.person_add, size: 18),
          label: translatedtranslatedText('Add Employee',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),*/
      ],
    );
  }

  Widget _buildEmployeeTable(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('type', isEqualTo: 'Employee').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> employees = snapshot.data!.docs;

        // Filter employees based on search query
        if (_searchQuery.isNotEmpty) {
          employees = employees.where((employee) {
            final employeeData = employee.data() as Map<String, dynamic>;
            final name = employeeData['Name']?.toString().toLowerCase() ?? '';
            final email = employee.id.toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();
        }

        if (employees.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: translatedtranslatedText(
              _searchQuery.isEmpty ? 'No employees found' : 'No matching employees found',
              style: GoogleFonts.poppins(),
            ),
          );
        }

        if (isMobile) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              final employeeData = employee.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: translatedtranslatedText(
                              employeeData['Name']?.substring(0, 1) ?? '?',
                              style: TextStyle(color: Colors.blue.shade800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                translatedtranslatedText(
                                  employeeData['Name'] ?? 'No Name',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                translatedtranslatedText(
                                  employee.id, // Using document ID as email
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusIndicator(employeeData['isOnline'] ?? false),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          translatedtranslatedText('Type: ${employeeData['type'] ?? 'Employee'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                            ),
                          ),
                          translatedtranslatedText('Verified: ${employeeData['emailVerified'] ?? false ? 'Yes' : 'No'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showConfirmationDialog(employee.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: translatedtranslatedText('Make Regular User',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns:  [
                DataColumn(label: translatedtranslatedText('Name')),
                DataColumn(label: translatedtranslatedText('Email')),
                DataColumn(label: translatedtranslatedText('Type')),
                DataColumn(label: translatedtranslatedText('Status')),
                DataColumn(label: translatedtranslatedText('Verified')),
                DataColumn(label: translatedtranslatedText('Last Online')),
                DataColumn(label: translatedtranslatedText('Actions')),
              ],
              rows: employees.map((employee) {
                final employeeData = employee.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(translatedtranslatedText(employeeData['Name'] ?? 'No Name')),
                  DataCell(translatedtranslatedText(employee.id)), // Using document ID as email
                  DataCell(translatedtranslatedText(employeeData['type'] ?? 'Employee')),
                  DataCell(_buildStatusIndicator(employeeData['isOnline'] ?? false)),
                  DataCell(translatedtranslatedText(employeeData['emailVerified'] ?? false ? 'Yes' : 'No')),
                  DataCell(translatedtranslatedText(employeeData['lastOnline']?.toString() ?? 'Unknown')),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_remove, size: 18),
                        onPressed: () => _updateUserType(employee.id, 'User'),
                        color: Colors.orange,
                        tooltip: 'Make Regular User',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {},
                        color: Colors.blue,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => _deleteUser(employee.id),
                        color: Colors.red,
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildStatusIndicator(bool isOnline) {
    final status = isOnline ? 'Online' : 'Offline';
    final color = isOnline ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: translatedtranslatedText(
        status,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _deleteUser(String email) async {
    try {
      await _firestore.collection('users').doc(email).delete();
      // Optionally delete from Firebase Auth as well
      // await FirebaseAuth.instance.deleteUser(email);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Error deleting user: $e')),
      );
    }
  }

  Widget _buildEmployeeStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;
        final totalEmployees = users.where((user) {
          final data = user.data() as Map<String, dynamic>;
          return data['type'] == 'Employee';
        }).length;
        final onlineEmployees = users.where((user) {
          final data = user.data() as Map<String, dynamic>;
          return data['type'] == 'Employee' && data['isOnline'] == true;
        }).length;
        final verifiedEmployees = users.where((user) {
          final data = user.data() as Map<String, dynamic>;
          return data['type'] == 'Employee' && data['emailVerified'] == true;
        }).length;

        return Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                translatedtranslatedText('Employee Statistics',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Total Employees', totalEmployees.toString(), Icons.people, Colors.blue),
                    _buildStatItem('Online', onlineEmployees.toString(), Icons.check_circle, Colors.green),
                    _buildStatItem('Verified', verifiedEmployees.toString(), Icons.verified, Colors.purple),
                    _buildStatItem('Active', (totalEmployees - onlineEmployees).toString(), Icons.person_off, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        translatedtranslatedText(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        translatedtranslatedText(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}