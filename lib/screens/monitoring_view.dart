import 'dart:async';
import 'dart:math' show cos, sin, sqrt, min, max, asin;
import 'dart:ui' as ui;
import 'package:copmap_flutter/models/duty.dart';
import 'package:copmap_flutter/models/officer.dart';
import 'package:copmap_flutter/services/database_service.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MonitoringView extends StatefulWidget {
  const MonitoringView({super.key});

  @override
  State<MonitoringView> createState() => _MonitoringViewState();
}

class _MonitoringViewState extends State<MonitoringView> {
  final Completer<GoogleMapController> _controller = Completer();
  final DatabaseService _db = DatabaseService();

  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  Set<Polygon> _polygons = {};
  final Map<String, double> _distances = {}; // Officer ID -> distance to duty
  bool _showRoutes = true;

  static const CameraPosition _kStationCenter = CameraPosition(
    target: LatLng(28.6139, 77.2090), // New Delhi Example
    zoom: 14.4746,
  );

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a =
        0.5 -
        cos((point2.latitude - point1.latitude) * p) / 2 +
        cos(point1.latitude * p) *
            cos(point2.latitude * p) *
            (1 - cos((point2.longitude - point1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Get list of intermediate points for polyline (simplified straight line)
  List<LatLng> _getPolylinePoints(LatLng from, LatLng to) {
    return [from, to];
  }

  /// Create a colored circle polygon for duty area
  Set<Polygon> _createDutyPolygons(List<Duty> duties) {
    Set<Polygon> polygons = {};

    for (int i = 0; i < duties.length; i++) {
      final duty = duties[i];
      if (duty.latitude != null && duty.longitude != null) {
        // Create circle polygon (approximate with 12 points)
        const double radiusInKm = 0.5; // 500 meters radius for duty area
        const double radiusInDegrees = radiusInKm / 111.0;

        List<LatLng> points = [];
        for (int j = 0; j < 12; j++) {
          final angle = (j * 360 / 12) * (3.14159 / 180);
          final dx = radiusInDegrees * cos(angle);
          final dy = radiusInDegrees * sin(angle);

          points.add(LatLng(duty.latitude! + dy, duty.longitude! + dx));
        }

        polygons.add(
          Polygon(
            polygonId: PolygonId('duty_area_${duty.id}'),
            points: points,
            fillColor: Colors.blue.withOpacity(0.2),
            strokeColor: Colors.blue,
            strokeWidth: 2,
            geodesic: true,
          ),
        );
      }
    }

    return polygons;
  }

  /// Build polylines showing officer to duty location routes
  Set<Polyline> _createRoutePolylines(
    List<Officer> officers,
    List<Duty> duties,
  ) {
    Set<Polyline> polylines = {};

    if (!_showRoutes || duties.isEmpty) return polylines;

    for (var officer in officers) {
      // Find duty assigned to this officer
      final assignedDuty = duties.firstWhere(
        (d) => d.assignedOfficerIds.contains(officer.id),
        orElse: () => duties.first,
      );

      if (assignedDuty.latitude != null && assignedDuty.longitude != null) {
        final dutyLocation = LatLng(
          assignedDuty.latitude!,
          assignedDuty.longitude!,
        );
        final officerLocation = officer.location;

        // Calculate distance
        final distance = _calculateDistance(officerLocation, dutyLocation);
        _distances[officer.id] = distance;

        // Create polyline from officer to duty
        final Color routeColor = officer.status == OfficerStatus.active
            ? Colors.green
            : officer.status == OfficerStatus.issue
            ? Colors.orange
            : Colors.red;

        polylines.add(
          Polyline(
            polylineId: PolylineId('route_${officer.id}'),
            points: _getPolylinePoints(officerLocation, dutyLocation),
            color: routeColor.withOpacity(0.7),
            width: 3,
            geodesic: true,
          ),
        );
      }
    }

    return polylines;
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(
    String title,
    Color color,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double width = 150.0;
    const double height = 100.0;

    // Background for name tag
    final Paint paint = Paint()..color = color;
    const Radius radius = Radius.circular(8.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.0, 0.0, width, 40.0),
        radius,
      ),
      paint,
    );

    // Text for name tag
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: title,
      style: const TextStyle(
        fontSize: 18.0,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset((width - painter.width) / 2, (40.0 - painter.height) / 2),
    );

    // Marker pin
    final Paint pinPaint = Paint()..color = color;
    final Path path = Path();
    path.moveTo(width / 2 - 10, 40);
    path.lineTo(width / 2 + 10, 40);
    path.lineTo(width / 2, 60);
    path.close();
    canvas.drawPath(path, pinPaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Auto-zoom map to show all field officers with optimal zoom
  Future<void> _autoZoomToOfficers(List<Officer> officers) async {
    if (officers.isEmpty) return;

    if (officers.length == 1) {
      // Single officer - zoom in
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: officers.first.location, zoom: 17.0),
        ),
      );
    } else {
      // Multiple officers - calculate bounds
      double minLat = officers.first.location.latitude;
      double maxLat = officers.first.location.latitude;
      double minLng = officers.first.location.longitude;
      double maxLng = officers.first.location.longitude;

      for (var officer in officers) {
        minLat = min(minLat, officer.location.latitude);
        maxLat = max(maxLat, officer.location.latitude);
        minLng = min(minLng, officer.location.longitude);
        maxLng = max(maxLng, officer.location.longitude);
      }

      // Add padding
      final padding = 0.01;
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;

      // Fit bounds with animation
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100, // padding
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Officer>>(
      stream: _db.getOfficersStream(),
      builder: (context, officerSnapshot) {
        return StreamBuilder<List<Duty>>(
          stream: _db.getActiveDutiesStream(),
          builder: (context, dutySnapshot) {
            if (officerSnapshot.connectionState == ConnectionState.waiting ||
                dutySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final officers = officerSnapshot.data ?? [];
            final duties = dutySnapshot.data ?? [];

            return FutureBuilder<Set<Marker>>(
              future: _combineMarkers(officers, duties),
              builder: (context, markerSnapshot) {
                final markers = markerSnapshot.data ?? {};

                // Update polygons and polylines
                _polygons = _createDutyPolygons(duties);
                _polylines = _createRoutePolylines(officers, duties);

                return Scaffold(
                  body: Stack(
                    children: [
                      GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: _kStationCenter,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                          _mapController = controller;

                          // Auto-zoom to officers after map is ready
                          if (officers.isNotEmpty) {
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                _autoZoomToOfficers(officers);
                              },
                            );
                          }
                        },
                        markers: markers,
                        polylines: _polylines,
                        polygons: _polygons,
                      ),
                      _buildLegend(),
                      _buildStationOverlay(officers.length, duties.length),
                      _buildControls(),
                      _buildDistancePanel(officers, duties),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Set<Marker>> _combineMarkers(
    List<Officer> officers,
    List<Duty> duties,
  ) async {
    final Set<Marker> markers = {};

    // Duty Markers
    for (var duty in duties) {
      if (duty.latitude != null && duty.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('duty_${duty.id}'),
            position: LatLng(duty.latitude!, duty.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: duty.area,
              snippet:
                  '${duty.type.toString().split('.').last} Duty - ${_distances[duty.id]?.toStringAsFixed(2) ?? "0"} km',
            ),
          ),
        );
      }
    }

    // Officer Markers with Name Tags
    for (var officer in officers) {
      Color color;
      switch (officer.status) {
        case OfficerStatus.active:
          color = AppTheme.statusActive;
          break;
        case OfficerStatus.issue:
          color = AppTheme.statusWarning;
          break;
        case OfficerStatus.offline:
          color = AppTheme.statusOffline;
          break;
      }

      final customIcon = await _createCustomMarkerBitmap(officer.name, color);

      markers.add(
        Marker(
          markerId: MarkerId('officer_${officer.id}'),
          position: officer.location,
          icon: customIcon,
          infoWindow: InfoWindow(
            title: officer.name,
            snippet:
                '${officer.badge} - ${officer.status.toString().split('.').last}',
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildLegend() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.secondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendItem(color: AppTheme.statusActive, label: 'Officer Active'),
            const SizedBox(height: 8),
            _LegendItem(color: AppTheme.statusWarning, label: 'Officer Issue'),
            const SizedBox(height: 8),
            _LegendItem(
              color: AppTheme.statusOffline,
              label: 'Officer Offline',
            ),
            const SizedBox(height: 8),
            _LegendItem(color: Colors.blue, label: 'Duty Location'),
            const SizedBox(height: 8),
            _LegendItem(
              color: Colors.blue.withOpacity(0.3),
              label: 'Duty Area (500m)',
            ),
            const SizedBox(height: 8),
            _LegendItem(color: Colors.green, label: 'Active Route'),
            const SizedBox(height: 8),
            _LegendItem(color: Colors.orange, label: 'Issue Route'),
            const SizedBox(height: 8),
            _LegendItem(color: Colors.red, label: 'Offline Route'),
          ],
        ),
      ),
    );
  }

  Widget _buildStationOverlay(int officerCount, int dutyCount) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.secondary),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Monitoring - District A',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Officers: $officerCount | Duties: $dutyCount',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            backgroundColor: _showRoutes ? AppTheme.primary : Colors.grey,
            heroTag: 'routes_btn',
            mini: true,
            onPressed: () {
              setState(() {
                _showRoutes = !_showRoutes;
              });
            },
            child: Icon(
              _showRoutes ? Icons.route : Icons.route_outlined,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: AppTheme.primary,
            heroTag: 'refresh_btn',
            mini: true,
            onPressed: () {
              setState(() {});
            },
            child: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDistancePanel(List<Officer> officers, List<Duty> duties) {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.secondary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 300),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Distance to Assigned Duty',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Divider(height: 12),
              ...[
                for (var officer in officers)
                  if (_distances.containsKey(officer.id))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: officer.status == OfficerStatus.active
                                  ? AppTheme.statusActive
                                  : officer.status == OfficerStatus.issue
                                  ? AppTheme.statusWarning
                                  : AppTheme.statusOffline,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              officer.name,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_distances[officer.id]?.toStringAsFixed(2) ?? "0"} km',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
