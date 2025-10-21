import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../FastTranslationService.dart';
import 'DetailService.dart';

class SearchC extends StatefulWidget {
  const SearchC({super.key});

  @override
  State<SearchC> createState() => _SearchCState();
}

class _SearchCState extends State<SearchC> {

  bool isLoadingUser = true; // Loading state
  bool _isMalay = false;
  bool _isRefreshing = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
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
  } Widget translatedtranslatedText(String text, {TextStyle? style}) {
    return Text(
      FastTranslationService.translate(text),
      style: style,
    );
  }
  String _searchQuery = '';
  String _sortBy = 'price_asc';
  final Map<String, String> _sortOptions = {
    'price_asc': 'Price: Lowest First',
    'price_desc': 'Price: Highest First',
    'rating_asc': 'Rating: Lowest First',
    'rating_desc': 'Rating: Highest First',
  };
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;
  List<String> _suggestions = [];
  Timer? _debounceTimer;



  @override
  void dispose() {
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Split query into words and create search terms
    final words = query.toLowerCase().split(' ');
    final searchTerms = words.where((word) => word.length > 2).toList();

    if (searchTerms.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('services')
        .get();

    // Filter locally for word-by-word matching
    final allServices = snapshot.docs.map((doc) => doc['name'] as String).toList();

    final matchedServices = allServices.where((service) {
      final serviceLower = service.toLowerCase();
      return searchTerms.every((term) => serviceLower.contains(term));
    }).toList();

    setState(() {
      _suggestions = matchedServices.take(5).toList();
      _showSuggestions = _suggestions.isNotEmpty;
    });
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    setState(() {
      _searchQuery = value.toLowerCase();
      _showSuggestions = value.isNotEmpty;
    });

    // Start a new timer with 300ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.arrow_back_ios_new_sharp)),
                    SizedBox(width: 10),
                    translatedtranslatedText('Search',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2F3534),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        )),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar with Suggestions
                Column(
                  children: [
                    TextFormField(
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      onTap: () {
                        if (_searchQuery.isNotEmpty) {
                          setState(() {
                            _showSuggestions = true;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search services...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    if (_showSuggestions && _suggestions.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              dense: true,
                              title: translatedtranslatedText(
                                _suggestions[index],
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                              onTap: () {
                                setState(() {
                                  _searchQuery = _suggestions[index].toLowerCase();
                                  _showSuggestions = false;
                                  _searchFocusNode.unfocus();
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Rest of your existing UI components...
                // (Sort dropdown, filter buttons, service cards)
                // ... keep all your existing code below this point

                // Sort by Dropdown
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    hintText: 'Sort by',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _sortOptions.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: translatedtranslatedText(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton('All'),
                      SizedBox(width: 8),
                      _buildFilterButton('Cleaning'),
                      SizedBox(width: 8),
                      _buildFilterButton('Repair'),
                      SizedBox(width: 8),
                      _buildFilterButton('Maintenance'),
                    ],
                  ),
                ),
                const SizedBox(height: 5),

                // Service Cards with filtered/sorted StreamBuilder
                Container(
                  height: MediaQuery.of(context).size.height - 320,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('services')
                        .orderBy(
                      _sortBy.contains('price') ? 'price' : 'rating',
                      descending: _sortBy.contains('_desc'),
                    )
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {

                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: translatedtranslatedText('No services available.'));
                      }

                      // Apply search filter
                      final filteredDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'].toString().toLowerCase();
                        final description = data['description'].toString().toLowerCase();

                        // Split search query into words
                        final searchWords = _searchQuery.split(' ');

                        // Check if all search words appear in either name or description
                        return searchWords.every((word) =>
                        name.contains(word) || description.contains(word));
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(child: translatedtranslatedText('No matching services found.'));
                      }

                      return ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final booking = filteredDocs[index];
                          final bookingData =
                          booking.data() as Map<String, dynamic>;

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Detailservice(
                                    name: bookingData['name'],
                                    description: bookingData['description'],
                                    price: bookingData['price'],
                                    imgurl: bookingData['imgurl'],
                                    additional: bookingData['rooms'],
                                    rooms: bookingData['additional'],
                                    id: booking.id.toString(),
                                  ),
                                ),
                              );
                            },
                            child: _buildServiceCard(
                              title: bookingData['name'],
                              description: bookingData['description'],
                              price: bookingData['price'] + 'EUR',
                              imageUrl: bookingData['imageUrl'] ??
                                  'https://cdn.prod.website-files.com/60ff934f6ded2d17563ab9dd/61392d68372fbf957b87bb8d_starting-a-cleaning-business.jpeg',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: translatedtranslatedText(
        text,
        style: GoogleFonts.poppins(
          color: const Color(0xFF939899),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String description,
    required String price,
    required String imageUrl,
  }) {
    return Card(
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D6D5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  translatedtranslatedText(
                    title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF303535),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      translatedtranslatedText(
                        description,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC4C4C4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  translatedtranslatedText(
                    price,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF787E7D),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}