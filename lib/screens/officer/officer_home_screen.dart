import 'package:flutter/material.dart';
import 'package:copmap_flutter/models/duty.dart';
import 'package:copmap_flutter/models/officer.dart';
import 'package:copmap_flutter/models/alert.dart';
import 'package:copmap_flutter/services/database_service.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';

class OfficerHomeScreen extends StatefulWidget {
  final String officerId;
  final Officer officer;

  const OfficerHomeScreen({
    super.key,
    required this.officerId,
    required this.officer,
  });

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  final DatabaseService _db = DatabaseService();
  final Battery _battery = Battery();
  Duty? _currentDuty;
  bool _isDutyActive = false;
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.charging;
  late StreamSubscription<BatteryState> _batteryStateStream;

  @override
  void initState() {
    super.initState();
    _loadCurrentDuty();
    _initBatteryTracking();
  }

  void _initBatteryTracking() {
    _battery.batteryLevel.then((level) {
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }
    });

    _batteryStateStream = _battery.onBatteryStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _batteryState = state;
        });
      }
    });

    Timer.periodic(const Duration(seconds: 60), (timer) async {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }
    });
  }

  @override
  void dispose() {
    _batteryStateStream.cancel();
    super.dispose();
  }

  void _loadCurrentDuty() {
    _db.getActiveDutiesStream().listen((duties) {
      final duty = duties.firstWhere(
        (d) => d.assignedOfficerIds.contains(widget.officerId),
        orElse: () => Duty(
          id: '',
          type: DutyType.patrolling,
          area: '',
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          assignedOfficerIds: [],
        ),
      );

      if (mounted) {
        setState(() {
          _currentDuty = duty.id.isNotEmpty ? duty : null;
        });
      }
    });
  }

  void _toggleDuty() async {
    if (_currentDuty == null) return;

    try {
      final newStatus = _isDutyActive ? 'paused' : 'active';

      await _db.updateDutyStatus(_currentDuty!.id, widget.officerId, newStatus);

      if (mounted) {
        setState(() {
          _isDutyActive = !_isDutyActive;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'active' ? 'Duty started' : 'Duty paused',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            backgroundColor: newStatus == 'active'
                ? AppTheme.statusActive
                : AppTheme.statusWarning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating duty: $e',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.statusOffline,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendEmergencyAlert() async {
    try {
      await _db.sendAlertFromOfficer(
        widget.officerId,
        widget.officer.name,
        AlertType.offline,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Emergency alert sent to station',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.statusOffline,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending alert: $e',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.statusOffline,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.05),
            Colors.blue.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOfficerInfoCard(),
            const SizedBox(height: 28),
            _buildDeviceStatusSection(),
            const SizedBox(height: 28),
            _buildDutySection(),
            const SizedBox(height: 28),
            _buildActionButtons(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(38),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.officer.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.officer.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Badge: ${widget.officer.badge}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.officer.status),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(
                                widget.officer.status,
                              ).withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.officer.status
                            .toString()
                            .split('.')
                            .last
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusSection() {
    final batteryColor = _batteryLevel > 50
        ? AppTheme.statusActive
        : _batteryLevel > 20
        ? AppTheme.statusWarning
        : AppTheme.statusOffline;

    final isCharging = _batteryState == BatteryState.charging;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Device Status',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color.fromARGB(255, 208, 210, 214),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Battery Level',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: batteryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isCharging ? LucideIcons.zap : LucideIcons.battery,
                            size: 26,
                            color: batteryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_batteryLevel%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (isCharging)
                              Text(
                                'Charging',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: batteryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 120,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: _batteryLevel / 100,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              batteryColor,
                              batteryColor.withValues(alpha: 0.75),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: batteryColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDutySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assigned Duty',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color.fromARGB(255, 208, 210, 214),
          ),
        ),
        const SizedBox(height: 16),
        if (_currentDuty != null)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentDuty!.area,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _currentDuty!.type == DutyType.patrolling
                                  ? AppTheme.primary.withValues(alpha: 0.15)
                                  : AppTheme.statusWarning.withValues(
                                      alpha: 0.15,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _currentDuty!.type == DutyType.patrolling
                                    ? AppTheme.primary.withValues(alpha: 0.3)
                                    : AppTheme.statusWarning.withValues(
                                        alpha: 0.3,
                                      ),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _currentDuty!.type
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _currentDuty!.type == DutyType.patrolling
                                    ? AppTheme.primary
                                    : AppTheme.statusWarning,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isDutyActive
                            ? AppTheme.statusActive.withValues(alpha: 0.15)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isDutyActive
                            ? LucideIcons.checkCircle2
                            : LucideIcons.circle,
                        size: 24,
                        color: _isDutyActive
                            ? AppTheme.statusActive
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.clock,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${DateFormat.jm().format(_currentDuty!.startTime)} - ${DateFormat.jm().format(_currentDuty!.endTime)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.users,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_currentDuty!.assignedOfficerIds.length} officers on duty',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      LucideIcons.inbox,
                      size: 48,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No Active Duty',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Awaiting assignment from station',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_currentDuty != null) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      (_isDutyActive
                              ? AppTheme.statusOffline
                              : AppTheme.statusActive)
                          .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _toggleDuty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDutyActive
                      ? AppTheme.statusOffline
                      : AppTheme.statusActive,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isDutyActive
                          ? LucideIcons.pauseCircle
                          : LucideIcons.playCircle,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isDutyActive ? 'End Duty' : 'Start Duty',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.statusOffline.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _sendEmergencyAlert,
              icon: const Icon(LucideIcons.alertTriangle, size: 20),
              label: const Text('Send Emergency Alert'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.statusOffline, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: AppTheme.statusOffline,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(OfficerStatus status) {
    switch (status) {
      case OfficerStatus.active:
        return AppTheme.statusActive;
      case OfficerStatus.issue:
        return AppTheme.statusWarning;
      case OfficerStatus.offline:
        return AppTheme.statusOffline;
    }
  }
}
