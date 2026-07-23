import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_keys.dart';
import '../../viewmodels/admin/admin_remote_config_view_model.dart';

class AdminRemoteConfigScreen extends StatefulWidget {
  const AdminRemoteConfigScreen({super.key});

  @override
  State<AdminRemoteConfigScreen> createState() => _AdminRemoteConfigScreenState();
}

class _AdminRemoteConfigScreenState extends State<AdminRemoteConfigScreen> {
  final _journalsController = TextEditingController();
  final _keywordsController = TextEditingController();
  bool _hasSeededFields = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminRemoteConfigViewModel>().load();
    });
  }

  @override
  void dispose() {
    _journalsController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  void _seedFieldsIfNeeded(AdminRemoteConfigViewModel viewModel) {
    if (_hasSeededFields || viewModel.isLoading) return;
    _journalsController.text = viewModel.maxJournalsDisplayed?.toString() ?? '';
    _keywordsController.text = viewModel.maxKeywordsDisplayed?.toString() ?? '';
    _hasSeededFields = true;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminRemoteConfigViewModel>();
    _seedFieldsIfNeeded(viewModel);

    return SafeArea(
      key: AppKeys.adminRemoteConfigScreen,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remote Config', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Controls values consumed by the client app via Firebase Remote Config.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              if (viewModel.isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                TextField(
                  key: AppKeys.adminMaxJournalsField,
                  controller: _journalsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'max_journals_displayed',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: AppKeys.adminMaxKeywordsField,
                  controller: _keywordsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'max_keywords_displayed',
                    border: OutlineInputBorder(),
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
                if (viewModel.saveSucceeded)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Saved successfully.',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                FilledButton.icon(
                  key: AppKeys.adminRemoteConfigSaveButton,
                  onPressed: viewModel.isSaving ? null : () => _save(context),
                  icon: viewModel.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    final maxJournals = int.tryParse(_journalsController.text.trim());
    final maxKeywords = int.tryParse(_keywordsController.text.trim());
    context.read<AdminRemoteConfigViewModel>().save(
      maxJournalsDisplayed: maxJournals,
      maxKeywordsDisplayed: maxKeywords,
    );
  }
}
