import 'package:copmap_flutter/models/alert.dart';
import 'package:copmap_flutter/screens/alerts_view.dart';
import 'package:copmap_flutter/screens/create_duty_view.dart';
import 'package:copmap_flutter/screens/dashboard_view.dart';
import 'package:copmap_flutter/screens/monitoring_view.dart';
import 'package:copmap_flutter/services/database_service.dart';
import 'package:copmap_flutter/widgets/header.dart';
import 'package:copmap_flutter/widgets/sidebar.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _activeTab = 'dashboard';
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          StreamBuilder<List<Alert>>(
            stream: _db.getAlertsStream(),
            builder: (context, snapshot) {
              final alerts = snapshot.data ?? [];
              final unresolvedAlertCount = alerts.where((alert) => !alert.resolved).length;
              
              return Sidebar(
                activeTab: _activeTab, 
                onTabChange: (tab) => setState(() => _activeTab = tab),
                alertCount: unresolvedAlertCount,
              );
            },
          ),
          Expanded(
            child: Column(
              children: [
                const Header(
                  stationName: 'Central Police Station, District HQ',
                ),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeTab) {
      case 'dashboard':
        return const DashboardView();
      case 'create-duty':
        return const CreateDutyView();
      case 'monitoring':
        return const MonitoringView();
      case 'alerts':
        return const AlertsView();
      default:
        return const SizedBox();
    }
  }
}
