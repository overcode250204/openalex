import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_keys.dart';
import '../../viewmodels/selected_topic_view_model.dart';

/// Profile shell kept intentionally lightweight until authentication is added.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTopic = context.watch<SelectedTopicViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Research profile'),
              subtitle: const Text(
                'Authentication is not configured for this lab project.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.topic_outlined),
              title: const Text('Selected topic'),
              subtitle: Text(
                selectedTopic.selectedTopic ?? 'No topic selected',
              ),
              trailing: selectedTopic.hasSelectedTopic
                  ? IconButton(
                      tooltip: 'Clear selected topic',
                      onPressed: selectedTopic.clearTopic,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            key: AppKeys.logoutButton,
            onPressed: null,
            icon: const Icon(Icons.logout),
            label: const Text('Logout requires authentication'),
          ),
        ],
      ),
    );
  }
}
