import 'package:flutter/material.dart';
import 'package:openalex/models/search_filter.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:provider/provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late SearchFilter _tempFilter;
  final _yearFromCrl = TextEditingController();
  final _yearToCrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempFilter = context.read<PublicationProvider>().filter;
    if (_tempFilter.yearFrom != null) {
      _yearFromCrl.text = _tempFilter.yearFrom.toString();
    }
    if (_tempFilter.yearTo != null) {
      _yearToCrl.text = _tempFilter.yearTo.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempFilter = const SearchFilter();
                    _yearFromCrl.clear();
                    _yearToCrl.clear();
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const Divider(),

          const Text('Year', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _yearFromCrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'From year',
                    hint: Text("1990"),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (v) => setState(() {
                    _tempFilter = _tempFilter.copyWith(
                      yearFrom: int.tryParse(v),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _yearToCrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'To year',
                    hint: Text("2026"),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (v) => setState(() {
                    _tempFilter = _tempFilter.copyWith(yearTo: int.tryParse(v));
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text('Sort', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _sortChip('Relevance', SortOption.relevance),
              _sortChip('Cited (Desc)', SortOption.citedDesc),
              _sortChip('Cited (Asc)', SortOption.citedAsc),
              _sortChip('Year (Desc)', SortOption.yearDesc),
              _sortChip('Year (Asc)', SortOption.yearAsc),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _typeChip('All', DocumentType.all),
              _typeChip('Article', DocumentType.article),
              _typeChip('Preprint', DocumentType.preprint),
              _typeChip('Book', DocumentType.book),
            ],
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Open Access'),
            value: _tempFilter.isOpenAccess ?? false,
            onChanged: (v) => setState(() {
              _tempFilter = v
                  ? _tempFilter.copyWith(isOpenAccess: true)
                  : _tempFilter.copyWith(clearOpenAccess: true);
            }),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                context.read<PublicationProvider>().updateFilter(_tempFilter);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Apply', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, SortOption option) {
    final selected = _tempFilter.sortOption == option;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _tempFilter = _tempFilter.copyWith(sortOption: option);
      }),
    );
  }

  Widget _typeChip(String label, DocumentType type) {
    final selected = _tempFilter.documentType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _tempFilter = _tempFilter.copyWith(documentType: type);
      }),
    );
  }
}
