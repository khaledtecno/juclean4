import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../FastTranslationService.dart';
import 'service.dart';
import 'service_repository.dart';
import 'image_upload_service.dart';
import 'add_service_page.dart';

class ServicesListPage extends StatefulWidget {
  final ServiceRepository serviceRepository;
  final ImageUploadService imageUploadService;

  const ServicesListPage({
    Key? key,
    required this.serviceRepository,
    required this.imageUploadService,
  }) : super(key: key);

  @override
  State<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends State<ServicesListPage> {
  late Future<List<Service>> _servicesFuture;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _servicesFuture = widget.serviceRepository.getServices();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMoreServices() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoadingMore = false);
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      _loadMoreServices();
    }
  }

  void _refreshServices() {
    setState(() {
      _servicesFuture = widget.serviceRepository.getServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title:  translatedtranslatedText('LUXURY SERVICES',
            style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 22,
                letterSpacing: 2.0)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () => _navigateToAddService(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _refreshServices,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: FutureBuilder<List<Service>>(
          future: _servicesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                  ));
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.black54),
                    const SizedBox(height: 24),

                     translatedtranslatedText('Failed to load services',
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w300)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _refreshServices,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        elevation: 2,
                      ),
                      child:
                      translatedtranslatedText('RETRY',
                          style: TextStyle(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w300)),
                    ),
                  ],
                ),
              );
            }
            final services = snapshot.data ?? [];
            if (services.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_mosaic,
                        size: 64, color: Colors.black26),
                    const SizedBox(height: 24),

                     translatedtranslatedText('NO SERVICES FOUND',
                        style: TextStyle(
                            color: Colors.black45,
                            fontSize: 14,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w300)),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddService(),
                      icon: const Icon(Icons.add, size: 18),
                      label:
                      translatedtranslatedText('ADD SERVICE',
                          style: TextStyle(letterSpacing: 1.2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              );
            }
            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(context),
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: _getChildAspectRatio(context),
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        if (index < services.length) {
                          return _buildLuxuryServiceCard(services[index]);
                        } else {
                          return _buildLoadingIndicator();
                        }
                      },
                      childCount:
                      services.length + (_isLoadingMore ? 1 : 0),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLuxuryServiceCard(Service service) {
    return InkWell(
      onTap: () => _navigateToEditService(service),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              _buildServiceImage(service),
              _buildServiceContent(service),
              _buildFavoriteButton(),
              _buildDeleteButton(service),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceImage(Service service) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth;
        final imageHeight = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Image with proper aspect ratio handling
            ClipRRect(
              borderRadius: BorderRadius.circular(12), // Optional rounded corners
              child: _buildResponsiveImage(service.imgurl),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), // Match image radius
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: [0.5, 1.0], // Adjust gradient stops for better effect
                ),
              ),
            ),

            // Optional: Add a shimmer effect while loading

          ],
        );
      },
    );
  }

  Widget _buildResponsiveImage(String imageUrl) {
    return Image.network(
      _getFormattedImageUrl(imageUrl),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                translatedtranslatedText('Image not available',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFormattedImageUrl(String url) {
    if (url.isEmpty) return '';

    if (kIsWeb && !url.startsWith('http')) {
      // Format for web if needed
      return 'https://firebasestorage.googleapis.com/v0/b/YOUR-PROJECT-ID.appspot.com/o/${Uri.encodeComponent(url)}?alt=media';
    }
    return url;
  }

  Widget _buildServiceContent(Service service) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            translatedtranslatedText(
              service.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.favorite_border,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(Service service) {
    return Positioned(
      bottom: 12,
      right: 12,
      child: IconButton(
        onPressed: () => _showDeleteDialog(service),
        icon: const Icon(Icons.delete, color: Colors.white),
        tooltip: 'Delete Service',
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
        ),
      ),
    );
  }

  void _navigateToAddService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServicePage(
          serviceRepository: widget.serviceRepository,
          imageUploadService: widget.imageUploadService,
        ),
      ),
    ).then((_) => _refreshServices());
  }

  void _navigateToEditService(Service service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServicePage(
          service: service,
          serviceRepository: widget.serviceRepository,
          imageUploadService: widget.imageUploadService,
        ),
      ),
    ).then((_) => _refreshServices());
  }

  Future<void> _showDeleteDialog(Service service) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  translatedtranslatedText('Delete Service'),
          content: SingleChildScrollView(
            child: ListBody(
              children:  <Widget>[
                translatedtranslatedText('Are you sure you want to delete this service?'),
                SizedBox(height: 8),
                translatedtranslatedText('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child:  translatedtranslatedText('Cancel', style: TextStyle(color: Colors.black54)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child:  translatedtranslatedText('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteService(service);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteService(Service service) async {
    try {
      // Delete the image first


      // Then delete the service
      await widget.serviceRepository.deleteService(service.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: translatedtranslatedText('Service deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshServices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: translatedtranslatedText('Failed to delete service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  double _getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 0.9;
    if (width > 900) return 0.85;
    if (width > 600) return 0.8;
    return 0.75;
  }
}