import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/keyword/openalex_keyword.dart';
import '../../services/suggestion_service.dart';
import '../../utils/app_keys.dart';

class KeywordAutocompleteSearch extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<OpenAlexKeyword> onKeywordSelected;
  final ValueChanged<String>? onAnalyzePressed;
  final String hintText;
  final bool showAnalyzeButton;
  final SuggestionService suggestionService;

  const KeywordAutocompleteSearch({
    super.key,
    required this.controller,
    required this.onKeywordSelected,
    this.onAnalyzePressed,
    this.hintText = 'Enter an academic keyword...',
    this.showAnalyzeButton = true,
    required this.suggestionService,
  });

  @override
  State<KeywordAutocompleteSearch> createState() =>
      _KeywordAutocompleteSearchState();
}

class _KeywordAutocompleteSearchState extends State<KeywordAutocompleteSearch> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  List<OpenAlexKeyword> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        if (_suggestions.isNotEmpty || _isLoading) {
          _showOverlay();
        }
      } else {
        // Delay hiding the overlay to allow onTap to process
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_focusNode.hasFocus) {
            _hideOverlay();
          }
        });
      }
    });
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _debounce?.cancel();
    _hideOverlay();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (!_focusNode.hasFocus) return;

    final query = widget.controller.text.trim();
    if (query.isEmpty) {
      _debounce?.cancel();
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _showSuggestions = false;
      });
      _hideOverlay();
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });
    _showOverlay();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await widget.suggestionService
          .fetchOpenAlexKeywordSuggestions(query);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _suggestions = results;
      });
      if (_showSuggestions && _focusNode.hasFocus) {
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onSuggestionTap(OpenAlexKeyword keyword) {
    _focusNode.unfocus();
    _hideOverlay();
    widget.controller.text = keyword.displayName;
    widget.onKeywordSelected(keyword);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No matching academic keywords found.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return InkWell(
          key: AppKeys.keywordSuggestionItem(suggestion.id),
          onTap: () => _onSuggestionTap(suggestion),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.label_outline,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (suggestion.worksCount > 0)
                        Text(
                          '${_formatNumber(suggestion.worksCount)} works',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: AppKeys.keywordSearchField,
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() {
                          _showSuggestions = false;
                        });
                        _hideOverlay();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty && widget.onAnalyzePressed != null) {
                _hideOverlay();
                widget.onAnalyzePressed!(value);
              }
            },
          ),
          if (widget.showAnalyzeButton) const SizedBox(height: 12),
          if (widget.showAnalyzeButton)
            FilledButton.icon(
              key: AppKeys.keywordAnalyzeButton,
              onPressed: () {
                final query = widget.controller.text.trim();
                if (query.isNotEmpty && widget.onAnalyzePressed != null) {
                  _hideOverlay();
                  widget.onAnalyzePressed!(query);
                }
              },
              icon: const Icon(Icons.analytics),
              label: const Text('Analyze Keyword'),
            ),
        ],
      ),
    );
  }
}
