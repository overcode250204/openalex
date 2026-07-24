class AdminDashboardStats {
  final int totalUsers;
  final int totalAdmins;
  final int totalReports;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalAdmins,
    required this.totalReports,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalAdmins: (json['totalAdmins'] as num?)?.toInt() ?? 0,
      totalReports: (json['totalReports'] as num?)?.toInt() ?? 0,
    );
  }
}
