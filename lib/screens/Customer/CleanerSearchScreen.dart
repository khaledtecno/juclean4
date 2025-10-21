import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../FastTranslationService.dart';



class CleanerSearchScreen extends StatefulWidget {
  const CleanerSearchScreen({super.key});

  @override
  State<CleanerSearchScreen> createState() => _CleanerSearchScreenState();
}

class _CleanerSearchScreenState extends State<CleanerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
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
  } Widget translatedtranslatedText(String text, {TextStyle? style}) {
    return Text(
      FastTranslationService.translate(text),
      style: style,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Header with search
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.teal[700]!,
                      Colors.teal[500]!,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
                  child: Column(
                    children: [
                      translatedtranslatedText('Find Nearby Cleaners',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Search bar with ripple animation
                      Hero(
                        tag: 'search',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              // Show search dialog
                              showSearch(
                                context: context,
                                delegate: CleanerSearchDelegate(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search, color: Colors.white),
                                  const SizedBox(width: 10),
                                  translatedtranslatedText('Search by name or service...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filter chips
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('All'),
                    _buildFilterChip('Deep Cleaning'),
                    _buildFilterChip('House Cleaning'),
                    _buildFilterChip('Office Cleaning'),
                    _buildFilterChip('Eco-Friendly'),
                  ],
                ),
              ),
            ),
          ),

          // Nearby cleaners title
          SliverPadding(
            padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
            sliver: SliverToBoxAdapter(
              child: translatedtranslatedText('Nearby Cleaners (1-100m)',
                style: GoogleFonts.poppins(
                  color: Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Cleaners list
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final cleaner = cleaners[index];
                return _buildCleanerCard(cleaner);
              },
              childCount: cleaners.length,
            ),
          ),

          // View all button
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                child: translatedtranslatedText('View All Nearby Cleaners',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: label,
        selected: _selectedFilter == label,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : 'All';
          });
        },
      ),
    );
  }

  Widget _buildCleanerCard(Cleaner cleaner) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // Show cleaner details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Profile image with ripple animation
                  Hero(
                    tag: 'cleaner-${cleaner.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          // Show profile
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(cleaner.imageUrl),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        translatedtranslatedText(
                          cleaner.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        translatedtranslatedText(
                          cleaner.service,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rating
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.teal[700], size: 16),
                        const SizedBox(width: 4),
                        translatedtranslatedText(
                          cleaner.rating.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.teal[600]),
                  const SizedBox(width: 5),
                  translatedtranslatedText('${cleaner.distance}m away',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(
                    width: 1,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(width: 15),


                  const Spacer(),
                  // Book button with ripple animation
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        // Book cleaner
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: translatedtranslatedText('Book',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
  }
}
class ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;

  const ChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label:translatedtranslatedText(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: selected ? Colors.white : Colors.teal[600],
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: Colors.teal[600],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? Colors.teal[600]! : Colors.grey[300]!,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}


class CleanerSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = query.isEmpty
        ? cleaners
        : cleaners.where((cleaner) =>
    cleaner.name.toLowerCase().contains(query.toLowerCase()) ||
        cleaner.service.toLowerCase().contains(query.toLowerCase()));

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final cleaner = results.elementAt(index);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(cleaner.imageUrl),
          ),
          title:translatedtranslatedText(cleaner.name),
          subtitle:translatedtranslatedText(cleaner.service),
          trailing: translatedtranslatedText('\\${cleaner.price}/hr'),
          onTap: () {
            close(context, cleaner.name);
          },
        );
      },
    );
  }
}

class Cleaner {
  final String id;
  final String name;
  final String service;
  final double rating;
  final int distance;
  final int price;
  final String imageUrl;

  Cleaner({
    required this.id,
    required this.name,
    required this.service,
    required this.rating,
    required this.distance,
    required this.price,
    required this.imageUrl,
  });
}

final List<Cleaner> cleaners = [
  Cleaner(
    id: '1',
    name: 'Richard K.',
    service: 'Deep Cleaning Specialist',
    rating: 4.8,
    distance: 35,
    price: 35,
    imageUrl:
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
  ),
  Cleaner(
    id: '2',
    name: 'Maria S.',
    service: 'House Cleaning Expert',
    rating: 4.9,
    distance: 75,
    price: 40,
    imageUrl:
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
  ),
  Cleaner(
    id: '3',
    name: 'James L.',
    service: 'Eco-Friendly Cleaning',
    rating: 4.7,
    distance: 50,
    price: 45,
    imageUrl:
    'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
  ),
];