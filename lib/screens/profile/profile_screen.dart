import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_keys.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/selected_topic_view_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;
    final selectedTopic = context.watch<SelectedTopicViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: user?.photoUrl == null
                    ? null
                    : NetworkImage(user!.photoUrl!),
                child: user?.photoUrl == null
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              title: Text(user?.displayName ?? 'Research profile'),
              subtitle: Text(user?.email ?? 'Signed in with Google'),
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
            onPressed: auth.isLoading ? null : auth.signOut,
            icon: const Icon(Icons.logout),
            label: Text(auth.isLoading ? 'Signing out...' : 'Sign out'),
          ),
        ],
      ),
    );
  }
}
