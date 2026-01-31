import 'package:copmap_flutter/models/duty.dart';
import 'package:copmap_flutter/models/officer.dart';
import 'package:copmap_flutter/services/database_service.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:copmap_flutter/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final padding = ResponsiveUtil.getResponsivePadding(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: ResponsiveUtil.getResponsiveFontSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 28,
              ),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Overview of current operations',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Stats Grid - Responsive
          StreamBuilder(
            stream: _getStatsStream(db),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? _DashboardStats.empty();
              final isMobile = ResponsiveUtil.isMobile(context);

              if (isMobile) {
                return Column(
                  children: [
                    _StatCard(
                      title: 'Active Duties',
                      value: stats.activeDuties.toString(),
                      subtitle: 'Currently in progress',
                      icon: LucideIcons.shield,
                      iconColor: AppTheme.primary,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Officers on Duty',
                      value: stats.officersOnDuty.toString(),
                      subtitle: 'Active personnel',
                      icon: LucideIcons.users,
                      iconColor: AppTheme.statusActive,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Alerts',
                      value: stats.alertsCount.toString(),
                      subtitle: stats.alertsCount > 0
                          ? 'Requires attention'
                          : 'All clear',
                      icon: LucideIcons.alertTriangle,
                      iconColor: stats.alertsCount > 0
                          ? AppTheme.statusOffline
                          : Colors.grey,
                      borderColor: stats.alertsCount > 0
                          ? AppTheme.statusOffline
                          : null,
                      valueColor: stats.alertsCount > 0
                          ? AppTheme.statusOffline
                          : null,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Active Duties',
                      value: stats.activeDuties.toString(),
                      subtitle: 'Currently in progress',
                      icon: LucideIcons.shield,
                      iconColor: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Officers on Duty',
                      value: stats.officersOnDuty.toString(),
                      subtitle: 'Active personnel',
                      icon: LucideIcons.users,
                      iconColor: AppTheme.statusActive,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Alerts',
                      value: stats.alertsCount.toString(),
                      subtitle: stats.alertsCount > 0
                          ? 'Requires attention'
                          : 'All clear',
                      icon: LucideIcons.alertTriangle,
                      iconColor: stats.alertsCount > 0
                          ? AppTheme.statusOffline
                          : Colors.grey,
                      borderColor: stats.alertsCount > 0
                          ? AppTheme.statusOffline
                          : null,
                      valueColor: stats.alertsCount > 0
                          ? AppTheme.statusOffline
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Recent Duties
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.secondary),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Duties',
                    style: TextStyle(
                      fontSize: ResponsiveUtil.getResponsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 17,
                        desktop: 18,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Duty>>(
                    stream: db.getActiveDutiesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final duties = snapshot.data ?? [];
                      if (duties.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.shield,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No active duties',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: duties.length > 5 ? 5 : duties.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final duty = duties[index];
                          final isPatrol = duty.type == DutyType.patrolling;

                          return _DutyDetailCard(
                            duty: duty,
                            db: db,
                            isPatrol: isPatrol,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<_DashboardStats> _getStatsStream(DatabaseService db) {
    return db.getFieldOfficersStream().asyncMap((officers) async {
      final duties = await db.getActiveDutiesStream().first;
      final alerts = await db.getAlertsStream().first;

      return _DashboardStats(
        activeDuties: duties.length,
        officersOnDuty: officers
            .where((o) => o.status == OfficerStatus.active)
            .length,
        alertsCount: alerts.where((a) => !a.resolved).length,
      );
    });
  }
}

// Helper class for local aggregation
class _DashboardStats {
  final int activeDuties;
  final int officersOnDuty;
  final int alertsCount;

  _DashboardStats({
    required this.activeDuties,
    required this.officersOnDuty,
    required this.alertsCount,
  });

  factory _DashboardStats.empty() =>
      _DashboardStats(activeDuties: 0, officersOnDuty: 0, alertsCount: 0);
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? borderColor;
  final Color? valueColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.borderColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor ?? AppTheme.secondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, size: 20, color: iconColor),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detailed duty card with edit and delete functionality
class _DutyDetailCard extends StatelessWidget {
  final Duty duty;
  final DatabaseService db;
  final bool isPatrol;

  const _DutyDetailCard({
    required this.duty,
    required this.db,
    required this.isPatrol,
  });

  Future<void> _showEditDutyDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    late String updatedArea;
    late DateTime updatedStartTime;
    late DateTime updatedEndTime;

    updatedArea = duty.area;
    updatedStartTime = duty.startTime;
    updatedEndTime = duty.endTime;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Duty'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: updatedArea,
                    decoration: const InputDecoration(labelText: 'Area'),
                    onChanged: (value) => updatedArea = value,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Area required' : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start Time: ${DateFormat.jm().format(updatedStartTime)}',
                  ),
                  const SizedBox(height: 8),
                  Text('End Time: ${DateFormat.jm().format(updatedEndTime)}'),
                  const SizedBox(height: 12),
                  Text('Officers Assigned: ${duty.assignedOfficerIds.length}'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final updatedDuty = Duty(
                    id: duty.id,
                    type: duty.type,
                    area: updatedArea,
                    startTime: updatedStartTime,
                    endTime: updatedEndTime,
                    assignedOfficerIds: duty.assignedOfficerIds,
                    latitude: duty.latitude,
                    longitude: duty.longitude,
                  );

                  try {
                    await db.updateDuty(updatedDuty);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Duty updated successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating duty: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDuty(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Duty'),
          content: const Text(
            'Are you sure you want to delete this duty? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm ?? false) {
      try {
        await db.deleteDuty(duty.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Duty deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting duty: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.secondary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPatrol
                      ? AppTheme.primary.withValues(alpha: 0.2)
                      : AppTheme.statusWarning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPatrol ? 'PATROLLING' : 'BANDOBAST',
                  style: TextStyle(
                    color: isPatrol ? AppTheme.primary : AppTheme.statusWarning,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDutyDialog(context);
                  } else if (value == 'delete') {
                    _deleteDuty(context);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(LucideIcons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Area/Location
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  duty.area,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Time details
          Row(
            children: [
              Icon(LucideIcons.clock, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                DateFormat.jm().format(duty.startTime),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Text(
                ' to ',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                DateFormat.jm().format(duty.endTime),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Officers assigned
          Row(
            children: [
              Icon(LucideIcons.users, size: 16, color: AppTheme.statusActive),
              const SizedBox(width: 8),
              Text(
                '${duty.assignedOfficerIds.length} officers assigned',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          if (duty.latitude != null && duty.longitude != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(LucideIcons.navigation, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${duty.latitude?.toStringAsFixed(4)}, ${duty.longitude?.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
