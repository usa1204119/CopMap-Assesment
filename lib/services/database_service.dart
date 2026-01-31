import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:copmap_flutter/models/alert.dart';
import 'package:copmap_flutter/models/duty.dart';
import 'package:copmap_flutter/models/officer.dart';
import 'package:copmap_flutter/models/user_role.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// DatabaseService provides real-time Firestore operations for CopMap
/// Features:
/// - Real-time officer location tracking
/// - Duty assignment and management
/// - Alert system for emergencies
/// - Location streaming for live monitoring
///
/// Live Location Implementation:
/// - Officers' locations are updated every 5 meters via LocationTrackingService
/// - Use getOfficersStream() for all officers with live locations
/// - Use getOfficerLocationStream(officerId) for single officer's live location
/// - Use getOfficerStream(officerId) for complete officer data with live location
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== OFFICERS ====================
  /// Streams all officers with real-time location updates from Firestore
  /// Each officer's location is updated via background GPS tracking
  Stream<List<Officer>> getOfficersStream() {
    return _db.collection('officers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Officer.fromFirestore(doc)).toList();
    });
  }

  /// Updates officer's location in Firestore
  /// Called by LocationTrackingService every 5 meters
  /// Also updates lastUpdate timestamp automatically via server timestamp
  Future<void> updateOfficerLocation(String id, LatLng location) {
    return _db.collection('officers').doc(id).update({
      'location': GeoPoint(location.latitude, location.longitude),
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Duties
  Stream<List<Duty>> getActiveDutiesStream() {
    return _db.collection('duties').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Duty.fromFirestore(doc)).toList();
    });
  }

  Future<void> createDuty(Duty duty) {
    return _db.collection('duties').doc(duty.id).set(duty.toMap());
  }

  // Alerts
  Stream<List<Alert>> getAlertsStream() {
    return _db
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Alert.fromFirestore(doc)).toList();
        });
  }

  Future<void> resolveAlert(String alertId) {
    return _db.collection('alerts').doc(alertId).update({'resolved': true});
  }

  // Send alert from officer to station
  Future<void> sendAlertFromOfficer(
    String officerId,
    String officerName,
    AlertType type,
  ) {
    return _db.collection('alerts').add({
      'type': type.toString().split('.').last == 'batteryLow'
          ? 'battery_low'
          : type.toString().split('.').last == 'trackingStopped'
          ? 'tracking_stopped'
          : 'offline',
      'officerId': officerId,
      'officerName': officerName,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'resolved': false,
    });
  }

  // Update duty status (officer started/completed duty)
  Future<void> updateDutyStatus(
    String dutyId,
    String officerId,
    String status,
  ) {
    return _db.collection('duties').doc(dutyId).update({
      'officerStatus.$officerId': status, // active, completed, paused
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Update duty details (area, times, etc.)
  Future<void> updateDuty(Duty duty) {
    return _db.collection('duties').doc(duty.id).update({
      'area': duty.area,
      'startTime': Timestamp.fromDate(duty.startTime),
      'endTime': Timestamp.fromDate(duty.endTime),
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Delete duty
  Future<void> deleteDuty(String dutyId) {
    return _db.collection('duties').doc(dutyId).delete();
  }

  // Get officer by ID
  Future<Officer?> getOfficer(String id) async {
    try {
      final doc = await _db.collection('officers').doc(id).get();
      if (doc.exists) {
        return Officer.fromFirestore(doc);
      }
    } catch (e) {
      print('Error fetching officer: $e');
    }
    return null;
  }

  // Update officer status (active, issue, offline)
  Future<void> updateOfficerStatus(String id, OfficerStatus status) {
    return _db.collection('officers').doc(id).update({
      'status': status.toString().split('.').last,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Get all officers for a specific duty
  Stream<List<Officer>> getOfficersForDuty(String dutyId) {
    return _db.collection('duties').doc(dutyId).snapshots().asyncMap((
      dutyDoc,
    ) async {
      if (!dutyDoc.exists) return [];

      final duty = Duty.fromFirestore(dutyDoc);
      final List<Officer> officers = [];

      for (String officerId in duty.assignedOfficerIds) {
        final officer = await getOfficer(officerId);
        if (officer != null) {
          officers.add(officer);
        }
      }

      return officers;
    });
  }

  // Create officer from Firebase Auth user
  Future<void> createOfficerFromUser(
    User user, {
    required String badgeNumber,
  }) async {
    final role = UserRoleExtension.determineRoleFromEmail(user.email ?? '');

    final officer = Officer(
      id: user.uid,
      name: user.displayName ?? user.email?.split('@')[0] ?? 'Unknown Officer',
      badge: badgeNumber,
      status: OfficerStatus.active,
      location: const LatLng(28.6139, 77.2090), // Default location
      lastUpdate: DateTime.now(),
      role: role,
      email: user.email ?? '',
    );

    await _db.collection('officers').doc(user.uid).set(officer.toMap());
  }

  // Get only field officers (for station master dashboard)
  Stream<List<Officer>> getFieldOfficersStream() {
    return _db
        .collection('officers')
        .where('role', isEqualTo: 'field_officer')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Officer.fromFirestore(doc))
              .toList();
        });
  }

  // Get user role by email
  Future<UserRole> getUserRole(String email) async {
    try {
      final doc = await _db
          .collection('officers')
          .where('email', isEqualTo: email)
          .get();
      if (doc.docs.isNotEmpty) {
        final officer = Officer.fromFirestore(doc.docs.first);
        return officer.role;
      }
      // If not found in Firestore, determine from email
      return UserRoleExtension.determineRoleFromEmail(email);
    } catch (e) {
      print('Error getting user role: $e');
      return UserRoleExtension.determineRoleFromEmail(email);
    }
  }

  // Get duties assigned to a specific officer
  Stream<List<Duty>> getOfficerDutiesStream(String officerId) {
    return _db
        .collection('duties')
        .where('assignedOfficerIds', arrayContains: officerId)
        .where('endTime', isGreaterThan: Timestamp.now())
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Duty.fromFirestore(doc)).toList();
        });
  }

  // Get active duty for an officer
  Stream<Duty?> getOfficerActiveDutyStream(String officerId) {
    final now = Timestamp.now();
    return _db
        .collection('duties')
        .where('assignedOfficerIds', arrayContains: officerId)
        .where('startTime', isLessThanOrEqualTo: now)
        .where('endTime', isGreaterThan: now)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs;
          if (docs.isNotEmpty) {
            return Duty.fromFirestore(docs.first);
          }
          return null;
        });
  }

  /// Stream live location updates for a specific officer from Firestore
  /// This fetches location data in real-time whenever the officer's location field changes
  Stream<LatLng?> getOfficerLocationStream(String officerId) {
    return _db.collection('officers').doc(officerId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;

      final data = snapshot.data() as Map<String, dynamic>;
      final location = data['location'] as GeoPoint?;

      if (location != null) {
        return LatLng(location.latitude, location.longitude);
      }
      return null;
    });
  }

  /// Stream live officer data with location updates
  /// Provides complete officer object with latest location from Firestore
  Stream<Officer?> getOfficerStream(String officerId) {
    return _db.collection('officers').doc(officerId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return Officer.fromFirestore(snapshot);
    });
  }
}
