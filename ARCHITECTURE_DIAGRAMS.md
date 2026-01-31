# Live Location System Architecture

## System Overview Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        COPMAP LIVE LOCATION SYSTEM                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                    FIELD OFFICER (Mobile Device)                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  OfficerAppLayout                                                      │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │ │
│  │  │ initState() {                                                    │ │ │
│  │  │   _initializeBackgroundLocationTracking()  ← AUTO-STARTS         │ │ │
│  │  │ }                                                                │ │ │
│  │  └──────────────────────────────────────────────────────────────────┘ │ │
│  │                           ↓                                           │ │
│  │  ┌────────────────────────────────────────────────────────────────┐ │ │
│  │  │ _initializeBackgroundLocationTracking()                       │ │ │
│  │  │ {                                                              │ │ │
│  │  │   1. Request permission                                       │ │ │
│  │  │   2. Call startTracking()                                     │ │ │
│  │  │   3. Continue across all screens                              │ │ │
│  │  │   4. Stop in dispose()                                        │ │ │
│  │  │ }                                                              │ │ │
│  │  └──────────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                           ↓                                                  │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  LocationTrackingService                                               │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │ │
│  │  │ startTracking(officerId) {                                      │ │ │
│  │  │   Geolocator.getPositionStream(                                 │ │ │
│  │  │     accuracy: LocationAccuracy.high,                            │ │ │
│  │  │     distanceFilter: 5  ← Updates every 5 meters                 │ │ │
│  │  │   ).listen((position) {                                         │ │ │
│  │  │     LatLng latLng = LatLng(pos.latitude, pos.longitude)         │ │ │
│  │  │     _db.updateOfficerLocation(officerId, latLng) ─────┐        │ │ │
│  │  │     _locationController.add(latLng)  ← UI updates    │        │ │ │
│  │  │   })                                                  │        │ │ │
│  │  │ }                                                     │        │ │ │
│  │  └──────────────────────────────────────────────────────┼────────┘ │ │
│  │                                                          │           │ │
│  │  Stream<LatLng> locationStream ←─────────────────────────┘           │ │
│  │  (Used by OfficerTrackingScreen)                                      │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                           ↓                                                  │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  DatabaseService.updateOfficerLocation()                               │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │ │
│  │  │ updateOfficerLocation(id, LatLng location) {                    │ │ │
│  │  │   firestore.collection('officers')                              │ │ │
│  │  │            .doc(id)                                             │ │ │
│  │  │            .update({                                            │ │ │
│  │  │              'location': GeoPoint(lat, lng)  ← FIRESTORE UPDATE │ │ │
│  │  │              'lastUpdate': FieldValue.serverTimestamp()         │ │ │
│  │  │            })                                                   │ │ │
│  │  │ }                                                               │ │ │
│  │  └──────────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  All Screens (Home, Tracking, Alerts, Profile)                             │
│  ├─ Location tracking running in background                                 │
│  ├─ Can view own location in OfficerTrackingScreen                          │
│  └─ All use same underlying GPS stream                                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                      ┌──────────────┴──────────────┐
                      │   FIREBASE/FIRESTORE        │
                      │   (Cloud Database)          │
                      └──────────────┬──────────────┘
                                     │
                ┌────────────────────┴────────────────────┐
                │  Collection: officers/{officerId}       │
                │                                         │
                │  Document Fields:                       │
                │  ├─ id: "officer_1"                     │
                │  ├─ name: "SI Rajesh Kumar"             │
                │  ├─ badge: "Badge #1024"                │
                │  ├─ role: "field_officer"               │
                │  ├─ status: "active"                    │
                │  ├─ location: GeoPoint(28.6139, 77.209) │
                │  ├─ lastUpdate: Timestamp               │
                │  └─ currentDutyId: "duty_123"           │
                │                                         │
                │  🔄 Updates every 5 meters              │
                │  ⏱️  timestamp always current            │
                │  📡 Real-time stream available          │
                │                                         │
                └────────────────────┬────────────────────┘
                                     │
                ┌────────────────────┴──────────────────────────────────┐
                │                                                       │
                ▼                                                       ▼
