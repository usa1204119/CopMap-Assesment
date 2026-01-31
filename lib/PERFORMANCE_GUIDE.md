// Performance Optimization Tips & Best Practices for CopMap Flutter

// 1. USE CONST CONSTRUCTORS EVERYWHERE
// ✅ GOOD - const reduces widget tree rebuilds
class MyWidget extends StatelessWidget {
  const MyWidget({super.key}); // Mark with const

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 16); // const for all widgets
  }
}

// ❌ BAD - non-const wastes memory
class MyWidget extends StatelessWidget {
  MyWidget({super.key}); // Missing const

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 16); // Rebuilds every time
  }
}

// ---

// 2. USE REPAINT BOUNDARIES FOR COMPLEX WIDGETS
// Prevents unnecessary repaints of expensive subtrees
RepaintBoundary(
  child: ComplexAnimationWidget(),
)

// ---

// 3. USE LAZY LOADING WITH STREAMBUILDER
// Don't load all data at once - use pagination

class DutyListView extends StatefulWidget {
  const DutyListView({super.key});

  @override
  State<DutyListView> createState() => _DutyListViewState();
}

class _DutyListViewState extends State<DutyListView> {
  static const int pageSize = 10;
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Duty>>(
      stream: _db.getDutiesPage(currentPage, pageSize),
      builder: (context, snapshot) {
        return ListView.builder(
          itemCount: snapshot.data?.length ?? 0,
          itemBuilder: (context, index) {
            // Load next page when user reaches 80% of list
            if (index == (snapshot.data?.length ?? 0) * 0.8) {
              currentPage++;
            }
            return DutyCard(duty: snapshot.data![index]);
          },
        );
      },
    );
  }
}

// ---

// 4. CACHE NETWORK IMAGES PROPERLY
// Use CachedNetworkImage instead of Image.network

import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: 'https://example.com/officer.jpg',
  placeholder: (context, url) => const CircleAvatar(
    backgroundColor: Colors.grey,
    child: Icon(Icons.person),
  ),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  cacheManager: CacheManager.instance,
  maxHeightDiskCache: 100,
  maxWidthDiskCache: 100,
)

// ---

// 5. USE SLIVERS FOR COMPLEX SCROLLING LAYOUTS
// Better performance than regular scroll view with many items

CustomScrollView(
  slivers: [
    SliverAppBar(
      title: const Text('Officers'),
      floating: true,
      snap: true,
    ),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => OfficerCard(officers[index]),
        childCount: officers.length,
      ),
    ),
  ],
)

// ---

// 6. USE CONST COLORS & DECORATIONS AT CLASS LEVEL
// Avoid recreating the same objects repeatedly

class AppTheme {
  // ✅ GOOD - Create once at top level
  static const Color primary = Color(0xFF6366F1);
  static const Color statusActive = Color(0xFF22C55E);
  
  static final _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
      ),
    ],
  );
}

// Use it:
Container(
  decoration: AppTheme._cardDecoration,
  child: Text('Officer Card'),
)

// ---

// 7. DISPOSE STREAMS AND TIMERS PROPERLY
// Prevent memory leaks

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late StreamSubscription _streamSub;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    
    _streamSub = _db.getOfficersStream().listen((officers) {
      setState(() => this.officers = officers);
    });

    _timer = Timer.periodic(Duration(seconds: 30), (_) {
      _updateUI();
    });
  }

  @override
  void dispose() {
    _streamSub.cancel(); // ✅ Always cancel
    _timer.cancel();     // ✅ Always cancel
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

// ---

// 8. USE THROTTLING/DEBOUNCING FOR FREQUENT UPDATES
// Don't rebuild on every location update

import 'package:rxdart/rxdart.dart';

class LocationService {
  final _locationSubject = BehaviorSubject<GeoPoint>();
  
  void updateLocation(GeoPoint location) {
    _locationSubject.add(location);
  }
  
  Stream<GeoPoint> get locationStream => _locationSubject.stream
    .throttleTime(Duration(milliseconds: 500)) // Only emit every 500ms
    .distinct();
}

// ---

// 9. MINIMIZE WIDGET REBUILDS WITH PROVIDER
// Use select() instead of full Consumer

// ❌ BAD - Rebuilds when ANY provider changes
Consumer<OfficerProvider>(
  builder: (context, provider, _) {
    return Text(provider.officer.name);
  },
)

// ✅ GOOD - Only rebuilds when name changes
Selector<OfficerProvider, String>(
  selector: (_, provider) => provider.officer.name,
  builder: (context, name, _) {
    return Text(name);
  },
)

// ---

// 10. USE IMAGE CACHING FOR MARKERS
// Avoid regenerating marker bitmaps constantly

class MarkerBitmapCache {
  static final Map<String, Future<BitmapDescriptor>> _cache = {};

  static Future<BitmapDescriptor> getMarkerBitmap(
    String officerId,
    Color color,
  ) async {
    final key = '$officerId-${color.value}';
    
    return _cache.putIfAbsent(key, () async {
      return BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty,
        'assets/marker_${color.toString()}.png',
      );
    });
  }
  
  static void clearCache() => _cache.clear();
}

