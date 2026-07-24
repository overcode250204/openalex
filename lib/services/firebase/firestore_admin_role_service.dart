import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin/admin_role_service.dart';

class FirestoreAdminRoleService implements AdminRoleService {
  FirestoreAdminRoleService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<bool> isAdmin(String uid) async {
    final doc = await _firestore.collection('admin_roles').doc(uid).get();
    return doc.exists && doc.data()?['role'] == 'admin';
  }
}