┌─────────────────────────────────────────┐    ┌─────────────────────────────┐
│  MONITORING VIEW                        │    │  OTHER SCREENS              │
│  (Station Master - Web/Mobile)          │    │  (Alerts, Duties, Etc)      │
├─────────────────────────────────────────┤    ├─────────────────────────────┤
│                                         │    │                             │
│ DatabaseService.getOfficersStream()     │    │ DatabaseService methods:    │
│   ↓                                     │    │                             │
│ Stream<List<Officer>>                   │    │ - getOfficerStream(id)      │
│   (All officers with live locations)    │    │ - getOfficerLocationStream()│
│   ↓                                     │    │                             │
│ GoogleMap Widget                        │    │ StreamBuilder updates       │
│   ├─ For each officer:                  │    │ UI with live data           │
│   ├─ Create marker at location          │    │                             │
│   ├─ Color by status (active/issue)     │    │ Example:                    │
│   ├─ Show name label                    │    │ StreamBuilder<Officer?>(    │
│   └─ Update in real-time                │    │   stream: _db.getOfficer... │
│                                         │    │   builder: (ctx, snap) { }  │
│ Real-time Updates:                      │    │ )                           │
│ ┌─────────────────────────────────────┐ │    │                             │
│ │ Officer moves 5+ meters             │ │    │ Battery Status Updates      │
│ │   ↓                                 │ │    │ Alert Notifications         │
│ │ Location updated in Firestore       │ │    │ Duty Status Changes         │
│ │   ↓                                 │ │    │                             │
│ │ getOfficersStream emits new data    │ │    │ All use stream pattern      │
│ │   ↓                                 │ │    │ for real-time updates       │
│ │ Markers update on map               │ │    │                             │
│ │   ↓                                 │ │    │                             │
│ │ Station sees new position (live)    │ │    │                             │
│ └─────────────────────────────────────┘ │    │                             │
│                                         │    │                             │
│ Legend:                                 │    │                             │
│ 🟢 Active (Active Duty)                 │    │                             │
│ 🟡 Issue (Low Battery/Tracking Issue)   │    │                             │
│ ⚪ Offline (Not Connected)              │    │                             │
│ 🔵 Duty Location (Patrol Area)          │    │                             │
│                                         │    │                             │
└─────────────────────────────────────────┘    └─────────────────────────────┘
```

---

## Data Flow: Location Update Sequence

```
Timeline: Officer moves 10 meters away

T0 (00:00:00)
├─ Officer at location A (28.6139° N, 77.209° E)
├─ Location stored in Firestore
└─ Monitoring map shows marker at location A

T1 (02 seconds)
├─ Officer walks 3 meters (not enough for update)
└─ No action

T2 (05 seconds)
├─ Officer walks 2 more meters (total 5 meters)
├─ LocationTrackingService detects 5m threshold reached
│  └─ Geolocator.getPositionStream triggers callback
└─ New position: 28.6144° N, 77.2095° E

T3 (05.5 seconds)
├─ DatabaseService.updateOfficerLocation() called
├─ Firestore document updated:
│  ├─ location: GeoPoint(28.6144, 77.2095)  ← NEW
│  └─ lastUpdate: Timestamp.now()            ← CURRENT
└─ Update size: ~100 bytes (very efficient)

T4 (05.6 seconds)
├─ Firestore notifies all listeners:
│  └─ getOfficersStream()
├─ All clients listening to officers collection receive update
└─ Contains full officer object with NEW location

T5 (05.65 seconds - Monitoring Map)
├─ StreamBuilder rebuilds with new officer data
├─ GoogleMap calculates marker position change
│  └─ Old: 28.6139° N, 77.209° E
│  └─ New: 28.6144° N, 77.2095° E
└─ Marker animates to new position on screen
    (Station Master sees update in real-time)

T6 (05.7 seconds - Other Screens)
├─ OfficerTrackingScreen (if subscribed)
│  └─ Sees location update via locationStream
├─ AlertsScreen (indirectly)
│  └─ May use location for geofencing alerts
└─ ProfileScreen (optional)
    └─ Can show "last location update: 1 second ago"

T7 (06+ seconds)
├─ System idle, waiting for next 5m threshold
└─ Battery optimized (not constantly updating)
```

---

## Component Dependencies

```
OfficerAppLayout (Entry Point)
│
├─→ LocationTrackingService
│   ├─ requestLocationPermission() → Geolocator
│   ├─ startTracking(officerId) → GPS Stream
│   └─ locationStream → LatLng updates
│
├─→ DatabaseService
│   ├─ updateOfficerLocation() → Firestore
│   ├─ getOfficersStream() → All officers
│   ├─ getOfficerStream() → Single officer
│   └─ getOfficerLocationStream() → Location only
│
└─→ Firebase/Firestore
    ├─ officers/{officerId}/location ← Gets updated
    ├─ officers/{officerId}/lastUpdate ← Auto timestamp
    └─ officers collection → Real-time stream
```

---

## API Endpoints Reference

### DatabaseService Methods

```dart
// Get all officers with live locations
Stream<List<Officer>> getOfficersStream()
// Returns: Emits new list whenever ANY officer updates

// Get single officer with live location
Stream<Officer?> getOfficerStream(String officerId)
// Returns: Emits single officer whenever they update

// Get location only (lightweight)
Stream<LatLng?> getOfficerLocationStream(String officerId)
// Returns: Just the LatLng, not full officer object

// Update location (called by LocationTrackingService)
Future<void> updateOfficerLocation(String id, LatLng location)
// Effect: Updates Firestore and triggers stream listeners
```

---

## Update Frequency & Performance

```
Distance Filter: 5 meters
├─ Minimum distance before update
├─ Reduces battery drain
└─ Prevents too frequent updates

