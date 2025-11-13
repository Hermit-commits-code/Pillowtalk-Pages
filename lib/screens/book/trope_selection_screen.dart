// lib/screens/book/trope_selection_screen.dart
import 'package:flutter/material.dart';
import '../../services/feature_gating_service.dart';

import '../../constants/tropes_categorized.dart';

/// Trope selection screen modeled after GenreSelectionScreen but with categories.
class TropeSelectionScreen extends StatefulWidget {
  final List<String> initialTropes;

  /// Optional override for checking pro status. If provided, this will be
  /// used instead of querying FirebaseAuth/Firestore which simplifies testing.
  final Future<bool> Function()? proCheck;

  const TropeSelectionScreen({
    super.key,
    required this.initialTropes,
    this.proCheck,
  });

  @override
  State<TropeSelectionScreen> createState() => _TropeSelectionScreenState();
}

class _TropeSelectionScreenState extends State<TropeSelectionScreen> {
  late Set<String> _selectedTropes;
  final List<String> _customTropes = [];
  bool _isPro = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedTropes = Set.from(widget.initialTropes);
    // Separate custom tropes from predefined ones
    for (var trope in _selectedTropes) {
      if (!romanceTropesCategorized.contains(trope)) {
        _customTropes.add(trope);
      }
    }
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    // If a proCheck override is provided (useful for tests), use it.
    if (widget.proCheck != null) {
      try {
        final val = await widget.proCheck!();
        if (mounted) {
          setState(() {
            _isPro = val;
            _isLoading = false;
          });
        }
        return;
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
    } else {
      // Use feature gating service for Pro status check
      try {
        final featureGatingService = FeatureGatingService();
        final isPro = await featureGatingService.isPro();
        if (mounted) {
          setState(() {
            _isPro = isPro;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _toggleTrope(String trope) {
    setState(() {
      if (_selectedTropes.contains(trope)) {
        _selectedTropes.remove(trope);
      } else {
        // Check pro tier limit
        if (!_isPro &&
            _selectedTropes.length >= FeatureGatingService.freeTropeLimit) {
          FeatureGatingService().showTropeLimitUpgradePrompt(context);
          return;
        }
        _selectedTropes.add(trope);
      }
    });
  }

  Future<void> _showAddCustomTropeDialog() async {
    final TextEditingController controller = TextEditingController();
    final newTrope = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Trope'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Fish Out of Water',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newTrope != null) {
      setState(() {
        if (!_customTropes.contains(newTrope)) {
          _customTropes.add(newTrope);
        }
        // Check pro tier limit before adding
        if (!_isPro &&
            _selectedTropes.length >= FeatureGatingService.freeTropeLimit) {
          FeatureGatingService().showTropeLimitUpgradePrompt(context);
        } else {
          _selectedTropes.add(newTrope);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Tropes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final categories = tropeCategories.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Tropes ${_isPro ? '' : '(${FeatureGatingService.freeTropeLimit} max)'}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {
              Navigator.of(context).pop(_selectedTropes.toList());
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == categories.length) {
            // Add custom
            return ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add a custom trope...'),
              onTap: _showAddCustomTropeDialog,
            );
          }

          final cat = categories[index];
          final items = tropeCategories[cat] ?? [];
          return ExpansionTile(
            title: Text(cat),
            initiallyExpanded: items.any((i) => _selectedTropes.contains(i)),
            children: [
              CheckboxListTile(
                title: Text('All $cat'),
                value:
                    items.every((i) => _selectedTropes.contains(i)) &&
                    items.isNotEmpty,
                onChanged: (sel) {
                  setState(() {
                    if (sel == true) {
                      _selectedTropes.addAll(items);
                    } else {
                      for (final i in items) _selectedTropes.remove(i);
                    }
                  });
                },
              ),
              ...items.map(
                (t) => CheckboxListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(t),
                  ),
                  value: _selectedTropes.contains(t),
                  onChanged: (_) => _toggleTrope(t),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
