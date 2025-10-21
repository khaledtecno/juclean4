// lib/services/mobile_places_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:juclean/js_interop/places_service.dart';

class MobilePlacesService implements PlacesService {
  static const String _apiKey = 'AIzaSyAL9E3CEvdhlTAwN2oE2ROH1G6UgmPZ4Mk'; // Replace with your key
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  @override
  Future<List<Map<String, dynamic>>> getAutocomplete(String input) async {
    if (input.length < 3) return [];

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/autocomplete/json?'
                'input=$input'
                '&types=address'
                '&components=country:de'
                '&key=$_apiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List).map((p) => {
            'description': p['description'] ?? '',
            'place_id': p['place_id'] ?? '',
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Autocomplete error: $e");
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/details/json?'
                'place_id=$placeId'
                '&fields=formatted_address,geometry'
                '&key=$_apiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];
          return {
            'address': result['formatted_address'] ?? '',
            'latitude': location['lat']?.toDouble() ?? 0.0,
            'longitude': location['lng']?.toDouble() ?? 0.0,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint("Place details error: $e");
      return null;
    }
  }
}