Update Frequency (Examples):
├─ Stationary: 0 updates
├─ Slow walking (~1 m/s): ~1 update per 5 seconds
├─ Normal walking (~1.5 m/s): ~1 update per 3 seconds
├─ Running (~5 m/s): ~1 update per 1 second
└─ Driving (~10 m/s): ~1 update per 0.5 seconds

Firestore Impact:
├─ Active duty (~4 officers): ~1 write per 3 sec = 20 writes/min
├─ Peak time (10 officers): ~33 writes/min
├─ Monthly quota: 500K writes (Firebase Free: 50K/day)
└─ Status: ✅ Well within limits
```

---

## Security & Permissions

```
Android Permissions Required:
├─ ACCESS_FINE_LOCATION (GPS)
├─ ACCESS_COARSE_LOCATION (Network)
└─ (Optional) ACCESS_BACKGROUND_LOCATION

RequestLocationPermission() Flow:
├─ Check current status
├─ If DENIED → Request (user sees dialog)
├─ If DENIED_FOREVER → Open settings
└─ Return true/false based on result

Firestore Rules (Recommended):
├─ Officers read/write own location
├─ Station masters read all locations
└─ Prevent cross-officer data access
```

---

## Failure Scenarios & Recovery

```
GPS Not Available
├─ LocationTrackingService.startTracking() catches exception
├─ Shows error: "Location permission denied"
└─ UI continues working (just no tracking)

Firestore Update Fails
├─ DatabaseService.updateOfficerLocation() throws
├─ LocationTrackingService catches exception
├─ Logs: "Error updating location: [error]"
└─ Retries on next movement

Network Offline
├─ Firestore queues update locally
├─ Attempts to upload when online
├─ LocationTrackingService continues collecting data
└─ Sync happens automatically when network returns

App Backgrounded (OS Dependent)
├─ iOS: May stop GPS after ~10 minutes
├─ Android: Continues if permissions granted
├─ Battery optimization enabled: May be restricted
└─ Solution: Foreground service (future enhancement)

App Closed
├─ dispose() is called
├─ _locationService.stopTracking() stops GPS
├─ No more Firestore updates
└─ Location freezes at last position
```

---

## Integration Points

```
With Duty System:
├─ Officer gets duty assignment
├─ Tracking already running in background
└─ Duty area location compared with officer location

With Alert System:
├─ Officer location used for geofencing (future)
├─ Battery alerts independent of location
└─ Location critical for emergency response

With Auth System:
├─ User logged in → OfficerAppLayout
├─ _initializeBackgroundLocationTracking() starts
├─ officerId passed from auth context
└─ Tracking tied to authenticated user

With Monitoring Map:
├─ getOfficersStream() provides data
├─ GoogleMap renders markers
├─ Real-time updates flow automatically
└─ No additional code needed (already working)
```

---

## Class Relationships

```
OfficerAppLayout
    │
    ├─[composition]──→ LocationTrackingService
    │                     │
    │                     └─[uses]──→ Geolocator plugin
    │                                  └─ Streams GPS position
    │
    ├─[composition]──→ DatabaseService
    │                     │
    │                     └─[uses]──→ FirebaseFirestore
    │                                  └─ Reads/writes to officers collection
    │
    └─[contains]──→ OfficerHomeScreen
                   OfficerTrackingScreen
                   OfficerAlertsScreen
                   OfficerProfileScreen
                       │
                       └─[optional]──→ Consume location streams
                                       via DatabaseService
```

---

## Summary: Complete System Flow

```
1️⃣  Officer opens app
    └─ OfficerAppLayout loads

2️⃣  OfficerAppLayout.initState()
    └─ Calls _initializeBackgroundLocationTracking()

3️⃣  Background tracking initializes
    ├─ Request location permission
    └─ Start LocationTrackingService.startTracking()

4️⃣  GPS streaming begins
    ├─ Geolocator listens for position changes
    └─ Every 5 meters → triggers callback

5️⃣  Position callback received
    ├─ Create LatLng from GPS position
    └─ Call DatabaseService.updateOfficerLocation()

6️⃣  Firestore updated
    ├─ officers/{officerId}/location = new GeoPoint
    ├─ officers/{officerId}/lastUpdate = server timestamp
    └─ Notifies all stream listeners

7️⃣  Listeners receive update
    ├─ getOfficersStream() → monitoring view
    ├─ getOfficerStream() → any screen
    └─ getOfficerLocationStream() → location-only consumers

8️⃣  UI updates
    ├─ Monitoring map → marker moves
    ├─ Tracking screen → location changes
    └─ Profile screen → timestamp updates

9️⃣  Station Master sees live location
    ├─ Officer position on map
    ├─ Real-time updates as they move
    └─ Status indicator (active/issue/offline)

🔟  Cycle repeats
    └─ Every 5 meters or location change
```

---

This architecture ensures **real-time, efficient, and scalable** location tracking across the CopMap system.
