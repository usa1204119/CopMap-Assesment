import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class Sidebar extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;
  final int alertCount;

  const Sidebar({
    super.key,
    required this.activeTab,
    required this.onTabChange,
    this.alertCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF0F172A), // Even darker sidebar bg
      child: Column(
        children: [
          const SizedBox(height: 20),
          _NavItem(
            label: 'Dashboard',
            icon: LucideIcons.layoutDashboard,
            value: 'dashboard',
            isActive: activeTab == 'dashboard',
            onTap: () => onTabChange('dashboard'),
          ),
          _NavItem(
            label: 'Create Duty',
            icon: LucideIcons.plus,
            value: 'create-duty',
            isActive: activeTab == 'create-duty',
            onTap: () => onTabChange('create-duty'),
          ),
          _NavItem(
            label: 'Live Monitoring',
            icon: LucideIcons.mapPin,
            value: 'monitoring',
            isActive: activeTab == 'monitoring',
            onTap: () => onTabChange('monitoring'),
          ),
          _NavItem(
            label: 'Alerts',
            icon: LucideIcons.bell,
            value: 'alerts',
            isActive: activeTab == 'alerts',
            onTap: () => onTabChange('alerts'),
            badgeCount: alertCount,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.value,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppTheme.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (badgeCount > 0) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.statusOffline,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
