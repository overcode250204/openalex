import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ai/ai_chat_message.dart';
import '../../utils/app_keys.dart';
import '../../viewmodels/publication_ai_chat_view_model.dart';

class PublicationAiChatPanel extends StatefulWidget {
  const PublicationAiChatPanel({super.key});

  @override
  State<PublicationAiChatPanel> createState() => _PublicationAiChatPanelState();
}

class _PublicationAiChatPanelState extends State<PublicationAiChatPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggestedPrompts = <({String id, String label, String prompt})>[
    (
      id: 'summary',
      label: 'Summarize',
      prompt:
          'Summarize this paper in English using the available abstract and metadata.',
    ),
    (
      id: 'contributions',
      label: 'Contributions',
      prompt: 'What are the likely key contributions of this paper?',
    ),
    (
      id: 'research_gap',
      label: 'Research gap',
      prompt:
          'Based only on the available abstract and metadata, what possible research gaps does this paper suggest?',
    ),
    (
      id: 'limitations',
      label: 'Limitations',
      prompt:
          'What limitations can be cautiously inferred from the available publication details?',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(BuildContext context) async {
    final text = _controller.text;
    _controller.clear();
    await context.read<PublicationAiChatViewModel>().sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _sendPrompt(BuildContext context, String prompt) async {
    await context.read<PublicationAiChatViewModel>().sendSuggestedPrompt(
      prompt,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PublicationAiChatViewModel>();

    return SafeArea(
      key: AppKeys.publicationAiChatPanel,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PanelHeader(
                canClear: viewModel.hasMessages,
                onClear: viewModel.clearMessages,
              ),
              const SizedBox(height: 12),
              _PromptChips(
                enabled: !viewModel.isLoading,
                onSelected: (prompt) => _sendPrompt(context, prompt),
                prompts: _suggestedPrompts,
              ),
              const SizedBox(height: 12),
              if (viewModel.errorMessage != null) ...[
                _InlineError(
                  message: viewModel.errorMessage!,
                  onDismiss: viewModel.clearError,
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: viewModel.hasMessages
                    ? ListView.separated(
                        controller: _scrollController,
                        itemCount:
                            viewModel.messages.length +
                            (viewModel.isLoading ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index >= viewModel.messages.length) {
                            return const _TypingBubble();
                          }

                          return _MessageBubble(
                            message: viewModel.messages[index],
                          );
                        },
                      )
                    : const _EmptyChatState(),
              ),
              const SizedBox(height: 12),
              _Composer(
                controller: _controller,
                isLoading: viewModel.isLoading,
                onSend: () => _send(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.canClear, required this.onClear});

  final bool canClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.auto_awesome, color: Colors.blue.shade700),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ask AI about this paper',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              Text(
                'Uses title, abstract, and metadata only',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          key: AppKeys.publicationAiChatClearButton,
          tooltip: 'Clear chat',
          onPressed: canClear ? onClear : null,
          icon: const Icon(Icons.delete_outline),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _PromptChips extends StatelessWidget {
  const _PromptChips({
    required this.enabled,
    required this.onSelected,
    required this.prompts,
  });

  final bool enabled;
  final ValueChanged<String> onSelected;
  final List<({String id, String label, String prompt})> prompts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final prompt in prompts) ...[
            ActionChip(
              key: AppKeys.publicationAiPromptChip(prompt.id),
              label: Text(prompt.label),
              onPressed: enabled ? () => onSelected(prompt.prompt) : null,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final background = isUser ? Colors.blue.shade600 : Colors.grey.shade100;
    final foreground = isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SelectableText(
              message.content,
              style: TextStyle(color: foreground, height: 1.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Analyzing...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 42, color: Colors.grey[500]),
            const SizedBox(height: 10),
            const Text(
              'Ask for a summary, research gap, limitations, or contribution analysis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: TextStyle(color: Colors.red[800])),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: AppKeys.publicationAiChatInput,
            controller: controller,
            enabled: !isLoading,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => isLoading ? null : onSend(),
            decoration: InputDecoration(
              hintText: 'Ask about this paper...',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          key: AppKeys.publicationAiChatSendButton,
          tooltip: 'Send',
          onPressed: isLoading ? null : onSend,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}
