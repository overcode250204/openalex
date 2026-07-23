import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/report/uploaded_report.dart';
import '../../utils/app_keys.dart';
import '../../utils/formatters.dart';
import '../../viewmodels/admin/admin_reports_view_model.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminReportsViewModel>().loadFirstPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminReportsViewModel>();

    return SafeArea(
      key: AppKeys.adminReportsScreen,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Uploaded Reports', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                if (!viewModel.isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => context.read<AdminReportsViewModel>().loadFirstPage(),
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
                  : viewModel.reports.isEmpty
                  ? const Center(child: Text('No reports uploaded yet.'))
                  : ListView.builder(
                      itemCount: viewModel.reports.length + (viewModel.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= viewModel.reports.length) {
                          if (!viewModel.isLoadingMore) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              context.read<AdminReportsViewModel>().loadMore();
                            });
                          }
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _ReportTile(report: viewModel.reports[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final UploadedReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: AppKeys.adminReportItem(report.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf),
        title: Text(report.topic.isEmpty ? report.fileName : report.topic),
        subtitle: Text(
          'User: ${report.userId ?? 'unknown'} · '
          '${Formatters.formatCompactNumber(report.sizeBytes)} bytes · '
          '${report.uploadedAt.toLocal()}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: report.downloadUrl.isEmpty
              ? null
              : () => launchUrl(
                  Uri.parse(report.downloadUrl),
                  mode: LaunchMode.externalApplication,
                ),
        ),
      ),
    );
  }
}
