import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/tropes.dart';

class TropeSelectionScreen extends StatefulWidget {
  final List<String> initialTropes;
  const TropeSelectionScreen({super.key, required this.initialTropes});

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
      if (!romanceTropes.contains(trope)) {
        _customTropes.add(trope);
      }
    }
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted) {
          setState(() {
            _isPro = userDoc.data()?['isPro'] ?? false;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleTrope(String trope) {
    setState(() {
      if (_selectedTropes.contains(trope)) {
        _selectedTropes.remove(trope);
      } else {
        // Check pro tier limit
        if (!_isPro && _selectedTropes.length >= 2) {
          _showProUpgradeMessage();
          return;
        }
        _selectedTropes.add(trope);
      }
    });
  }

  void _showProUpgradeMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Free users can select up to 2 tropes. Upgrade to Pro for unlimited selections!',
        ),
        action: SnackBarAction(
          label: 'Upgrade',
          onPressed: () {
            Navigator.of(context).pushNamed('/pro-club');
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
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
        if (!_isPro && _selectedTropes.length >= 2) {
          _showProUpgradeMessage();
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

    // Combine predefined and custom tropes for display
    final allDisplayTropes = <String>[...romanceTropes, ..._customTropes];

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Tropes ${_isPro ? '' : '(2 max)'}'),
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
        itemCount: allDisplayTropes.length + 1,
        itemBuilder: (context, index) {
          if (index == allDisplayTropes.length) {
            // This is the "Add Custom" button
            return ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add a custom trope...'),
              onTap: _showAddCustomTropeDialog,
            );
          }

          final trope = allDisplayTropes[index];

          return CheckboxListTile(
            title: Text(trope),
            value: _selectedTropes.contains(trope),
            onChanged: (bool? selected) {
              _toggleTrope(trope);
            },
          );
        },
      ),
    );
  }
}
