import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin/admin_user_summary.dart';
import '../../utils/app_keys.dart';
import '../../viewmodels/admin/admin_users_view_model.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUsersViewModel>().loadFirstPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminUsersViewModel>();

    return SafeArea(
      key: AppKeys.adminUsersScreen,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Users', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                if (!viewModel.isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => context.read<AdminUsersViewModel>().loadFirstPage(),
                  ),
              ],
            ),
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : viewModel.users.isEmpty
                  ? const Center(child: Text('No users found.'))
                  : ListView.builder(
                      itemCount: viewModel.users.length + (viewModel.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= viewModel.users.length) {
                          if (!viewModel.isLoadingMore) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              context.read<AdminUsersViewModel>().loadMore();
                            });
                          }
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final user = viewModel.users[index];
                        return _UserTile(
                          user: user,
                          isMutating: viewModel.isMutating(user.uid),
                          onDisabledChanged: (disabled) =>
                              context.read<AdminUsersViewModel>().setDisabled(user.uid, disabled),
                          onRoleChanged: (isAdmin) =>
                              context.read<AdminUsersViewModel>().setRole(user.uid, isAdmin),
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

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isMutating,
    required this.onDisabledChanged,
    required this.onRoleChanged,
  });

  final AdminUserSummary user;
  final bool isMutating;
  final ValueChanged<bool> onDisabledChanged;
  final ValueChanged<bool> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: AppKeys.adminUserItem(user.uid),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              child: Text((user.displayName ?? user.email ?? '?').substring(0, 1).toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? user.email ?? user.uid,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (user.email != null)
                    Text(user.email!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (isMutating)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            Row(
              children: [
                const Text('Admin'),
                Switch(
                  key: AppKeys.adminUserRoleToggle(user.uid),
                  value: user.isAdmin,
                  onChanged: isMutating ? null : onRoleChanged,
                ),
              ],
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                const Text('Disabled'),
                Switch(
                  key: AppKeys.adminUserDisableToggle(user.uid),
                  value: user.disabled,
                  onChanged: isMutating ? null : onDisabledChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
