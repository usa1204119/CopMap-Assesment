# CopMap - Police Officer Tracking & Station Management System

**A real-time police station management platform with live officer tracking, duty assignment, and emergency alert system.**

> **Status**: BETA (70% Complete) | **Last Updated**: January 31, 2026

---

## 📋 Table of Contents

1. [Problem Understanding](#problem-understanding)
2. [Architecture Overview](#architecture-overview)
3. [System Design](#system-design)
4. [Database Schema](#database-schema)
5. [Implementation Status](#implementation-status)
6. [Trade-offs & Decisions](#trade-offs--decisions)
7. [Installation & Setup](#installation--setup)
8. [Running the Application](#running-the-application)
9. [API Documentation](#api-documentation)
10. [Project Structure](#project-structure)
11. [Key Features](#key-features)

---

## 🎯 Problem Understanding

### The Challenge

Police station commanders need a **real-time system** to:
- 📍 Track field officers' locations during patrol duties
- 🎯 Assign officers to specific areas (Patrol or Bandobast duties)
- 🚨 Receive emergency alerts from officers in distress
- 📊 Monitor duty status and officer availability
- 📱 Support both station management (web/desktop) and field officers (mobile)

### Key Requirements

| Requirement | Priority | Solution |
|-------------|----------|----------|
| Real-time location tracking | CRITICAL | GPS + Firestore streams |
| Role-based access control | CRITICAL | Firebase Auth + role enums |
| Live map visualization | CRITICAL | Google Maps with custom markers |
| Emergency alerts | CRITICAL | Firestore alert collection + status indicators |
| Multi-platform support | HIGH | Flutter (Web + Android + iOS) |
| Low latency communication | HIGH | Firebase Firestore real-time listeners |
| Offline resilience | MEDIUM | (Planned: Local cache with Hive) |

---

## 🏗️ Architecture Overview

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CopMap System Architecture                   │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────┐         ┌──────────────────────┐
│  Station Master      │         │   Field Officer      │
│     (Web/Desktop)    │         │    (Mobile App)      │
│                      │         │                      │
│ • Dashboard          │         │ • Home Screen        │
│ • Live Monitoring    │         │ • Tracking Map       │
│ • Create Duties      │◄─────►  │ • Alert Sending      │
│ • Alert Management   │  JSON   │ • Profile            │
└──────────────────────┘         └──────────────────────┘
         │                                 │
         │                                 │
         └────────────────┬────────────────┘
                          │
                    (Firebase SDK)
                          │
                ┌─────────▼─────────┐
                │   Firebase        │
                │  (Google Cloud)   │
                │                   │
                │ • Firestore DB    │
                │ • Auth Service    │
                │ • Cloud Messaging │
                └───────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
    ┌─────▼────┐  ┌─────▼────┐  ┌─────▼────┐
    │  Officers │  │   Duties  │  │  Alerts  │
    │Collection │  │Collection │  │Collection│
    └──────────┘  └──────────┘  └──────────┘
```

### Technology Stack

**Frontend:**
- **Framework**: Flutter 3.9.2
- **State Management**: Provider + StreamBuilder
- **UI Components**: Material Design 3, Lucide Icons
- **Maps**: Google Maps Flutter
- **Location**: Geolocator + Google Places API

**Backend:**
- **Database**: Firebase Firestore (NoSQL)
- **Authentication**: Firebase Authentication
- **Real-time Communication**: Firestore Listeners (WebSocket-like)
- **Cloud Services**: Google Cloud Platform

**Deployment:**
- **Web**: Flutter Web (browser)
- **Mobile**: Android (Play Store), iOS (App Store)
- **Platform**: Cloud-hosted via Firebase Hosting

---

## 🔄 System Design

### Data Flow Diagrams

#### 1. **Duty Assignment Flow**

```
Station Master                 Firestore              Field Officer App
     │                            │                          │
     ├─ Create Duty ─────────────>│                          │
     │  (area, officers, time)    │                          │
     │                            │                          │
     │                    Store in /duties                    │
     │                    collection                          │
     │                            │                          │
     │                            │<─ Real-time Listener ────┤
     │                            │  (StreamBuilder)         │
     │                            │                          │
     │                            ├─ Fetch Duty ────────────>│
     │                            │                          │
     │<─── Update on Dashboard ───│<─ Officer Starts ────────┤
     │     (stats refresh)        │   Duty (tap button)      │
     │                            │                          │
     │                            ├─ Update duty status ────>│
     │                            │   to "in_progress"       │
     │                            │                          │
     └─────────────────────────────────────────────────────┘
```

#### 2. **Location Tracking Flow**

```
Field Officer                   Device                Firestore         Station Master
     │                            │                      │                    │
     ├─ Start Duty ──────────────>│                      │                    │
     │  (trigger tracking)        │                      │                    │
     │                            │                      │                    │
     │<─────────────────────────┤ GPS Stream            │                    │
     │  (Geolocator package)     │  (5m threshold)      │                    │
     │                            │                      │                    │
     │                         Current Location         │                    │
     │                            │                      │                    │
     │                    Update ──────────────────────>│                    │
     │                    /officers/{id}                │                    │
     │                    + location + timestamp        │                    │
     │                            │                      │                    │
     │                            │           Stream ────────────────────────>│
     │                            │           Listener   │  Refresh Map       │
     │                            │           (Real-time)                     │
     │                            │                      │                    │
     │◄───────────────────────────────────────────────────── Show Blue Marker ─
```

#### 3. **Alert System Flow**

```
Field Officer              Firestore           Station Master
     │                         │                      │
     ├─ Send Alert ───────────>│                      │
     │ (Battery/SOS/Offline)   │                      │
     │                         │                      │
     │              Store in    │                      │
     │              /alerts     │                      │
     │                         │                      │
     │                    Listener ──────────────────>│
     │                    (Real-time)                 │
     │                         │          Snackbar    │
     │                         │          + Red Card  │
     │                         │          + Audio     │
     │                         │                      │
     │                         │<─ Station Resolves ──
     │                         │  (Mark as resolved)  
     │                         │                      │
     ├─ Clear Alert ──────────>│                      │
     │ (Acknowledge)           │                      │
     │                         │
```

#### 4. **User Authentication Flow**

```
User                           App                  Firebase Auth
 │                              │                        │
 ├─ Enter Email/Password ──────>│                        │
 │                              │                        │
 │                              ├─ signInWithEmailPassword
 │                              ├─────────────────────── >│
 │                              │                        │
 │                              │<────── Auth Token ─────┤
 │                              │    (JWT)               │
 │                              │                        │
 │<────── Route Decision ───────┤                        │
 │ (check role from Firestore)  │                        │
 │                              │                        │
 ├─ Dashboard/Officer Screen   │                        │
 │                              │                        │
 │◄───── Authenticated Session ─┤                        │
 │                              │                        │
```

---

## 💾 Database Schema

### Firestore Collections Structure

```javascript
// /users collection
{
  userId: {
    email: string,
    name: string,
    role: "station_master" | "field_officer",
    createdAt: timestamp,
    updatedAt: timestamp,
    isActive: boolean
  }
}

// /officers collection
{
  officerId: {
    name: string,
    badge: string,
    email: string,
    phone: string,
    role: "field_officer",
    status: "active" | "issue" | "offline",
    
    // Location data
    location: GeoPoint { latitude, longitude },
    lastLocationUpdate: timestamp,
    
    // Current duty assignment
    currentDutyId: string,
    
    // Real-time metrics
    batteryLevel: number (0-100),
    signalStrength: "strong" | "weak" | "none",
    
    // Metadata
    createdAt: timestamp,
    updatedAt: timestamp
  }
}

// /duties collection
{
  dutyId: {
    type: "patrol" | "bandobast",
    description: string,
    area: string,
    location: GeoPoint { latitude, longitude },
    
    // Assignment
    createdBy: string (station_master_id),
    assignedOfficerIds: string[],
    
    // Scheduling
    startTime: timestamp,
    endTime: timestamp,
    
    // Status tracking per officer
    officerStatus: {
      officerId1: "pending" | "started" | "completed" | "cancelled",
      officerId2: "pending" | "started" | "completed" | "cancelled"
    },
    
    // Metadata
    createdAt: timestamp,
    updatedAt: timestamp
  }
}

// /alerts collection
{
  alertId: {
    type: "battery_low" | "tracking_stopped" | "offline" | "sos",
    officerId: string,
    officerName: string,
    
    // Alert context
    message: string,
    location: GeoPoint,
    
    // Status
    resolved: boolean,
    resolvedBy: string (optional),
    resolvedAt: timestamp (optional),
    
    // Timestamps
    createdAt: timestamp,
    updatedAt: timestamp
  }
}
```

### Entity Relationship Diagram

```
┌──────────────┐           ┌──────────────┐
│    Users     │           │   Officers   │
├──────────────┤           ├──────────────┤
│ userId (PK)  │──┐    ┌──│ officerId(PK)│
│ email        │  │    │  │ name         │
│ name         │  │    │  │ badge        │
│ role         │  │    │  │ status       │
│ createdAt    │  │    │  │ location     │
└──────────────┘  │    │  └──────────────┘
                  │    │
                  │    │  ┌──────────────┐
                  │    └─>│   Duties     │
                  │       ├──────────────┤
                  └─────> │ dutyId (PK)  │
                         │ type         │
                         │ area         │
                         │ assignedOfficers[]
                         │ createdBy    │
                         │ officerStatus{}
                         └──────────────┘
                                │
                                │ triggers
                                │
                         ┌──────▼──────┐
                         │   Alerts    │
                         ├─────────────┤
                         │ alertId(PK) │
                         │ type        │
                         │ officerId   │
                         │ resolved    │
                         └─────────────┘
```

---

## ✅ Implementation Status

### Completed Features (45+)

#### Station Master Dashboard
- ✅ Real-time statistics (active duties, officers, pending alerts)
- ✅ Recent duties listing with status indicators
- ✅ Interactive metric cards
- ✅ Live Google Map monitoring
- ✅ Custom officer markers with status colors
- ✅ Duty location markers
- ✅ Route polylines from officers to destinations
- ✅ Create duty with officer multi-selection
- ✅ Area search with autocomplete
- ✅ Alerts view with status indicators
- ✅ Alert resolution interface

#### Officer Mobile App
- ✅ Officer home screen with current duty
- ✅ Quick action buttons (Start/End Duty, Send Alert)
- ✅ Officer profile card
- ✅ Live GPS tracking map
- ✅ Current location marker (blue)
- ✅ Destination marker (red)
- ✅ Route visualization
- ✅ Incoming alerts display
- ✅ Officer profile screen with history

#### Backend & Infrastructure
- ✅ Firebase authentication (email/password)
- ✅ Role-based access control
- ✅ Firestore collections setup
- ✅ Real-time StreamBuilders
- ✅ Google Maps API integration
- ✅ Location tracking service
- ✅ Database service (CRUD operations)
- ✅ Authentication provider

#### UI/UX
- ✅ Dark theme with Material Design 3
- ✅ Responsive layout (Web + Mobile)
- ✅ Custom widgets
- ✅ Status color coding
- ✅ Google Fonts typography
- ✅ Lucide Icons integration

---

## 📦 Installation & Setup

### Prerequisites

1. **Flutter SDK** (v3.9.2 or later)
   ```bash
   flutter --version
   ```

2. **Firebase Project**
   - Go to [console.firebase.google.com](https://console.firebase.google.com)
   - Create a new project
   - Enable Firestore Database
   - Enable Authentication (Email/Password)

3. **Google Cloud Project** (for Maps API)
   - Enable Maps SDK for Android
   - Enable Google Places API
   - Create an API key

4. **IDE**: Android Studio, Xcode (for iOS), or VS Code

### Step-by-Step Setup

#### 1. Clone Repository
```bash
git clone <repository-url>
cd copmap_flutter
```

#### 2. Get Flutter Dependencies
```bash
flutter pub get
```

#### 3. Configure Firebase

**For Android:**
- Download `google-services.json` from Firebase Console
- Place in `android/app/`

**For iOS:**
- Download `GoogleService-Info.plist`
- Add to Xcode project (Runner > Runner)

**For Web:**
- Initialize Firebase in `web/index.html` with your config

#### 4. Configure Google Maps API

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

**iOS** (`ios/Runner/GeneratedPluginRegistrant.m`):
- Google Maps plugin auto-configured

**Web** (`web/index.html`):
```html
<script>
  window.addEventListener('flutter-first-frame', function() {
    // Initialize Maps
  });
</script>
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY"></script>
```

#### 5. Verify Configuration
```bash
flutter doctor -v
```

---

## 🚀 Running the Application

### Development Mode

**Run on Android Emulator:**
```bash
flutter run -d emulator-5554
```

**Run on iOS Simulator:**
```bash
flutter run -d ios
```

**Run on Web:**
```bash
flutter run -d chrome
```

**Run on Physical Device:**
```bash
flutter run -d <device-id>
```

### Build for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle (Google Play):**
```bash
flutter build appbundle --release
```

**iOS App:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

---

## 📚 API Documentation

### Firebase Firestore Operations

This app uses Firebase Firestore as the backend. All API operations are real-time via WebSocket-like listeners.

#### Authentication Endpoints

**Sign Up Officer**
```dart
// Service: auth_provider.dart
Future<void> signup(String email, String password, String name, String badge) async {
  // 1. Create Firebase Auth user
  // 2. Create /users document with role="field_officer"
  // 3. Create /officers document
}
```

**Sign Up Station Master**
```dart
Future<void> signupStationMaster(String email, String password, String name) async {
  // 1. Create Firebase Auth user
  // 2. Create /users document with role="station_master"
}
```

**Login**
```dart
Future<void> login(String email, String password) async {
  // Firebase Email/Password authentication
  // Returns auth token valid for 1 hour
}
```

#### Officer Operations

**Get Current Officer**
```dart
// Endpoint: GET /officers/{officerId}
Future<Officer> getCurrentOfficer(String officerId)
```

**Update Officer Location**
```dart
// Endpoint: PATCH /officers/{officerId}
Future<void> updateOfficerLocation(String officerId, double lat, double lng, int battery)
```

**Get Officer's Current Duty**
```dart
// Endpoint: GET /officers/{officerId}
// Returns currentDutyId, then GET /duties/{dutyId}
Future<Duty?> getCurrentDuty(String officerId)
```

#### Duty Operations

**Create Duty**
```dart
// Endpoint: POST /duties
Future<String> createDuty(Duty duty) async {
  // Station Master only
  // Returns dutyId
}
```

**Assign Officers to Duty**
```dart
// Endpoint: PATCH /duties/{dutyId}
Future<void> assignOfficers(String dutyId, List<String> officerIds)
```

**Get Active Duties**
```dart
// Endpoint: GET /duties?status=active
Stream<List<Duty>> getActiveDutiesStream()
```

**Start Duty**
```dart
// Endpoint: PATCH /duties/{dutyId}
Future<void> startDuty(String dutyId, String officerId) async {
  // Updates officerStatus[officerId] = "started"
}
```

**Complete Duty**
```dart
// Endpoint: PATCH /duties/{dutyId}
Future<void> completeDuty(String dutyId, String officerId) async {
  // Updates officerStatus[officerId] = "completed"
}
```

#### Alert Operations

**Send Alert from Officer**
```dart
// Endpoint: POST /alerts
Future<void> sendAlertFromOfficer(
  String officerId,
  String officerName,
  AlertType type,
  {GeoPoint? location}
) async {
  // Creates new alert document
  // Types: "battery_low", "tracking_stopped", "offline"
}
```

**Get Active Alerts**
```dart
// Endpoint: GET /alerts?resolved=false
Stream<List<Alert>> getActiveAlertsStream()
```

**Resolve Alert**
```dart
// Endpoint: PATCH /alerts/{alertId}
Future<void> resolveAlert(String alertId, String resolvedBy)
```

### Postman Collection

Since this project uses Firestore (not REST API), traditional Postman collections don't apply. However, you can test via:

1. **Firebase Console** - Direct Firestore testing
2. **Flutter DevTools** - Debug real-time listeners
3. **Custom REST Wrapper** - Wrap Firestore in Cloud Functions for REST API

#### Cloud Functions Example (Optional)

If you implement Cloud Functions for REST API:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// REST Endpoint: POST /api/duties
exports.createDuty = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }
  
  try {
    const { type, area, location, assignedOfficerIds, startTime, endTime } = req.body;
    const dutyRef = await db.collection('duties').add({
      type,
      area,
      location,
      assignedOfficerIds,
      startTime,
      endTime,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    res.json({ success: true, dutyId: dutyRef.id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

---

## 📁 Project Structure

```
copmap_flutter/
├── android/                      # Android native code
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml
│   │   │   └── kotlin/
│   │   └── google-services.json
│   └── gradle/
│
├── ios/                          # iOS native code
│   ├── Runner/
│   │   ├── GeneratedPluginRegistrant.m
│   │   └── Info.plist
│   └── Podfile
│
├── web/                          # Web platform code
│   ├── index.html
│   ├── manifest.json
│   └── firebase-config.js
│
├── lib/                          # Main Flutter application
│   ├── main.dart                 # Entry point
│   │
│   ├── models/                   # Data models
│   │   ├── officer.dart         # Officer model with serialization
│   │   ├── duty.dart            # Duty assignment model
│   │   ├── alert.dart           # Alert model
│   │   └── user_role.dart       # Role enum
│   │
│   ├── screens/                  # App screens/pages
│   │   ├── login_screen.dart    # Authentication
│   │   ├── main_layout.dart     # Station master main layout
│   │   ├── dashboard_view.dart  # Dashboard with stats
│   │   ├── monitoring_view.dart # Google Maps live tracking
│   │   ├── create_duty_view.dart # Duty creation form
│   │   ├── alerts_view.dart     # Alert management
│   │   └── officer/             # Officer mobile app screens
│   │       ├── officer_app_layout.dart
│   │       ├── officer_home_screen.dart
│   │       ├── officer_tracking_screen.dart
│   │       ├── officer_alerts_screen.dart
│   │       └── officer_profile_screen.dart
│   │
│   ├── services/                 # Business logic & API calls
│   │   ├── database_service.dart       # Firestore CRUD operations
│   │   ├── location_tracking_service.dart # GPS tracking stream
│   │   ├── location_service.dart       # Google Places API
│   │   ├── navigation_service.dart     # App navigation
│   │   ├── auth_service.dart          # Firebase Auth
│   │   └── notification_service.dart  # (Planned) Push notifications
│   │
│   ├── providers/                # State management
│   │   └── auth_provider.dart    # Authentication provider
│   │
│   ├── widgets/                  # Reusable UI components
│   │   ├── sidebar.dart          # Navigation sidebar
│   │   ├── header.dart           # Top app bar
│   │   ├── stat_card.dart        # Statistics card
│   │   ├── duty_card.dart        # Duty display card
│   │   ├── alert_card.dart       # Alert notification card
│   │   └── splash_screen.dart    # Loading screen
│   │
│   ├── theme/                    # Design system
│   │   └── app_theme.dart        # Color palette, text styles
│   │
│   └── utils/                    # Utilities (if needed)
│       └── constants.dart        # App-wide constants
│
├── test/                         # Unit & integration tests
│   ├── widget_test.dart         # Widget tests
│   └── services/                # Service tests (planned)
│
├── pubspec.yaml                 # Dependencies
├── pubspec.lock                 # Dependency lock file
├── analysis_options.yaml        # Linting rules
├── .gitignore                   # Git ignore file
│
└── docs/                        # Documentation (optional)
    ├── ARCHITECTURE_DIAGRAMS.md
    ├── COMMUNICATION_SYSTEM.md
    ├── TESTING_GUIDE.md
    └── DEPLOYMENT_GUIDE.md
```

---

## ⭐ Key Features

### Station Master Dashboard

**Dashboard View**
- 📊 Real-time statistics (active duties, officers, pending alerts)
- 📈 Recent duties with status indicators
- 🎨 Color-coded metrics cards
- 🔄 Auto-refresh every 5 seconds

**Monitoring View**
- 🗺️ Live Google Map
- 🔵 Blue markers for officer locations
- 🔴 Red markers for duty destinations
- 🛣️ Polyline routes from officers to duties
- 📌 Info windows with officer status

**Create Duty**
- ✏️ Form with duty type selection (Patrol/Bandobast)
- 🔍 Area search with autocomplete
- 👥 Multi-select officer picker
- ⏰ Date/time scheduling
- ✅ Form validation

**Alerts**
- 🚨 Real-time alert notifications
- 🏷️ Alert type badges (Battery, Tracking, Offline)
- ✔️ Mark as resolved
- 📱 Officer name and timestamp

### Officer Mobile App

**Home Screen**
- 📋 Current duty display
- ⏱️ Duty timing and area
- 🎯 Quick action buttons (Start/End Duty, Send Alert)
- 🔋 Battery and signal status
- 👤 Officer profile card

**Tracking Screen**
- 🗺️ Live Google Map
- 🔵 Current location marker (blue)
- 🔴 Duty destination marker (red)
- 🛣️ Route to destination
- 📍 Location updates with 5m precision

**Alerts Screen**
- 🚨 Incoming alerts from station
- ✅ Acknowledge functionality
- 📜 Alert history

**Profile Screen**
- 👤 Officer details (name, badge, ID)
- 📝 Duty history
- 🟢 Current status indicator

---

## 🛠️ Development

### Code Style

- **Formatting**: `dart format .`
- **Analysis**: `dart analyze`
- **Linting**: Follows `analysis_options.yaml`

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/officer_test.dart

# Run with coverage
flutter test --coverage
```

### Debugging

**Enable Debug Logging:**
```dart
// In main.dart
void main() {
  // Enable Firebase logging
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(MyApp());
}
```

**Use Flutter DevTools:**
```bash
flutter pub global activate devtools
flutter devtools
```

---

## 📋 Known Issues & Limitations

| Issue | Impact | Status | Fix ETA |
|-------|--------|--------|---------|
| Background location stops when app minimized | HIGH | OPEN | v2.0 |
| No offline mode support | MEDIUM | OPEN | v2.0 |
| API keys exposed in source | CRITICAL | OPEN | v1.1 |
| Missing Firestore security rules | CRITICAL | OPEN | v1.1 |
| <1% test coverage | HIGH | OPEN | v1.1 |
| No push notifications | MEDIUM | OPEN | v1.1 |
| Marker clustering not implemented | LOW | OPEN | v2.0 |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Before Committing

```bash
# Format code
dart format .

# Run analysis
dart analyze

# Run tests
flutter test
```

---

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

---

## 📞 Support & Contact

- **Issues**: Open issues on GitHub
- **Documentation**: See [docs/](./docs/) folder
- **Firebase Docs**: [firebase.google.com/docs](https://firebase.google.com/docs)
- **Flutter Docs**: [flutter.dev/docs](https://flutter.dev/docs)

---

## 🗺️ Roadmap

### ✅ Completed (v1.0)
- Real-time duty assignment
- Live officer tracking
- Alert system
- Web + Mobile support

### 🔄 In Progress (v1.1)
- Security hardening
- Background location tracking
- Push notifications

### 📅 Planned (v2.0)
- Geofencing
- Offline support
- Advanced analytics
- Marker clustering
- Supervisor role
- Photo verification

---

**Last Updated**: January 31, 2026 | **Status**: BETA (70% Complete)
