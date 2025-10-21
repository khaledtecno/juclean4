//import 'dart:html' as html;
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';


import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(XFile imageFile, String serviceId) async {
    try {
      if (kIsWeb) {
        // Handle web upload
        final bytes = await imageFile.readAsBytes();
        return await _uploadBytes(bytes, serviceId);
      } else {
        // Handle mobile upload
        final file = File(imageFile.path);
        return await _uploadFile(file, serviceId);
      }
    } catch (e) {
      throw Exception('Image upload failed: ${e.toString()}');
    }
  }

  Future<String> _uploadBytes(Uint8List bytes, String serviceId) async {
    final path = 'service_images/$serviceId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl: 'public, max-age=31536000',
    );

    final uploadTask = _storage.ref(path).putData(bytes, metadata);
    return await _monitorUpload(uploadTask);
  }

  Future<String> _uploadFile(File file, String serviceId) async {
    final path = 'service_images/$serviceId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl: 'public, max-age=31536000',
    );

    final uploadTask = _storage.ref(path).putFile(file, metadata);
    return await _monitorUpload(uploadTask);
  }

  Future<String> _monitorUpload(UploadTask uploadTask) async {
    uploadTask.snapshotEvents.listen((snapshot) {
      final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      debugPrint('Upload progress: ${progress.toString()}%');
    });

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }








  static Widget buildNetworkImage(
      String imageUrl, {
        double? width,
        double? height,
        BoxFit fit = BoxFit.cover,
        Widget? placeholder,
        Widget? errorWidget,
      }) {
    final cleanUrl = _cleanImageUrl(imageUrl);

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _defaultErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 300),
      memCacheWidth: (width != null && width < 1000) ? width.toInt() : 1000,
      httpHeaders: const {'Cache-Control': 'max-age=86400'},
    );
  }

  static String _cleanImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.queryParameters['alt'] == 'media') {
        return url;
      }
      return '${uri.origin}${uri.path}?alt=media';
    } catch (e) {
      return url;
    }
  }

  static Widget _defaultPlaceholder() => Center(
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation(Colors.white70),
    ),
  );

  static Widget _defaultErrorWidget() => Container(
    color: Colors.grey[100],
    child: Center(
      child: Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
    ),
  );
}