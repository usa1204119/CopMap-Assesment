import 'package:cloud_firestore/cloud_firestore.dart';

enum DutyType { patrolling, bandobast }

class Duty {
  final String id;
  final DutyType type;
  final String area;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> assignedOfficerIds;
  final double? latitude;
  final double? longitude;

  Duty({
    required this.id,
    required this.type,
    required this.area,
    required this.startTime,
    required this.endTime,
    required this.assignedOfficerIds,
    this.latitude,
    this.longitude,
  });

  factory Duty.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Duty(
      id: doc.id,
      type: DutyType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'patrolling'),
        orElse: () => DutyType.patrolling,
      ),
      area: data['area'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      assignedOfficerIds: List<String>.from(data['assignedOfficerIds'] ?? []),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'area': area,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'assignedOfficerIds': assignedOfficerIds,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
