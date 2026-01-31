import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:copmap_flutter/models/officer.dart';
import 'package:copmap_flutter/models/duty.dart';
import 'package:copmap_flutter/services/location_tracking_service.dart';
import 'package:copmap_flutter/services/database_service.dart';
import 'package:copmap_flutter/services/navigation_service.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import 'dart:math' as math;

class OfficerTrackingScreen extends StatefulWidget {
  final String officerId;
  final Officer officer;

  const OfficerTrackingScreen({
    super.key,
    required this.officerId,
    required this.officer,
  });

  @override
  State<OfficerTrackingScreen> createState() => _OfficerTrackingScreenState();
}

class _OfficerTrackingScreenState extends State<OfficerTrackingScreen> {
  final LocationTrackingService _locationService = LocationTrackingService();
  final DatabaseService _db = DatabaseService();
  final NavigationService _navigationService = NavigationService();
  final Completer<GoogleMapController> _mapController = Completer();
  StreamSubscription<LatLng>? _locationSubscription;
  StreamSubscription<List<Duty>>? _dutySubscription;
  bool _isTrackingActive = false;
  String _trackingStatus = 'Requesting location permission...';
  LatLng _currentLocation = const LatLng(
    28.6139,
    77.2090,
  ); // Default: New Delhi
  LatLng? _destinationLocation; // Assigned duty location
  Duty? _activeDuty;
  List<Duty> _assignedDuties = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoadingDuties = true;
  bool _isGettingLocation = true;

  @override
  void initState() {
    super.initState();
    _initializeUserLocation();
    _loadAssignedDuties();
  }

  Future<void> _initializeUserLocation() async {
    try {
      setState(() {
        _isGettingLocation = true;
        _trackingStatus = 'Requesting location permission...';
      });

      // Request location permission first
      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          _showLocationPermissionDialog();
        }
        return;
      }

      setState(() {
        _trackingStatus = 'Getting your current location...';
      });

