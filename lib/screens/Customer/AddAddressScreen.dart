import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../FastTranslationService.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({Key? key}) : super(key: key);

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final _addressNameController = TextEditingController();
  LatLng? _currentLocation;
  bool _isLoading = false;
  String? _selectedAddressType;
  bool isLoadingUser = true; // Loading state
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
  }

  final List<String> _addressTypes = ['Home', 'Work', 'Other'];

  @override
  void dispose() {
    _addressController.dispose();
    _mapLinkController.dispose();
    _addressNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: translatedtranslatedText('Add New Address',
        style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
    ),
    ),
    centerTitle: true,
    backgroundColor: Colors.blue.shade700,
    elevation: 0,
    shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
    bottom: Radius.circular(20),
    ),
    ),),
    body: SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(
    key: _formKey,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    _buildSectionHeader('Address Details'),
    const SizedBox(height: 16),

    // Address Name Field
    TextFormField(
    controller: _addressNameController,
    decoration: _buildInputDecoration(
    label: 'Address Name (e.g., My Home)',
    icon: Icons.label,
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please give this address a name';
    }
    return null;
    },
    ),
    const SizedBox(height: 20),

    // Address Type Dropdown
    DropdownButtonFormField<String>(
    value: _selectedAddressType,
    decoration: _buildInputDecoration(
    label: 'Address Type',
    icon: Icons.category,
    ),
    items: _addressTypes.map((type) {
    return DropdownMenuItem(
    value: type,
    child: translatedtranslatedText(type),
    );
    }).toList(),
    onChanged: (value) {
    setState(() {
    _selectedAddressType = value;
    });
    },
    validator: (value) {
    if (value == null) {
    return 'Please select address type';
    }
    return null;
    },
    ),
    const SizedBox(height: 20),

    // Full Address Field
    TextFormField(
    controller: _addressController,
    decoration: _buildInputDecoration(
    label: 'Full Address',
    icon: Icons.location_on,
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter your address';
    }
    return null;
    },
    maxLines: 3,
    ),
    const SizedBox(height: 20),

    // Google Maps Link Field
    TextFormField(
    controller: _mapLinkController,
    decoration: _buildInputDecoration(
    label: 'Google Maps Link (Optional)',
    icon: Icons.map,
    ),
    ),
    const SizedBox(height: 24),

    _buildSectionHeader('Location Services'),
    const SizedBox(height: 16),

    // Current Location Button
    ElevatedButton.icon(
    icon: const Icon(Icons.my_location, size: 22),
    label:  translatedtranslatedText('Use Current Location',
    style: TextStyle(fontSize: 16),
    ),
    onPressed: _getCurrentLocation,
    style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 52),
    backgroundColor: Colors.blue.shade50,
    foregroundColor: Colors.blue.shade800,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: Colors.blue.shade200),
    ),
    elevation: 0,
    ),
    ),
    const SizedBox(height: 20),

    // Location Coordinates Display
    if (_currentLocation != null)
    Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: Colors.green.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.green.shade200),
    ),
    child: Row(
    children: [
    Icon(Icons.gps_fixed, color: Colors.green.shade700),
    const SizedBox(width: 12),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    translatedtranslatedText('Current Location Coordinates',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.green.shade800,
    ),
    ),
    const SizedBox(height: 4),
    translatedtranslatedText(
    'Lat: ${_currentLocation!.latitude.toString()}\n'
    'Lng: ${_currentLocation!.longitude.toString()}',
    style: TextStyle(color: Colors.green.shade700),
    ),
    ],
    ),
    ),
    ],
    ),
    ),
    const SizedBox(height: 32),

    // Save Button
    SizedBox(
    width: double.infinity,
    child: ElevatedButton(
    onPressed: _isLoading ? null : _saveAddress,
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue.shade700,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    padding: const EdgeInsets.symmetric(vertical: 16),
    ),
    child: _isLoading
    ? const SizedBox(
    width: 24,
    height: 24,
    child: CircularProgressIndicator(
    strokeWidth: 3,
    color: Colors.white,
    ),
    )
        :  translatedtranslatedText('SAVE ADDRESS',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ),
    ],
    ),
    ),
    ),
    );
  }

  Widget _buildSectionHeader(String title) {
   return translatedtranslatedText(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 20,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    final location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    try {
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final locationData = await location.getLocation();
      setState(() {
        _currentLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        _mapLinkController.text =
        'https://www.google.com/maps?q=${locationData.latitude},${locationData.longitude}';
        _addressController.text = 'Current location at coordinates';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: translatedtranslatedText('Location obtained successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: translatedtranslatedText('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: translatedtranslatedText('Please sign in to save addresses'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .add({
        'name': _addressNameController.text,
        'type': _selectedAddressType,
        'address': _addressController.text,
        'mapLink': _mapLinkController.text,
        'coordinates': _currentLocation != null
            ? GeoPoint(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        )
            : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: translatedtranslatedText('Address saved successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: translatedtranslatedText('Failed to save address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}