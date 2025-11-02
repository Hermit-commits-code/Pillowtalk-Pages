// lib/screens/book/widgets/editable_tropes_section.dart

import 'package:flutter/material.dart';

/// Editable tropes/warnings section with autocomplete for community suggestions
class EditableTropesSection extends StatefulWidget {
  final List<String> tropes;
  final List<String> availableTropes; // Community suggestions
  final Function(List<String>) onTropesChanged;
  final String label;

  const EditableTropesSection({
    super.key,
    required this.tropes,
    required this.availableTropes,
    required this.onTropesChanged,
    this.label = 'Tropes',
  });

  @override
  State<EditableTropesSection> createState() => _EditableTropesSectionState();
}

class _EditableTropesSectionState extends State<EditableTropesSection> {
  late List<String> _currentTropes;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Lightweight fallback suggestions when the book has no aggregated suggestions yet.
  static const List<String> _fallbackSuggestions = [
    'Violence',
    'Dubcon',
    'Abuse',
    'Self-harm',
    'Substance use',
    'Non-con',
    'Trigger: sexual content',
  ];

  @override
  void initState() {
    super.initState();
    _currentTropes = List.from(widget.tropes);
    // No debug prints in production: available suggestions handled silently.
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTrope(String trope) {
    final trimmed = trope.trim();
    if (trimmed.isEmpty || _currentTropes.contains(trimmed)) {
      return;
    }
    setState(() {
      _currentTropes.add(trimmed);
    });
    widget.onTropesChanged(_currentTropes);
    _textController.clear();
  }

  void _removeTrope(String trope) {
    setState(() {
      _currentTropes.remove(trope);
    });
    widget.onTropesChanged(_currentTropes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${_currentTropes.length})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.6 * 255).round(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Existing tropes as deletable chips
        if (_currentTropes.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _currentTropes.map((trope) {
              return Chip(
                label: Text(trope),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeTrope(trope),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        // Autocomplete input field
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            final search = textEditingValue.text;
            if (search.isEmpty) {
              return const Iterable<String>.empty();
            }
            final searchTerm = search.toLowerCase();
            final source = widget.availableTropes.isNotEmpty
                ? widget.availableTropes
                : _fallbackSuggestions;
            final results = source.where((trope) {
              return trope.toLowerCase().contains(searchTerm) &&
                  !_currentTropes.contains(trope);
            });
            // return matches
            return results;
          },
          onSelected: (String selection) {
            _addTrope(selection);
          },
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController fieldTextController,
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted,
              ) {
                return TextField(
                  controller: fieldTextController,
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Add ${widget.label.toLowerCase()}',
                    hintText: 'Search or type to add...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        _addTrope(fieldTextController.text);
                        fieldTextController.clear();
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    _addTrope(value);
                    fieldTextController.clear();
                    fieldFocusNode.requestFocus();
                  },
                );
              },
          optionsViewBuilder:
              (
                BuildContext context,
                AutocompleteOnSelected<String> onSelected,
                Iterable<String> options,
              ) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                        maxWidth: 300,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(option),
                            leading: const Icon(
                              Icons.bookmark_border,
                              size: 20,
                            ),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }
}
