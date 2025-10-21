/*import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:universal_html/html.dart' as html;

@JS('google.maps.places.AutocompleteService')
class AutocompleteService {
  external factory AutocompleteService();
  external void getPlacePredictions(
      dynamic request, void Function(List<dynamic>?, String?) callback);
}

@JS('google.maps.places.PlacesService')
class PlacesServiceJS {
  external factory PlacesServiceJS(html.Element attrContainer);
  external void getDetails(dynamic request, void Function(dynamic, String) callback);
}

class PlacesService {
  static Completer<void>? _initCompleter;

  static Future<void> ensureInitialized() async {
    if (!kIsWeb) return;

    if (_initCompleter != null) {
      if (_initCompleter!.isCompleted) return;
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      final promise = js_util.getProperty(html.window, 'googleMapsReady');
      await js_util.promiseToFuture(promise);
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAutocomplete(String input) async {
    if (!kIsWeb || input.length < 3) return [];

    await ensureInitialized();

    final completer = Completer<List<Map<String, dynamic>>>();
    final service = AutocompleteService(); // Corrected here

    service.getPlacePredictions(
      js_util.jsify({
        'input': input,
        'componentRestrictions': {'country': 'de'},
        'types': ['address'],
      }),
      allowInterop((List<dynamic>? predictions, String? status) {
        if (status == 'OK' && predictions != null && predictions.isNotEmpty) {
          final List<Map<String, dynamic>> results = [];

          for (var pred in predictions) {
            final description = js_util.getProperty(pred, 'description');
            final placeId = js_util.getProperty(pred, 'place_id');

            results.add({
              'description': description ?? '',
              'place_id': placeId ?? '',
            });
          }

          completer.complete(results);
        } else {
          completer.complete([]);
        }
      }),
    );

    return completer.future.timeout(const Duration(seconds: 5), onTimeout: () => []);
  }

  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (!kIsWeb) return null;

    await ensureInitialized();

    try {
      final googleObj = js_util.getProperty(html.window, 'google');
      final mapsObj = js_util.getProperty(googleObj, 'maps');
      final placesObj = js_util.getProperty(mapsObj, 'places');

      final service = js_util.callConstructor(
        js_util.getProperty(placesObj, 'PlacesService'),
        [html.document.createElement('div')],
      );

      final completer = Completer<Map<String, dynamic>?>();

      js_util.callMethod(service, 'getDetails', [
        js_util.jsify({
          'placeId': placeId,
          'fields': ['formatted_address', 'geometry']
        }),
        allowInterop((dynamic place, String status) {
          if (status == 'OK' && place != null) {
            final formattedAddress = js_util.getProperty(place, 'formatted_address');
            final geometry = js_util.getProperty(place, 'geometry');
            final location = geometry != null ? js_util.getProperty(geometry, 'location') : null;

            final lat = location != null ? js_util.callMethod(location, 'lat', []) : null;
            final lng = location != null ? js_util.callMethod(location, 'lng', []) : null;

            completer.complete({
              'address': formattedAddress ?? '',
              'latitude': lat?.toDouble() ?? 0.0,
              'longitude': lng?.toDouble() ?? 0.0,
            });
          } else {
            completer.complete(null);
          }
        }),
      ]);

      return completer.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
    } catch (e, stackTrace) {
      print("Error in getPlaceDetails: $e\n$stackTrace");
      return null;
    }
  }
}*/// lib/services/places_service.dart
import 'package:flutter/foundation.dart';

import 'MobilePlaces.dart';

abstract class PlacesService {
  static MobilePlacesService get instance {
   // if (kIsWeb) return WebPlacesService();
    return MobilePlacesService();
  }

  Future<List<Map<String, dynamic>>> getAutocomplete(String input);
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId);
}