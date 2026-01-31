import 'package:flutter/material.dart';
import 'package:copmap_flutter/models/duty.dart';
import 'package:copmap_flutter/models/officer.dart';
import 'package:copmap_flutter/providers/auth_provider.dart';
import 'package:copmap_flutter/services/database_service.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OfficerProfileScreen extends StatefulWidget {
  final String officerId;
  final Officer officer;

  const OfficerProfileScreen({
    super.key,
    required this.officerId,
    required this.officer,
  });

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: Text(
                        widget.officer.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.officer.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.officer.badge,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.statusActive.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.statusActive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Account Info
          const Text(
            'Account Information',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: LucideIcons.mail,
                    label: 'Email',
                    value: authProvider.user?.email ?? 'Not available',
                  ),
                  const Divider(height: 16),
                  _InfoRow(
                    icon: LucideIcons.calendar,
                    label: 'Last Update',
                    value: DateFormat.yMd().add_jm().format(
                      widget.officer.lastUpdate,
                    ),
                  ),
                  const Divider(height: 16),
                  _InfoRow(
                    icon: LucideIcons.mapPin,
                    label: 'Current Location',
                    value:
                        '${widget.officer.location.latitude.toStringAsFixed(4)}, ${widget.officer.location.longitude.toStringAsFixed(4)}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Duty History
          const Text(
            'Recent Duties',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Duty>>(
            stream: _db.getActiveDutiesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final duties = snapshot.data ?? [];
              final myDuties = duties
                  .where((d) => d.assignedOfficerIds.contains(widget.officerId))
                  .toList();

              if (myDuties.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No duty history',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myDuties.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final duty = myDuties[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                duty.area,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: duty.type == DutyType.patrolling
                                      ? AppTheme.primary.withValues(alpha: 0.2)
                                      : AppTheme.statusWarning.withValues(
                                          alpha: 0.2,
                                        ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  duty.type.toString().split('.').last,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: duty.type == DutyType.patrolling
                                        ? AppTheme.primary
                                        : AppTheme.statusWarning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat.jm().format(duty.startTime)} - ${DateFormat.jm().format(duty.endTime)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Settings Section
          const Text(
            'Settings',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.bell),
                  title: const Text('Notifications'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16),
                  onTap: () {
                    // TODO: Navigate to notification settings
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(LucideIcons.shield),
                  title: const Text('Privacy & Security'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16),
                  onTap: () {
                    // TODO: Navigate to privacy settings
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(LucideIcons.helpCircle),
                  title: const Text('Help & Support'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16),
                  onTap: () {
                    // TODO: Open help
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogoutDialog(context, authProvider);
              },
              icon: const Icon(LucideIcons.logOut),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.statusOffline,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
