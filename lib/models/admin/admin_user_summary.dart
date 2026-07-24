class AdminUserSummary {
  final String uid;
  final String? email;
  final String? displayName;
  final bool disabled;
  final DateTime? createdAt;
  final bool isAdmin;

  const AdminUserSummary({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.disabled,
    required this.createdAt,
    required this.isAdmin,
  });

  AdminUserSummary copyWith({bool? disabled, bool? isAdmin}) {
    return AdminUserSummary(
      uid: uid,
      email: email,
      displayName: displayName,
      disabled: disabled ?? this.disabled,
      createdAt: createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      disabled: json['disabled'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
