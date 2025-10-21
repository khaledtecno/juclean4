import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../FastTranslationService.dart';
import 'service.dart';
import 'service_repository.dart';
import 'image_upload_service.dart';

class AddServicePage extends StatefulWidget {
  final Service? service;
  final ServiceRepository serviceRepository;
  final ImageUploadService imageUploadService;

  const AddServicePage({
    Key? key,
    this.service,
    required this.serviceRepository,
    required this.imageUploadService,
  }) : super(key: key);

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late TextEditingController _popularController;
  late TextEditingController _roomsController;
  late TextEditingController _additionalController;

  dynamic _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descriptionController = TextEditingController(text: widget.service?.description ?? '');

    _popularController = TextEditingController(text: widget.service?.popular ?? 'true');
    _roomsController = TextEditingController(text: widget.service?.rooms ?? '');
    _additionalController = TextEditingController(text: widget.service?.additional ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();

    _popularController.dispose();
    _roomsController.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = kIsWeb ? pickedFile : File(pickedFile.path);
      });
    }
  }

  Widget _buildImageWidget() {
    if (_imageFile != null) {
      return kIsWeb
          ? _buildWebImagePreview()
          : Image.file(_imageFile as File, fit: BoxFit.cover);
    } else if (widget.service?.imgurl != null) {
      return ImageUploadService.buildNetworkImage(
        widget.service!.imgurl,
        fit: BoxFit.cover,
      );
    }
    return const Icon(Icons.image, size: 50, color: Colors.grey);
  }

  Widget _buildWebImagePreview() {
    return FutureBuilder<Uint8List>(
      future: _imageFile.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: translatedtranslatedText(widget.service == null ? 'Add New Service' : 'Edit Service'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Colors.teal.shade800, Colors.teal.shade600]
                  : [Colors.teal, Colors.tealAccent.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImageUploadSection(),
              const SizedBox(height: 30),
              _buildFormFields(theme),
              const SizedBox(height: 30),
              _buildSubmitButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(
              color: Colors.teal.shade200,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              children: [
                Positioned.fill(child: _buildImageWidget()),
                if (_imageFile == null && widget.service?.imgurl == null)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image, size: 50, color: Colors.grey.shade400),
                        translatedtranslatedText('No Image Selected',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.cloud_upload_outlined),
          label:  translatedtranslatedText('Upload Image'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(ThemeData theme) {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Service Name',
          icon: Icons.work_outline,
          theme: theme,
          validator: (value) => value!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          icon: Icons.description_outlined,
          theme: theme,
          maxLines: 3,
          validator: (value) => value!.isEmpty ? 'Required' : null,
        ),

        const SizedBox(height: 20),
        _buildTextField(
          controller: _popularController,
          label: 'Popular (true/false)',
          icon: Icons.star_outline,
          theme: theme,
          validator: _validatePopularField,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _roomsController,
          label: 'Rooms Included',
          icon: Icons.room_preferences_outlined,
          theme: theme,
          validator: (value) => value!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _additionalController,
          label: 'Additional Information',
          icon: Icons.info_outline,
          theme: theme,
          validator: (value) => value!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    required String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.primaryColor),
        prefixIcon: Icon(icon, color: theme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
    );
  }

  String? _validatePopularField(String? value) {
    if (value!.isEmpty) return 'Required';
    if (value != 'true' && value != 'false') {
      return 'Enter true or false';
    }
    return null;
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
          shadowColor: Colors.teal.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : translatedtranslatedText('SAVE SERVICE',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = await _createOrUpdateService();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: translatedtranslatedText('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Service> _createOrUpdateService() async {
    String? imageUrl;
    final serviceId = widget.service?.id ?? '';

    if (_imageFile != null) {
      imageUrl = await widget.imageUploadService.uploadImage(
        _imageFile,
        serviceId.isEmpty ? 'new_${DateTime.now().millisecondsSinceEpoch}' : serviceId,
      );
    } else {
      imageUrl = widget.service?.imgurl;
    }

    final service = Service(
      id: serviceId,
      name: _nameController.text,
      description: _descriptionController.text,
      price: '',
      popular: _popularController.text,
      imgurl: imageUrl ?? '',
      rooms: _roomsController.text,
      additional: _additionalController.text,
    );

    if (serviceId.isEmpty) {
      await widget.serviceRepository.addService(service);
    } else {
      await widget.serviceRepository.updateService(service);
    }

    return service;
  }
}