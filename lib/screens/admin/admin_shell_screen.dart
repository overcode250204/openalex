import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_keys.dart';
import '../../viewmodels/auth_view_model.dart';
import 'admin_notifications_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_remote_config_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';

/// Root navigation shell for the admin web dashboard. Wide screens get a
/// permanent [NavigationRail]; narrow screens fall back to a [Drawer],
/// following the only responsive-layout precedent in this codebase
/// (lib/widgets/analytics/topic_summary_grid.dart's LayoutBuilder breakpoint).
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    _AdminDestination('Overview', Icons.dashboard_outlined, Icons.dashboard, AppKeys.adminNavOverview),
    _AdminDestination('Users', Icons.people_outline, Icons.people, AppKeys.adminNavUsers),
    _AdminDestination('Remote Config', Icons.tune_outlined, Icons.tune, AppKeys.adminNavRemoteConfig),
    _AdminDestination('Notifications', Icons.notifications_outlined, Icons.notifications, AppKeys.adminNavNotifications),
    _AdminDestination('Reports', Icons.description_outlined, Icons.description, AppKeys.adminNavReports),
  ];

  static const _screens = [
    AdminOverviewScreen(),
    AdminUsersScreen(),
    AdminRemoteConfigScreen(),
    AdminNotificationsScreen(),
    AdminReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: AppKeys.adminShellScreen,
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                _AdminNavigationRail(
                  destinations: _destinations,
                  selectedIndex: _selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: _screens),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(_destinations[_selectedIndex].label)),
          drawer: Drawer(
            child: SafeArea(
              child: ListView(
                children: [
                  const DrawerHeader(
                    child: Text(
                      'Admin Dashboard',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (var i = 0; i < _destinations.length; i++)
                    ListTile(
                      key: _destinations[i].navKey,
                      leading: Icon(i == _selectedIndex ? _destinations[i].activeIcon : _destinations[i].icon),
                      title: Text(_destinations[i].label),
                      selected: i == _selectedIndex,
                      onTap: () {
                        setState(() => _selectedIndex = i);
                        Navigator.of(context).pop();
                      },
                    ),
                  const Divider(),
                  ListTile(
                    key: AppKeys.logoutButton,
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign out'),
                    onTap: () => context.read<AuthViewModel>().signOut(),
                  ),
                ],
              ),
            ),
          ),
          body: IndexedStack(index: _selectedIndex, children: _screens),
        );
      },
    );
  }
}

class _AdminNavigationRail extends StatelessWidget {
  const _AdminNavigationRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: NavigationRail(
            extended: true,
            minExtendedWidth: 220,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelect,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Admin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon, key: d.navKey),
                  selectedIcon: Icon(d.activeIcon),
                  label: Text(d.label),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextButton.icon(
            key: AppKeys.logoutButton,
            onPressed: () => context.read<AuthViewModel>().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ),
      ],
    );
  }
}

class _AdminDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Key navKey;

  const _AdminDestination(this.label, this.icon, this.activeIcon, this.navKey);
}
