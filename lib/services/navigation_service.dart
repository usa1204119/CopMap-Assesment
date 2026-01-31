import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class NavigationService {
  /// Open Google Maps with walking directions from current location to destination
  Future<void> openGoogleMapsNavigation({
    required LatLng destination,
    String? destinationLabel,
  }) async {
    try {
      // Get current location
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final origin = '${currentPosition.latitude},${currentPosition.longitude}';
      final dest = '${destination.latitude},${destination.longitude}';

      // Create Google Maps URL for walking directions
      final params = <String, String>{
        'api': '1',
        'origin': origin,
        'destination': dest,
        'travelmode': 'walking',
      };

      final uri = Uri.https('www.google.com', '/maps/dir/', params);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      throw Exception('Failed to open navigation: $e');
    }
  }

  /// Open Google Maps showing the route between two points
  Future<void> showRouteInGoogleMaps({
    required LatLng origin,
    required LatLng destination,
    String? originLabel,
    String? destinationLabel,
  }) async {
    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';

      // Create Google Maps URL to show route
      final params = <String, String>{
        'api': '1',
        'origin': originStr,
        'destination': destStr,
        'travelmode': 'walking',
      };

      final uri = Uri.https('www.google.com', '/maps/dir/', params);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      throw Exception('Failed to show route: $e');
    }
  }

  /// Open Google Maps at specific location
  Future<void> openLocationInGoogleMaps({
    required LatLng location,
    String? label,
    int zoom = 15,
  }) async {
    try {
      final query = label?.trim().isNotEmpty == true
          ? label!.trim()
          : '${location.latitude},${location.longitude}';

      final uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': query,
        'zoom': zoom.toString(),
      });

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      throw Exception('Failed to open location: $e');
    }
  }
}