      // Get current location once (initial)
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentLocation = position;
        });

        _updateMapMarkers();

        // Start live tracking immediately so Firestore officer location stays updated
        await _locationService.startTracking(
          widget.officerId,
          permissionAlreadyGranted: true,
        );

        _locationSubscription?.cancel();
        _locationSubscription = _locationService.locationStream.listen((
          latLng,
        ) {
          if (!mounted) return;
          setState(() {
            _currentLocation = latLng;
            _isTrackingActive = true;
            _isGettingLocation = false;
            _trackingStatus = 'Live location enabled';
          });
          _updateMapMarkers();
          _updateMapToShowRoute();
        });

        // Move map to current location with appropriate zoom
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation, 16),
        );

        // Show success message briefly
        _showLocationSuccessMessage();
      } else {
        setState(() {
          _isGettingLocation = false;
          _trackingStatus = 'Unable to get location';
        });
      }
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
        _trackingStatus = 'Location error: ${e.toString()}';
      });
    }
  }

  void _showLocationSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Location access granted'),
        backgroundColor: AppTheme.statusActive,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.card,
          title: const Text(
            'Location Permission Required',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'CopMap needs location permission to track your location and show routes to assigned duty areas. Please enable location access in settings.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isGettingLocation = false;
                  _trackingStatus = 'Location permission denied';
                });
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Open app settings
                await _locationService.openAppSettings();
                // Retry after settings
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    _initializeUserLocation();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _loadAssignedDuties() {
    _dutySubscription?.cancel();
    _dutySubscription = _db.getOfficerDutiesStream(widget.officerId).listen((
      duties,
    ) {
      if (!mounted) return;

      // Keep list for backward compatibility, but destination uses nearest duty
      final nextDuty = duties.isNotEmpty ? duties.first : null;

      setState(() {
        _assignedDuties = duties;
        _activeDuty = nextDuty;
        _destinationLocation =
            (nextDuty?.latitude != null && nextDuty?.longitude != null)
            ? LatLng(nextDuty!.latitude!, nextDuty.longitude!)
            : null;
        _isLoadingDuties = false;
      });
      _updateMapMarkers();
      _updateMapToShowRoute();
    });
  }

  void _updateMapToShowRoute() async {
    // If we have both current location and destination, show route
    if (_destinationLocation != null) {
      final controller = await _mapController.future;

      // Create bounds to show both current location and destination
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(_currentLocation.latitude, _destinationLocation!.latitude),
          math.min(_currentLocation.longitude, _destinationLocation!.longitude),
        ),
        northeast: LatLng(
          math.max(_currentLocation.latitude, _destinationLocation!.latitude),
          math.max(_currentLocation.longitude, _destinationLocation!.longitude),
        ),
      );

      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  void _updateMapMarkers() {
    final Set<Marker> newMarkers = {};
    final Set<Polyline> newPolylines = {};

    // Add current location marker (Starting Point)
    newMarkers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation,
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: 'Starting Point',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Add destination marker (Assigned Duty Location)
    if (_destinationLocation != null && _activeDuty != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination_location'),
          position: _destinationLocation!,
          infoWindow: InfoWindow(
            title: 'Duty Location',
            snippet: _activeDuty!.area,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Add route polyline from current location to destination
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_destination'),
          points: [_currentLocation, _destinationLocation!],
          color: AppTheme.primary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    // Add other assigned duty locations (additional markers)
    // (intentionally not shown to keep UI clean)

    setState(() {
      _markers = newMarkers;
      _polylines = newPolylines;
    });
  }

  Future<void> _toggleTracking() async {
    try {
      if (_isTrackingActive) {
        await _locationService.stopTracking();
        setState(() {
          _isTrackingActive = false;
          _trackingStatus = 'Tracking stopped';
        });
      } else {
        await _locationService.startTracking(widget.officerId);
        setState(() {
          _isTrackingActive = true;
          _trackingStatus = 'Actively tracking...';
        });
      }
    } catch (e) {
      setState(() => _trackingStatus = 'Error: ${e.toString()}');
    }
  }

  Future<void> _goToMyLocation() async {
    if (_isGettingLocation) {
      await _initializeUserLocation();
    }
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 16));
  }

  Future<void> _navigateToDutyLocation() async {
    if (_destinationLocation != null) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_destinationLocation!, 16),
      );
    }
  }

  Future<void> _openGoogleMapsNavigation() async {
    if (_destinationLocation != null && _activeDuty != null) {
      try {
        await _navigationService.openGoogleMapsNavigation(
          destination: _destinationLocation!,
          destinationLabel: _activeDuty!.area,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open navigation: $e'),
              backgroundColor: AppTheme.statusOffline,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRouteInGoogleMaps() async {
    if (_destinationLocation != null && _activeDuty != null) {
      try {
        await _navigationService.showRouteInGoogleMaps(
          origin: _currentLocation,
          destination: _destinationLocation!,
          originLabel: 'Your Location',
          destinationLabel: _activeDuty!.area,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to show route: $e'),
              backgroundColor: AppTheme.statusOffline,
            ),
          );
        }
      }
    }
  }

  Future<void> _openCurrentLocationInGoogleMaps() async {
    try {
      await _navigationService.openLocationInGoogleMaps(
        location: _currentLocation,
        label: 'Your Current Location',
        zoom: 18,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open location: $e'),
            backgroundColor: AppTheme.statusOffline,
          ),
        );
      }
    }
  }

  Future<void> _showAllDuties() async {
    if (_markers.isNotEmpty) {
      final controller = await _mapController.future;
      final bounds = _boundsFromMarkers(_markers);
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  Future<void> _showRouteOverview() async {
    if (_destinationLocation != null) {
      final controller = await _mapController.future;

      // Create bounds to show both current location and destination
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(_currentLocation.latitude, _destinationLocation!.latitude),
          math.min(_currentLocation.longitude, _destinationLocation!.longitude),
        ),
        northeast: LatLng(
          math.max(_currentLocation.latitude, _destinationLocation!.latitude),
          math.max(_currentLocation.longitude, _destinationLocation!.longitude),
        ),
      );

      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  LatLngBounds _boundsFromMarkers(Set<Marker> markers) {
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _dutySubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),

          // Top Info Card with Duty Information
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.card.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _isTrackingActive
                                ? AppTheme.statusActive
                                : AppTheme.statusWarning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _trackingStatus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isLoadingDuties)
                      const Text(
                        'Loading assigned location…',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    else if (_activeDuty != null)
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _activeDuty!.area,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'No assigned location',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Navigation Buttons Row
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.card.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_activeDuty != null)
                        Text(
                          _activeDuty!.area,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        )
                      else
                        const Text(
                          'No duty assigned yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isGettingLocation
                                  ? null
                                  : _updateMapToShowRoute,
                              icon: const Icon(LucideIcons.crosshair, size: 18),
                              label: const Text('Center Route'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_destinationLocation != null &&
                                      !_isGettingLocation)
                                  ? _openGoogleMapsNavigation
                                  : null,
                              icon: const Icon(
                                LucideIcons.navigation,
                                size: 18,
                              ),
                              label: const Text('Navigate'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_trackingStatus.contains('permission denied') ||
                          _trackingStatus.contains('Location error')) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _initializeUserLocation,
                            icon: const Icon(LucideIcons.refreshCw, size: 18),
                            label: const Text('Retry Location'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AppTheme.secondary),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Duty Count Badge
          if (false && _assignedDuties.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.card.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.secondary),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_assignedDuties.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Text(
                      'Assigned\nDuties',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
