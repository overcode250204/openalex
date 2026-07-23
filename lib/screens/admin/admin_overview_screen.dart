import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_keys.dart';
import '../../viewmodels/admin/admin_dashboard_view_model.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDashboardViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminDashboardViewModel>();

    return SafeArea(
      key: AppKeys.adminOverviewScreen,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 700 ? 3 : 1;
                  final stats = viewModel.stats;
                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _StatCard(
                        label: 'Total Users',
                        value: stats?.totalUsers,
                        icon: Icons.people,
                        color: Colors.blue,
                        isLoading: viewModel.isLoading,
                      ),
                      _StatCard(
                        label: 'Admins',
                        value: stats?.totalAdmins,
                        icon: Icons.admin_panel_settings,
                        color: Colors.purple,
                        isLoading: viewModel.isLoading,
                      ),
                      _StatCard(
                        label: 'Uploaded Reports',
                        value: stats?.totalReports,
                        icon: Icons.description,
                        color: Colors.teal,
                        isLoading: viewModel.isLoading,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isLoading,
  });

  final String label;
  final int? value;
  final IconData icon;
  final MaterialColor color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color.shade700, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      '${value ?? 0}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
