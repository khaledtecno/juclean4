/*@JS()
library google_maps;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

// Define the JavaScript function we'll call
@JS('initGoogleMaps')
external dynamic _initGoogleMaps(String apiKey);

// Represents the Google Maps Places Autocomplete class
@JS('google.maps.places.Autocomplete')
class Autocomplete {
  external Autocomplete(dynamic inputField, dynamic options);
  external dynamic getPlace();
}

Future<void> initializeGoogleMaps() async {
  if (!kIsWeb) return;

  try {
    // Call the initialization function and wait for it to complete
    await js_util.promiseToFuture<void>(_initGoogleMaps('YOUR_API_KEY'));
    print('Google Maps initialized successfully');
  } catch (e) {
    print('Error initializing Google Maps: $e');
    throw Exception('Failed to initialize Google Maps');
  }
}

Future<void> showPlaceAutocomplete({
  required Function(LatLng location, String address) onPlaceSelected,
}) async {
  if (!kIsWeb) return;

  await initializeGoogleMaps();

  // Create an input element for the autocomplete
  final inputField = html.document.createElement('input')
    ..id = 'pac-input'
    ..className = 'controls'
    ..setAttribute('type', 'text')
    ..setAttribute('placeholder', 'Search for places');

  // Add it to the DOM
  html.document.body?.append(inputField);

  // Create the autocomplete
  final autocomplete = Autocomplete(
      inputField,
      js_util.jsify({
        'types': ['geocode'],
        'componentRestrictions': {'country': 'de'}
      })
  );//

  // Listen for place changes
  js_util.setProperty(inputField, 'onplacechanged', allowInterop((_) {
    final place = autocomplete.getPlace();
    if (place != null && place['geometry'] != null) {
      final location = place['geometry']['location'];
      final lat = location.lat();
      final lng = location.lng();
      onPlaceSelected(LatLng(lat, lng), place['formatted_address']);
    }
    inputField.remove();
  }));
}*/