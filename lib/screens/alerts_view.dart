import 'package:copmap_flutter/models/alert.dart';
import 'package:copmap_flutter/services/database_service.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class AlertsView extends StatelessWidget {
  const AlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alerts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          const Text('Monitor and manage system alerts', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          StreamBuilder<List<Alert>>(
            stream: db.getAlertsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final alerts = snapshot.data ?? [];
              final activeAlerts = alerts.where((a) => !a.resolved).toList();
              final resolvedAlerts = alerts.where((a) => a.resolved).toList();

              if (alerts.isEmpty) {
                return const Center(child: Text("No alerts found"));
              }

              return Column(
                children: [
                  if (activeAlerts.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.statusOffline.withValues(alpha: 0.1),
                        border: Border.all(color: AppTheme.statusOffline.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertTriangle, color: AppTheme.statusOffline),
                          const SizedBox(width: 12),
                          Text(
                            '${activeAlerts.length} active alerts requiring attention',
                            style: const TextStyle(color: AppTheme.statusOffline, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                  // Active Alerts Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.statusOffline, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              const Text('Active Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (activeAlerts.isEmpty)
                             const Center(child: Padding(
                               padding: EdgeInsets.all(24.0),
                               child: Text("All clear"),
                             ))
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activeAlerts.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final alert = activeAlerts[index];
                                return _AlertItem(alert: alert, onResolve: () => db.resolveAlert(alert.id));
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Resolved Alerts
                  if (resolvedAlerts.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(LucideIcons.checkCircle2, size: 16, color: AppTheme.statusActive),
                                SizedBox(width: 8),
                                Text('Resolved Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: resolvedAlerts.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final alert = resolvedAlerts[index];
                                return _AlertItem(alert: alert, isResolved: true);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final Alert alert;
  final bool isResolved;
  final VoidCallback? onResolve;

  const _AlertItem({required this.alert, this.isResolved = false, this.onResolve});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;
    
    switch (alert.type) {
      case AlertType.batteryLow:
        icon = LucideIcons.battery;
        label = "Battery Low";
        break;
      case AlertType.trackingStopped:
        icon = LucideIcons.mapPinOff;
        label = "Tracking Stopped";
        break;
      case AlertType.offline:
        icon = LucideIcons.wifiOff;
        label = "Device Offline";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: isResolved ? 0.3 : 0.5),
        border: Border.all(color: isResolved ? Colors.transparent : AppTheme.statusOffline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isResolved ? Colors.grey.withValues(alpha: 0.1) : AppTheme.statusOffline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isResolved ? Colors.grey : AppTheme.statusOffline, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isResolved ? AppTheme.statusActive : AppTheme.statusOffline).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isResolved ? 'Resolved' : 'Active',
                        style: TextStyle(
                          color: isResolved ? AppTheme.statusActive : AppTheme.statusOffline,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${alert.officerName} • ${DateFormat.Hm().format(alert.timestamp)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          if (!isResolved && onResolve != null)
            TextButton(
              onPressed: onResolve,
              child: const Text('Mark Resolved', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
    );
  }
}
