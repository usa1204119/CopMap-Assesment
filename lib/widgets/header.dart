import 'package:copmap_flutter/providers/auth_provider.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class Header extends StatelessWidget {
  final String stationName;

  const Header({
    super.key,
    required this.stationName,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userEmail = authProvider.user?.email ?? 'Unknown User';

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(bottom: BorderSide(color: AppTheme.secondary)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(LucideIcons.shield, color: AppTheme.primary, size: 28),
          const SizedBox(width: 12),
          const Text(
            'CopMap',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 20,
            width: 1,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 16),
          Text(
            stationName,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const Spacer(),
          const Icon(LucideIcons.user, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            userEmail,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(width: 24),
          TextButton.icon(
            onPressed: () async {
              await authProvider.signOut();
            },
            icon: const Icon(LucideIcons.logOut, size: 16, color: Colors.grey),
            label: const Text('Logout', style: TextStyle(color: Colors.grey)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
