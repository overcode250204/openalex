import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/auth/app_user.dart';
import '../../models/report/uploaded_report.dart';
import '../../utils/app_keys.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/selected_topic_view_model.dart';
import '../../viewmodels/uploaded_reports_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const _background = Color(0xFFF5F7FB);
  static const _primary = Color(0xFF2563EB);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _lastUserId;

  void _syncUploadedReports(AppUser? user) {
    final userId = user?.uid;
    if (userId == _lastUserId) return;

    _lastUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UploadedReportsViewModel>().load(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;
    final selectedTopic = context.watch<SelectedTopicViewModel>();
    final uploadedReports = context.watch<UploadedReportsViewModel>();

    _syncUploadedReports(user);

    return Scaffold(
      backgroundColor: ProfileScreen._background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: ProfileScreen._background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 16,
                12,
                isWide ? 32 : 16,
                24,
              ),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _ProfileCard(user: user)),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _WorkspaceCard(
                                selectedTopic: selectedTopic,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _ProfileCard(user: user),
                            const SizedBox(height: 16),
                            _WorkspaceCard(selectedTopic: selectedTopic),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: _UploadedReportsCard(viewModel: uploadedReports),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: _AccountActionsCard(auth: auth),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UploadedReportsCard extends StatelessWidget {
  const _UploadedReportsCard({required this.viewModel});

  final UploadedReportsViewModel viewModel;

  Future<void> _copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF link copied')));
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid PDF link')));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cannot open PDF link')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: AppKeys.uploadedReportsCard,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Uploaded PDF reports',
                    style: TextStyle(
                      color: ProfileScreen._ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: AppKeys.uploadedReportsRefreshButton,
                  tooltip: 'Refresh uploaded reports',
                  onPressed: viewModel.isLoading ? null : viewModel.refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Reports saved in Firestore after a successful S3 upload.',
              style: TextStyle(color: ProfileScreen._muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (viewModel.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (viewModel.errorMessage != null)
              _InlineStateBox(
                icon: Icons.error_outline,
                message: viewModel.errorMessage!,
              )
            else if (!viewModel.hasReports)
              const _InlineStateBox(
                icon: Icons.picture_as_pdf_outlined,
                message: 'No uploaded PDF reports yet.',
              )
            else
              ...viewModel.reports.map(
                (report) => _UploadedReportTile(
                  report: report,
                  onCopy: () => _copyLink(context, report.downloadUrl),
                  onOpen: () => _openLink(context, report.downloadUrl),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UploadedReportTile extends StatelessWidget {
  const _UploadedReportTile({
    required this.report,
    required this.onCopy,
    required this.onOpen,
  });

  final UploadedReport report;
  final VoidCallback onCopy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: AppKeys.uploadedReportItem(report.id),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.topic,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ProfileScreen._ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${report.fileName} - ${_formatBytes(report.sizeBytes)} - ${_formatDateTime(report.uploadedAt)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ProfileScreen._muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SelectableText(
            report.downloadUrl,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: AppKeys.uploadedReportCopyButton(report.id),
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy link'),
              ),
              FilledButton.icon(
                key: AppKeys.uploadedReportOpenButton(report.id),
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineStateBox extends StatelessWidget {
  const _InlineStateBox({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: ProfileScreen._muted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ProfileScreen._muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName;
    final email = _email;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _UserAvatar(displayName: displayName, photoUrl: user?.photoUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ProfileScreen._ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ProfileScreen._muted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow(
              icon: Icons.verified_user_outlined,
              label: 'Sign-in provider',
              value: 'Google via Firebase Auth',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.mail_outline,
              label: 'Email status',
              value: user?.isEmailVerified == true ? 'Verified' : 'Unverified',
            ),
          ],
        ),
      ),
    );
  }

  String get _displayName {
    final value = user?.displayName?.toString().trim();
    if (value != null && value.isNotEmpty) return value;

    final email = user?.email?.toString().trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;

    return 'Researcher';
  }

  String get _email {
    final value = user?.email?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    return 'No email available';
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.displayName, required this.photoUrl});

  final String displayName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final trimmedPhotoUrl = photoUrl?.trim();
    final hasPhoto = trimmedPhotoUrl != null && trimmedPhotoUrl.isNotEmpty;

    return CircleAvatar(
      radius: 36,
      backgroundColor: ProfileScreen._primary.withValues(alpha: 0.12),
      backgroundImage: hasPhoto ? NetworkImage(trimmedPhotoUrl) : null,
      child: hasPhoto
          ? null
          : Text(
              _initials(displayName),
              style: const TextStyle(
                color: ProfileScreen._primary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'R';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({required this.selectedTopic});

  final SelectedTopicViewModel selectedTopic;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Research workspace',
              style: TextStyle(
                color: ProfileScreen._ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your current context is restored while you explore.',
              style: TextStyle(color: ProfileScreen._muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            _InfoRow(
              icon: Icons.topic_outlined,
              label: 'Selected topic',
              value: selectedTopic.selectedTopic ?? 'No topic selected',
              trailing: selectedTopic.hasSelectedTopic
                  ? IconButton(
                      tooltip: 'Clear selected topic',
                      onPressed: selectedTopic.clearTopic,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActionsCard extends StatelessWidget {
  const _AccountActionsCard({required this.auth});

  final AuthViewModel auth;

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will need to sign in again to access your research dashboard.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Account',
              style: TextStyle(
                color: ProfileScreen._ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'You will be asked to sign in again after signing out.',
              style: TextStyle(color: ProfileScreen._muted, fontSize: 13),
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 16),
              _SignOutErrorBox(message: auth.errorMessage!),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: AppKeys.logoutButton,
              onPressed: auth.isLoading ? null : () => _confirmSignOut(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(
                  color: colorScheme.error.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: auth.isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.error,
                      ),
                    )
                  : const Icon(Icons.logout),
              label: Text(auth.isLoading ? 'Signing out...' : 'Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutErrorBox extends StatelessWidget {
  const _SignOutErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ProfileScreen._primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ProfileScreen._primary, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: ProfileScreen._muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ProfileScreen._ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '$bytes B';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-'
      '${_twoDigits(local.month)}-'
      '${_twoDigits(local.day)} '
      '${_twoDigits(local.hour)}:'
      '${_twoDigits(local.minute)}';
}

String _twoDigits(int number) => number.toString().padLeft(2, '0');
