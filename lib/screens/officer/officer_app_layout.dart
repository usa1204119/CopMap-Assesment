import 'package:flutter/material.dart';
import 'package:copmap_flutter/models/officer.dart';
import 'package:copmap_flutter/screens/officer/officer_home_screen.dart';
import 'package:copmap_flutter/screens/officer/officer_tracking_screen.dart';
import 'package:copmap_flutter/screens/officer/officer_alerts_screen.dart';
import 'package:copmap_flutter/screens/officer/officer_profile_screen.dart';
import 'package:copmap_flutter/services/location_tracking_service.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OfficerAppLayout extends StatefulWidget {
  final String officerId;
  final Officer officer;

  const OfficerAppLayout({
    super.key,
    required this.officerId,
    required this.officer,
  });

  @override
  State<OfficerAppLayout> createState() => _OfficerAppLayoutState();
}

class _OfficerAppLayoutState extends State<OfficerAppLayout> {
  int _selectedIndex = 0;
  final LocationTrackingService _locationService = LocationTrackingService();
  bool _locationPermissionGranted = false;
  bool _permissionCheckInProgress = false;

  late final List<Widget> _screens = [
    OfficerHomeScreen(officerId: widget.officerId, officer: widget.officer),
    OfficerTrackingScreen(officerId: widget.officerId, officer: widget.officer),
    OfficerAlertsScreen(officerId: widget.officerId, officer: widget.officer),
    OfficerProfileScreen(officerId: widget.officerId, officer: widget.officer),
  ];

  @override
  void initState() {
    super.initState();
    _initializeBackgroundLocationTracking();
  }

  /// Initialize background location tracking for the officer
  ///
  /// This method:
  /// 1. Requests location permissions from the device
  /// 2. Starts GPS tracking via LocationTrackingService
  /// 3. Continuously updates officer's location in Firestore
  /// 4. Updates every 5 meters or when location changes significantly
  ///
  /// If permission is denied:
  /// - Shows a banner at the top suggesting to enable permissions
  /// - Provides "Enable Location" button to retry
  ///
  /// The location stream flows:
  /// Officer GPS → LocationTrackingService → DatabaseService.updateOfficerLocation()
  /// → Firestore → getOfficersStream() → Monitoring Map
  Future<void> _initializeBackgroundLocationTracking() async {
    if (_permissionCheckInProgress) return;

    setState(() => _permissionCheckInProgress = true);

    try {
      print('Requesting location permission...');

      // Request location permissions
      final hasPermission = await _locationService.requestLocationPermission();

      if (mounted) {
        setState(() {
          _locationPermissionGranted = hasPermission;
          _permissionCheckInProgress = false;
        });
      }

      if (!hasPermission) {
        print('❌ Location permission denied');
        if (mounted) {
          _showPermissionDeniedBanner();
        }
        return;
      }

      // Start background location tracking
      // Updates Firestore with live GPS coordinates every 5 meters
      await _locationService.startTracking(
        widget.officerId,
        permissionAlreadyGranted: true,
      );

      print(
        '✅ Background location tracking started for officer: ${widget.officerId}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Location tracking enabled'),
            backgroundColor: AppTheme.statusActive,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error starting background location tracking: $e');
      if (mounted) {
        setState(() => _permissionCheckInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: $e'),
            backgroundColor: AppTheme.statusWarning,
          ),
        );
      }
    }
  }

  /// Show banner when location permission is denied
  void _showPermissionDeniedBanner() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '⚠️  Location permission required for live tracking',
        ),
        backgroundColor: AppTheme.statusWarning,
        action: SnackBarAction(
          label: 'Enable',
          textColor: Colors.white,
          onPressed: () {
            print('User tapped Enable Location');
            _initializeBackgroundLocationTracking();
          },
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  /// Manual method to request location permission again
  Future<void> _requestLocationPermissionManually() async {
    print('Manual permission request triggered');
    await _initializeBackgroundLocationTracking();
  }

  @override
  void dispose() {
    // Stop location tracking when app is closed to save battery
    _locationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show permission status banner if permission not granted
      appBar: !_locationPermissionGranted
          ? AppBar(
              backgroundColor: AppTheme.statusWarning,
              elevation: 0,
              leading: const SizedBox(),
              leadingWidth: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                '📍 Location permission required for live tracking',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: _permissionCheckInProgress
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : TextButton(
                            onPressed: _requestLocationPermissionManually,
                            child: const Text(
                              'Enable Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            )
          : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.card,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.mapPin),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.bell),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
