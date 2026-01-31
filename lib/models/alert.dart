import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { batteryLow, trackingStopped, offline }

class Alert {
  final String id;
  final AlertType type;
  final String officerId;
  final String officerName;
  final DateTime timestamp;
  final bool resolved;

  Alert({
    required this.id,
    required this.type,
    required this.officerId,
    required this.officerName,
    required this.timestamp,
    required this.resolved,
  });

  factory Alert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final typeStr = data['type'] as String? ?? 'offline';
    
    AlertType type;
    switch (typeStr) {
      case 'battery_low':
        type = AlertType.batteryLow;
        break;
      case 'tracking_stopped':
        type = AlertType.trackingStopped;
        break;
      case 'offline':
      default:
        type = AlertType.offline;
        break;
    }
    
    return Alert(
      id: doc.id,
      type: type,
      officerId: data['officerId'] ?? '',
      officerName: data['officerName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      resolved: data['resolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    String typeStr;
    switch (type) {
      case AlertType.batteryLow:
        typeStr = 'battery_low';
        break;
      case AlertType.trackingStopped:
        typeStr = 'tracking_stopped';
        break;
      case AlertType.offline:
        typeStr = 'offline';
        break;
    }

    return {
      'type': typeStr,
      'officerId': officerId,
      'officerName': officerName,
      'timestamp': Timestamp.fromDate(timestamp),
      'resolved': resolved,
    };
  }
}
