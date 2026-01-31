import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class Suggestion {
  final String placeId;
  final String description;

  Suggestion(this.placeId, this.description);

  @override
  String toString() {
    return 'Suggestion(description: $description, placeId: $placeId)';
  }
}

class LocationService {
  final String apiKey;
  final String sessionToken;

  LocationService(this.apiKey) : sessionToken = const Uuid().v4();

  Future<List<Suggestion>> fetchSuggestions(String input) async {
    if (input.isEmpty) return [];

    final encodedInput = Uri.encodeComponent(input);
    final baseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedInput&key=$apiKey&sessiontoken=$sessionToken';
    
    // On Web, direct REST calls to Google Maps are blocked by CORS.
    // Using corsproxy.io as it's typically more reliable for dev than cors-anywhere.
    final finalUrl = kIsWeb 
        ? 'https://corsproxy.io/?${Uri.encodeComponent(baseUrl)}'
        : baseUrl;

    final url = Uri.parse(finalUrl);
    
    try {
      print('LocationService: Fetching from: $finalUrl');
      final response = await http.get(url);
      print('LocationService: HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('LocationService response status: ${result['status']}');
        
        if (result['status'] == 'OK') {
          return result['predictions']
              .map<Suggestion>((p) => Suggestion(p['place_id'], p['description']))
              .toList();
        }
        if (result['status'] == 'ZERO_RESULTS') {
          return [];
        }
        
        final errorMessage = result['error_message'] ?? 'Status: ${result['status']}';
        print('LocationService API Error: $errorMessage');
        throw Exception(errorMessage);
      } else {
        print('LocationService HTTP Error: ${response.body}');
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      print('LocationService Exception: $e');
      rethrow;
    }
  }

  Future<Map<String, double>> getLatLng(String placeId) async {
    final baseUrl = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey&sessiontoken=$sessionToken';
    
    final finalUrl = kIsWeb 
        ? 'https://corsproxy.io/?${Uri.encodeComponent(baseUrl)}'
        : baseUrl;

    final url = Uri.parse(finalUrl);

    try {
      print('LocationService: Fetching LatLng from: $finalUrl');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          final lat = result['result']['geometry']['location']['lat'];
          final lng = result['result']['geometry']['location']['lng'];
          return {'lat': lat, 'lng': lng};
        }
        throw Exception(result['error_message'] ?? 'Status: ${result['status']}');
      } else {
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      print('LocationService LatLng Exception: $e');
      rethrow;
    }
  }
}
