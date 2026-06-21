import 'package:flutter/material.dart';

/// Chat message model for the demo chat state.
class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

/// Bottom sheet panel that acts as a simple AI research assistant chat UI.
/// No real API is called — this is a UI-only demo.
class ResearchAssistantPanel extends StatefulWidget {
  const ResearchAssistantPanel({super.key});

  @override
  State<ResearchAssistantPanel> createState() => _ResearchAssistantPanelState();
}

class _ResearchAssistantPanelState extends State<ResearchAssistantPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          "Hi! I can help you analyze keywords, find papers, explain trends, and suggest research directions.",
      isUser: false,
    ),
  ];

  static const _quickSuggestions = [
    "Analyze this keyword",
    "Find related papers",
    "Suggest research gaps",
  ];

  // Demo responses for each suggestion
  static const _demoReplies = {
    "Analyze this keyword":
        "Based on current OpenAlex data, this keyword shows strong upward momentum with significant growth in recent publications. The peak activity appears to be concentrated in the last 3 years, driven by increasing interdisciplinary adoption.",
    "Find related papers":
        "I found several highly-cited papers related to this keyword. Key authors include researchers from MIT, Stanford, and ETH Zürich. Would you like me to filter by publication year or citation count?",
    "Suggest research gaps":
        "Based on the trend analysis, potential research gaps include: (1) longitudinal studies across developing regions, (2) interdisciplinary applications with biology and physics, and (3) real-world deployment benchmarks with standardized metrics.",
  };

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true));
    });
    _inputController.clear();
    _focusNode.unfocus();

    // Simulate AI reply
    final reply =
        _demoReplies[trimmed] ??
        "That's a great research question! Let me analyze the OpenAlex data for you. Based on recent publication trends, this area shows significant activity. Would you like a detailed breakdown by year or by institution?";

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    });

    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    // Panel takes up ~70% on mobile, 55% on wide screens
    final panelHeight =
        screenHeight * (mediaQuery.size.width >= 600 ? 0.55 : 0.72);

    return Container(
      height: panelHeight + bottomInset,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Drag handle ─────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header ──────────────────────────────────────────────────────
          _PanelHeader(onClose: () => Navigator.pop(context)),

          const Divider(height: 1),

          // ── Messages list ────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // ── Quick suggestion chips ───────────────────────────────────────
          if (_messages.length <= 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickSuggestions.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _SuggestionChip(
                        label: s,
                        onTap: () => _sendMessage(s),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          const Divider(height: 1),

          // ── Input bar ───────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: 10 + bottomInset,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: 'Ask about keywords, trends, papers…',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(onTap: () => _sendMessage(_inputController.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _PanelHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _PanelHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEAF3FF),
              border: Border.all(color: const Color(0xFF2F6FB0), width: 2),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 20,
              color: Color(0xFF2F6FB0),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OpenAlex Research Assistant',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFF22C55E)),
                    SizedBox(width: 4),
                    Text(
                      'Online · Powered by OpenAlex data',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onClose,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEAF3FF),
                border: Border.all(color: const Color(0xFF2F6FB0), width: 1.5),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 15,
                color: Color(0xFF2F6FB0),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF2F6FB0)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 13,
                  color: isUser ? Colors.white : const Color(0xFF1F2937),
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2F6FB0).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF2F6FB0),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2F6FB0),
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}
