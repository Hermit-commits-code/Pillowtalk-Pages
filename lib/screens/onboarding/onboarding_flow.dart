// lib/screens/onboarding/onboarding_flow.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'curated_library.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _hardStops = <String>[];
  final _kinkFilters = <String>[];
  final _favorites = <String>[];

  int _step = 0;
  bool _saving = false;

  static const hardStopOptions = [
    'Dubious consent',
    'Infidelity',
    'Graphic violence',
    'Abuse',
    'Underage',
  ];

  static const kinkOptions = [
    'BDSM',
    'Ménage',
    'A/B/O',
    'Public sex',
    'Age gap',
  ];

  static const favoriteTropes = [
    'Enemies to Lovers',
    'Forced Proximity',
    'Fake Dating',
    'Grumpy x Sunshine',
  ];

  void _toggle(List<String> list, String value) {
    setState(() {
      if (list.contains(value))
        list.remove(value);
      else
        list.add(value);
    });
  }

  Future<void> _saveAndFinish() async {
    setState(() => _saving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }

    final data = {
      'hardStops': _hardStops,
      'kinkFilters': _kinkFilters,
      'favoriteTropes': _favorites,
      'completedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'onboarding': data,
      }, SetOptions(merge: true));
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Onboarding saved')));

      // Force replace the entire navigator stack so the CuratedLibrary becomes
      // the visible screen in all contexts (works whether onboarding was
      // launched modally or set as the app home).
      try {
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (c) => CuratedLibrary(
            hardStops: _hardStops,
            kinkFilters: _kinkFilters,
            favorites: _favorites,
          )),
          (route) => false,
        );
      } catch (navErr) {
        // As a last resort, leave the confirmation snackbar visible. Navigation
        // failures are non-fatal for onboarding completion.
        debugPrint('Onboarding navigation failed: $navErr');
      }
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (_step + 1) / 4),
            const SizedBox(height: 16),
            Expanded(child: _buildStep()),
            Row(
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                if (_step < 3)
                  ElevatedButton(
                    onPressed: () => setState(() => _step++),
                    child: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: _saving ? null : _saveAndFinish,
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text('Finish'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildIntro();
      case 1:
        return _buildSelector('Hard Stops', hardStopOptions, _hardStops);
      case 2:
        return _buildSelector('Kink Filters', kinkOptions, _kinkFilters);
      case 3:
        return _buildSelector('Favorite Tropes', favoriteTropes, _favorites);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Protect Yourself First',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          'Set hard stops and kink filters to ensure the app filters content you prefer not to see. You can change these later in settings.',
        ),
      ],
    );
  }

  Widget _buildSelector(
    String title,
    List<String> options,
    List<String> selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final chosen = selected.contains(o);
            return ChoiceChip(
              label: Text(o),
              selected: chosen,
              onSelected: (_) => _toggle(selected, o),
            );
          }).toList(),
        ),
      ],
    );
  }
}
