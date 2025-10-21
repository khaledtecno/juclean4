import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:juclean/screens/Admin/NoticationPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:juclean/screens/Create%20account.dart';
import 'package:juclean/screens/Customer/DetailService.dart';
import 'package:juclean/screens/FastTranslationService.dart';
import 'package:juclean/screens/SignIn.dart';
// import 'dart:html' as html;
import 'dart:async';import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
//import 'package:js/js.dart';
//import 'package:js/js_util.dart' as js_util;
import 'package:juclean/services/FCM.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:universal_html/html.dart' as html;
import 'package:juclean/screens/Splash.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'main.dart';

class SplashWithDeepLinkHandler extends StatefulWidget {
  const SplashWithDeepLinkHandler({super.key});

  @override
  State<SplashWithDeepLinkHandler> createState() => _SplashWithDeepLinkHandlerState();
}

class _SplashWithDeepLinkHandlerState extends State<SplashWithDeepLinkHandler> {
  String? _deepLinkServiceId;
  bool _isCheckingDeepLink = true;

  @override
  void initState() {
    super.initState();
    _checkForDeepLinks();
  }

  Future<void> _checkForDeepLinks() async {
    try {
      // Use app_links to check for deep links
      final appLinks = AppLinks();
      final initialUri = await appLinks.getInitialAppLink();

      if (initialUri != null) {
        final serviceId = _extractServiceIdFromUri(initialUri);
        if (serviceId != null) {
          setState(() {
            _deepLinkServiceId = serviceId;
          });
          return;
        }
      }
    } catch (e) {
      print('Error checking deep links: $e');
    } finally {
      setState(() {
        _isCheckingDeepLink = false;
      });
    }
  }

  String? _extractServiceIdFromUri(Uri uri) {
    // Handle GitHub Pages links: https://khaledtecno.github.io/socialshop-links/service.html?id=123
    if (uri.scheme == 'https' &&
        uri.host == 'khaledtecno.github.io' &&
        uri.path.contains('/socialshop-links/service.html')) {

      return uri.queryParameters['id'];
    }
    // Handle custom scheme: juclean://service/123
    else if (uri.scheme == 'juclean' && uri.host == 'service') {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments[0];
      }
    }
    return null;
  }

  void _navigateToService(BuildContext context, String serviceId) {
    FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .get()
        .then((doc) {
      if (doc.exists) {
        final serviceData = doc.data() as Map<String, dynamic>;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Detailservice(
              name: serviceData['name'],
              description: serviceData['description'],
              price: serviceData['price'],
              imgurl: serviceData['imgurl'],
              id: serviceId,
              additional: serviceData['rooms'] ?? '',
              rooms: serviceData['additional'] ?? '',
            ),
          ),
        );
      } else {
        // If service not found, continue to normal splash flow
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GetStarted()),
        );
      }
    }).catchError((error) {
      print('Error fetching service: $error');
      // On error, continue to normal splash flow
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GetStarted()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we found a deep link and finished checking, navigate to service
    if (!_isCheckingDeepLink && _deepLinkServiceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToService(context, _deepLinkServiceId!);
      });
    }

    // If no deep link found or still checking, show normal splash screen
    if (_isCheckingDeepLink || _deepLinkServiceId == null) {
      return Splash();
    }

    // Show splash screen while processing
    return Splash();
  }
}