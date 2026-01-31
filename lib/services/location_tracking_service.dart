import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:copmap_flutter/services/database_service.dart';

class LocationTrackingService {
  final DatabaseService _db = DatabaseService();
  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<LatLng> _locationController =
      StreamController<LatLng>.broadcast();
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  Stream<LatLng> get locationStream => _locationController.stream;

  /// Check and request location permissions
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse ||
          result == LocationPermission.always;
    } else if (permission == LocationPermission.deniedForever) {
      // Open app settings
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  /// Open app settings for location permissions
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Start tracking officer location in real-time
  Future<void> startTracking(
    String officerId, {
    bool permissionAlreadyGranted = false,
  }) async {
    if (_isTracking) return;

    if (!permissionAlreadyGranted) {
      // Request permission first
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }
    }

    _isTracking = true;

    // Use high accuracy, update every 10 seconds or 5 meters distance change
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // Update every 5 meters
          ),
        ).listen(
          (Position position) async {
            final latLng = LatLng(position.latitude, position.longitude);
            try {
              _locationController.add(latLng);
              await _db.updateOfficerLocation(officerId, latLng);
              print(
                'Location updated: ${position.latitude}, ${position.longitude}',
              );
            } catch (e) {
              print('Error updating location: $e');
            }
          },
          onError: (e) {
            print('Location stream error: $e');
            _isTracking = false;
          },
        );
  }

  /// Stop tracking officer location
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
  }

  /// Get current position once
  Future<LatLng?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get battery percentage
  Future<int> getBatteryPercentage() async {
    try {
      // Note: Battery level would need a separate package like battery_plus
      // This is a placeholder - you'd use battery_plus package for actual implementation
      return 100; // Placeholder
    } catch (e) {
      return 0;
    }
  }

  /// Cleanup
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
