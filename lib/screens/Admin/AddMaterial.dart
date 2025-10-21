import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../FastTranslationService.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final CollectionReference _materialsCollection =
  FirebaseFirestore.instance.collection('materials');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  bool _showAddForm = false;
  bool _showHiddenMaterials = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }
  Future<void> _addMaterial() async {
    if (_nameController.text.isEmpty || _quantityController.text.isEmpty) return;

    // Show confirmation dialog
    bool confirmAdd = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Add', style: GoogleFonts.poppins()),
        content: Text('Are you sure you want to add "${_nameController.text}" to materials?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Add',
              style: GoogleFonts.poppins(color: Colors.blue),
            ),
          ),
        ],
      ),
    );

    // If user confirmed, proceed with adding
    if (confirmAdd == true) {
      try {
        await _materialsCollection.add({
          'name': _nameController.text,
          'category': _categoryController.text,
          'quantity': int.tryParse(_quantityController.text) ?? 0,
          'unit': _unitController.text,
          'isVisible': true,
          'lastUpdated': DateTime.now(),
        });

        setState(() {
          _showAddForm = false;
          _clearForm();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Material added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding material: $e')),
        );
      }
    }
  }

  Future<void> _toggleVisibility(DocumentSnapshot material) async {
    try {
      await _materialsCollection.doc(material.id).update({
        'isVisible': !(material['isVisible'] as bool),
        'lastUpdated': DateTime.now(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: translatedtranslatedText('Error updating material: $e')),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _categoryController.clear();
    _quantityController.clear();
    _unitController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isSmallMobile = MediaQuery.of(context).size.width < 400;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  translatedtranslatedText('Material Management',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (!isMobile)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showAddForm = !_showAddForm),
                      icon: Icon(_showAddForm ? Icons.close : Icons.add, size: 18),
                      label: translatedtranslatedText(
                        _showAddForm ? 'Cancel' : 'Add Material',
                        style: GoogleFonts.poppins(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Search and filter row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search materials...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: translatedtranslatedText('Show Hidden',
                      style: GoogleFonts.poppins(fontSize: isSmallMobile ? 12 : 14),
                    ),
                    selected: _showHiddenMaterials,
                    onSelected: (selected) => setState(() => _showHiddenMaterials = selected),
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Add Material Form (conditionally shown)
              if (_showAddForm) _buildAddMaterialForm(isMobile),
              if (_showAddForm) const SizedBox(height: 24),

              // Materials List
              StreamBuilder<QuerySnapshot>(
                stream: _materialsCollection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: translatedtranslatedText('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final materials = snapshot.data!.docs.where((doc) {
                    final material = doc.data() as Map<String, dynamic>;
                    final matchesSearch =
                        material['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            material['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesVisibility = _showHiddenMaterials || material['isVisible'];
                    return matchesSearch && matchesVisibility;
                  }).toList();

                  if (materials.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            translatedtranslatedText('No materials found',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          if (!isMobile) _buildMaterialTableHeader(),
                          ...materials.map((material) =>
                              _buildMaterialItem(material, isMobile)),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Floating action button for mobile
              if (isMobile) const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
        onPressed: () => setState(() => _showAddForm = !_showAddForm),
        backgroundColor: Colors.blue,
        child: Icon(_showAddForm ? Icons.close : Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildAddMaterialForm(bool isMobile) {
    return Card(
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
            translatedtranslatedText('Add New Material',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isMobile ? double.infinity : 300,
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Material Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 150,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 150,
                  child: TextField(
                    controller: _unitController,
                    decoration: InputDecoration(
                      labelText: 'Unit (e.g., kg, pieces)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _addMaterial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: translatedtranslatedText('Save Material',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _deleteMaterial(DocumentSnapshot material) async {
    try {
      await _materialsCollection.doc(material.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: translatedtranslatedText('Material deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: translatedtranslatedText('Error deleting material: $e')),
        );
      }
    }
  }void _showDeleteConfirmation(DocumentSnapshot material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: translatedtranslatedText('Confirm Delete', style: GoogleFonts.poppins()),
        content: translatedtranslatedText('Are you sure you want to delete "${material['name']}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: translatedtranslatedText('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMaterial(material);
            },
            child: translatedtranslatedText('Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMaterialTableHeader() {
    return  Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: translatedtranslatedText('Name')),
          Expanded(flex: 2, child: translatedtranslatedText('Category')),
          Expanded(child: translatedtranslatedText('Quantity')),
          Expanded(child: translatedtranslatedText('Last Updated')),
          Expanded(child: translatedtranslatedText('Status')),
          SizedBox(width: 40), // For actions
        ],
      ),
    );
  }

  Widget _buildMaterialItem(DocumentSnapshot material, bool isMobile) {
    final data = material.data() as Map<String, dynamic>;
    final lastUpdated = (data['lastUpdated'] as Timestamp).toDate();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: InkWell(
        onTap: () {},
        child: isMobile
            ? Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  translatedtranslatedText(
                    data['name'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildVisibilityToggle(material),
                ],
              ),
              const SizedBox(height: 8),
              translatedtranslatedText('Category: ${data['category']}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  translatedtranslatedText('Quantity: ${data['quantity']} ${data['unit']}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  translatedtranslatedText(
                    DateFormat('MMM d').format(lastUpdated),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            : Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: translatedtranslatedText(
                  data['name'],
                  style: GoogleFonts.poppins(),
                ),
              ),
              Expanded(
                flex: 2,
                child: translatedtranslatedText(
                  data['category'],
                  style: GoogleFonts.poppins(),
                ),
              ),
              Expanded(
                child: translatedtranslatedText('${data['quantity']} ${data['unit']}',
                  style: GoogleFonts.poppins(),
                ),
              ),
              Expanded(
                child: translatedtranslatedText(
                  DateFormat('MMM d, y').format(lastUpdated),
                  style: GoogleFonts.poppins(),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: data['isVisible']
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: translatedtranslatedText(
                    data['isVisible'] ? 'Visible' : 'Hidden',
                    style: GoogleFonts.poppins(
                      color: data['isVisible']
                          ? Colors.green.shade800
                          : Colors.grey.shade800,
                      fontSize: 12,
                    ),

                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: _buildVisibilityToggle(material),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red.shade400, size: 20),
                onPressed: () => _showDeleteConfirmation(material),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityToggle(DocumentSnapshot material) {
    final data = material.data() as Map<String, dynamic>;
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: data['isVisible'],
        onChanged: (_) => _toggleVisibility(material),
        activeColor: Colors.blue,
        activeTrackColor: Colors.blue.shade100,
        inactiveThumbColor: Colors.grey.shade600,
        inactiveTrackColor: Colors.grey.shade200,
      ),
    );
  }
}