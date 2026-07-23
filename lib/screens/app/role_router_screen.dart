import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/admin/admin_role_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../admin/admin_shell_screen.dart';
import 'app_shell_screen.dart';

/// Sits between [AuthGateScreen] and the two possible app shells. Once the
/// user is authenticated, resolves whether they are an admin (via
/// [AdminRoleViewModel], a client-side read used only for UI routing — see
/// that class's doc comment for the security note) and renders
/// [AdminShellScreen] or the normal [AppShell] accordingly.
class RoleRouterScreen extends StatefulWidget {
  const RoleRouterScreen({super.key});

  @override
  State<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends State<RoleRouterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthViewModel>().currentUser?.uid;
      context.read<AdminRoleViewModel>().refreshForUser(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AdminRoleViewModel>();

    if (role.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    return role.isAdmin ? const AdminShellScreen() : const AppShell();
  }
}
