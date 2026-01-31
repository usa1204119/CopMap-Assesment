import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:copmap_flutter/models/user_role.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum OfficerStatus { active, issue, offline }

class Officer {
  final String id;
  final String name;
  final String badge;
  final OfficerStatus status;
  final LatLng location;
  final DateTime lastUpdate;
  final String? currentDutyId;
  final UserRole role;
  final String email;

  Officer({
    required this.id,
    required this.name,
    required this.badge,
    required this.status,
    required this.location,
    required this.lastUpdate,
    this.currentDutyId,
    required this.role,
    required this.email,
  });

  factory Officer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location'] as GeoPoint;
    
    return Officer(
      id: doc.id,
      name: data['name'] ?? '',
      badge: data['badge'] ?? '',
      status: OfficerStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'offline'),
        orElse: () => OfficerStatus.offline,
      ),
      location: LatLng(geoPoint.latitude, geoPoint.longitude),
      lastUpdate: (data['lastUpdate'] as Timestamp).toDate(),
      currentDutyId: data['currentDutyId'],
      role: UserRoleExtension.fromString(data['role'] ?? 'field_officer'),
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'badge': badge,
      'status': status.toString().split('.').last,
      'location': GeoPoint(location.latitude, location.longitude),
      'lastUpdate': Timestamp.fromDate(lastUpdate),
      'currentDutyId': currentDutyId,
      'role': role.value,
      'email': email,
    };
  }
}