// ---

// 11. USE CONST STREAMS FOR UNCHANGING DATA
// Don't rebuild stateful widgets unnecessarily

class Officer {
  // ✅ Mark as const if all fields are const
  const Officer({
    required this.id,
    required this.name,
    required this.badge,
  });
  
  final String id;
  final String name;
  final String badge;
}

// ---

// 12. OPTIMIZE MAP RENDERING
// Use marker clustering for 50+ markers

import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';

class MonitoringView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Officer>>(
      stream: _db.getOfficersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final officers = snapshot.data!;
        
        // Only render visible markers (within viewport)
        Set<Marker> markers = {};
        if (officers.length > 50) {
          // Use clustering algorithm
          final clusters = _clusterMarkers(officers);
          markers = clusters.map((cluster) => _clusterToMarker(cluster)).toSet();
        } else {
          markers = officers.map(_officerToMarker).toSet();
        }
        
        return GoogleMap(
          markers: markers,
          // Rest of config...
        );
      },
    );
  }
  
  Marker _officerToMarker(Officer officer) => Marker(
    markerId: MarkerId(officer.id),
    position: LatLng(officer.location.latitude, officer.location.longitude),
    // Cache bitmap instead of recreating
    icon: _markerBitmaps[officer.status] ?? BitmapDescriptor.defaultMarker,
  );
}

// ---

// 13. USE LISTVIEW.BUILDER NOT LISTVIEW
// .builder only renders visible items

// ❌ BAD - All items rendered at once
ListView(
  children: officers.map((o) => OfficerCard(o)).toList(),
)

// ✅ GOOD - Only visible items rendered
ListView.builder(
  itemCount: officers.length,
  itemBuilder: (context, index) => OfficerCard(officers[index]),
)

// ---

// 14. PROFILE YOUR APP WITH FLUTTER DEVTOOLS
// Check for jank and performance bottlenecks

/*
Steps:
1. flutter run -d chrome --profile
2. Open Chrome DevTools (Ctrl+Shift+I)
3. Go to "Performance" tab
4. Look for long frames (>16ms = 60fps)
5. Check widget rebuild counts
6. Use "Track widget rebuilds" checkbox
*/

// ---

// 15. USE RESPONSIVENESS UTILITIES
// Check screen size at runtime, not compile time

import 'responsive.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtil.isMobile(context)) {
      return MobileLayout();
    } else if (ResponsiveUtil.isTablet(context)) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  }
}

// ---

// BEST PRACTICES SUMMARY:
// ========================
//
// 1. Always use const constructors
// 2. Dispose streams & timers
// 3. Cache expensive computations
// 4. Use ListView.builder not ListView
// 5. Profile with DevTools
// 6. Minimize rebuilds with Selector
// 7. Use RepaintBoundary for complex widgets
// 8. Cache network images
// 9. Use Slivers for complex scrolling
// 10. Throttle frequent updates
// 11. Avoid large objects in build()
// 12. Use SingleChildScrollView only when necessary
// 13. Profile before optimizing
// 14. Test on real devices, not just emulators
// 15. Monitor memory usage
//
// PERFORMANCE TARGETS:
// ====================
// • 60 FPS on most frames (16ms per frame)
// • < 3 seconds initial load time
// • < 100MB memory usage
// • Smooth animations & transitions
// • No jank during scrolling

