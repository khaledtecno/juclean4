import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../FastTranslationService.dart';



class EmployeesDashboard extends StatefulWidget {
  const EmployeesDashboard({super.key});

  @override
  State<EmployeesDashboard> createState() => _EmployeesDashboardState();
}

class _EmployeesDashboardState extends State<EmployeesDashboard> {
  int _selectedCategory = 0;
  final List<String> categories = ['All', 'Cleaners', 'Drivers', 'Managers'];
  final List<Map<String, dynamic>> employees = [
    {
      'name': 'Richard Johnson',
      'position': 'Senior Cleaner',
      'rate': '\$25/hr',
      'image': 'https://randomuser.me/api/portraits/men/1.jpg',
      'status': 'Available'
    },
    {
      'name': 'Sarah Williams',
      'position': 'Office Cleaner',
      'rate': '\$20/hr',
      'image': 'https://randomuser.me/api/portraits/women/1.jpg',
      'status': 'On Leave'
    },
    {
      'name': 'Michael Brown',
      'position': 'Driver',
      'rate': '\$22/hr',
      'image': 'https://randomuser.me/api/portraits/men/2.jpg',
      'status': 'Available'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: translatedtranslatedText('Employees',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {},
        ),
        actions: [
         /* IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),*/
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filter Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search employees...',
                        hintStyle: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: 'Sort by',
                      items: ['Sort by', 'Name', 'Rate', 'Status']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: translatedtranslatedText(
                            value,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1E293B),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (_) {},
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Categories
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: translatedtranslatedText(
                        categories[index],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _selectedCategory == index
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                      selected: _selectedCategory == index,
                      selectedColor: const Color(0xFF3B82F6),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedCategory = selected ? index : 0;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Employees List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(employee['image']),
                    ),
                    title: translatedtranslatedText(
                      employee['name'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        translatedtranslatedText(
                          employee['position'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            translatedtranslatedText(
                              employee['rate'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: employee['status'] == 'Available'
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: translatedtranslatedText(
                                employee['status'],
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: employee['status'] == 'Available'
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Container(
                      width: 100,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: translatedtranslatedText('Details',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}