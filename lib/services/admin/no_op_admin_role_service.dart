import 'admin_role_service.dart';

class NoOpAdminRoleService implements AdminRoleService {
  const NoOpAdminRoleService();

  @override
  Future<bool> isAdmin(String uid) async => false;
}
