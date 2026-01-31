import 'package:flutter/material.dart';
import 'package:copmap_flutter/models/alert.dart';
import 'package:copmap_flutter/models/officer.dart';
import 'package:copmap_flutter/services/database_service.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class OfficerAlertsScreen extends StatefulWidget {
  final String officerId;
  final Officer officer;

  const OfficerAlertsScreen({
    super.key,
    required this.officerId,
    required this.officer,
  });

  @override
  State<OfficerAlertsScreen> createState() => _OfficerAlertsScreenState();
}

class _OfficerAlertsScreenState extends State<OfficerAlertsScreen> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alerts',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const Text(
            'Messages from station',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Send Alert Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showSendAlertDialog();
              },
              icon: const Icon(LucideIcons.bell),
              label: const Text('Send Alert to Station'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.statusWarning,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Alerts List
          StreamBuilder<List<Alert>>(
            stream: _db.getAlertsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allAlerts = snapshot.data ?? [];
              final myAlerts = allAlerts
                  .where((a) => a.officerId == widget.officerId)
                  .toList();

              if (myAlerts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        const Icon(
                          LucideIcons.inbox,
                          size: 40,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No alerts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'All clear - no alerts from station',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final activeAlerts = myAlerts.where((a) => !a.resolved).toList();
              final resolvedAlerts = myAlerts.where((a) => a.resolved).toList();

              return Column(
                children: [
                  if (activeAlerts.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Alerts',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeAlerts.length,
                          separatorBuilder: (c, i) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _AlertCard(
                              alert: activeAlerts[index],
                              onResolve: () =>
                                  _db.resolveAlert(activeAlerts[index].id),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  if (resolvedAlerts.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resolved',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: resolvedAlerts.length,
                          separatorBuilder: (c, i) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _AlertCard(
                              alert: resolvedAlerts[index],
                              isResolved: true,
                            );
                          },
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSendAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Alert to Station'),
        content: const Text(
          'Alert types:\n\n'
          '• Battery Low: Device battery critically low\n'
          '• Tracking Stopped: GPS tracking stopped\n'
          '• Emergency: Immediate assistance needed',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _sendAlert(AlertType.batteryLow);
              Navigator.pop(context);
            },
            child: const Text('Battery Low'),
          ),
          TextButton(
            onPressed: () {
              _sendAlert(AlertType.trackingStopped);
              Navigator.pop(context);
            },
            child: const Text('Tracking Stopped'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendAlert(AlertType type) async {
    try {
      // Send alert to Firestore to notify station master
      await _db.sendAlertFromOfficer(
        widget.officerId,
        widget.officer.name,
        type,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${type.toString().split('.').last} alert sent to station',
            ),
            backgroundColor: AppTheme.statusWarning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending alert: $e'),
            backgroundColor: AppTheme.statusOffline,
          ),
        );
      }
    }
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onResolve;
  final bool isResolved;

  const _AlertCard({
    required this.alert,
    this.onResolve,
    this.isResolved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isResolved
            ? Colors.grey.withValues(alpha: 0.1)
            : _getAlertTypeColor(alert.type).withValues(alpha: 0.1),
        border: Border.all(
          color: isResolved
              ? Colors.grey.withValues(alpha: 0.3)
              : _getAlertTypeColor(alert.type).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getAlertTypeIcon(alert.type),
            color: isResolved ? Colors.grey : _getAlertTypeColor(alert.type),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAlertTypeLabel(alert.type),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isResolved ? Colors.grey : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMd().add_jm().format(alert.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isResolved ? Colors.grey : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (!isResolved && onResolve != null)
            TextButton(onPressed: onResolve, child: const Text('Resolve')),
        ],
      ),
    );
  }

  Color _getAlertTypeColor(AlertType type) {
    switch (type) {
      case AlertType.batteryLow:
        return AppTheme.statusWarning;
      case AlertType.trackingStopped:
        return AppTheme.statusOffline;
      case AlertType.offline:
        return AppTheme.statusOffline;
    }
  }

  IconData _getAlertTypeIcon(AlertType type) {
    switch (type) {
      case AlertType.batteryLow:
        return LucideIcons.battery;
      case AlertType.trackingStopped:
        return LucideIcons.navigation;
      case AlertType.offline:
        return LucideIcons.wifiOff;
    }
  }

  String _getAlertTypeLabel(AlertType type) {
    switch (type) {
      case AlertType.batteryLow:
        return 'Battery Low';
      case AlertType.trackingStopped:
        return 'Tracking Stopped';
      case AlertType.offline:
        return 'Offline';
    }
  }
}
