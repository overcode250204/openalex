import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_keys.dart';
import '../../viewmodels/admin/admin_notifications_view_model.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminNotificationsViewModel>();

    return SafeArea(
      key: AppKeys.adminNotificationsScreen,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Send Notification', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Broadcasts a push notification to every signed-in device via Firebase Cloud Messaging.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              TextField(
                key: AppKeys.adminNotificationTitleField,
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: AppKeys.adminNotificationBodyField,
                controller: _bodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              if (viewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    viewModel.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (viewModel.sendSucceeded)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Notification sent.',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              FilledButton.icon(
                key: AppKeys.adminNotificationSendButton,
                onPressed: viewModel.isSending ? null : _send,
                icon: viewModel.isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: const Text('Send to all users'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _send() {
    context.read<AdminNotificationsViewModel>().send(
      title: _titleController.text,
      body: _bodyController.text,
    );
  }
}
