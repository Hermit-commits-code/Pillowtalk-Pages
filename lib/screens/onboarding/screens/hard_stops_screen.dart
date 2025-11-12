import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/hard_stops_service.dart';

class HardStopsScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const HardStopsScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<HardStopsScreen> createState() => _HardStopsScreenState();
}

class _HardStopsScreenState extends State<HardStopsScreen> {
  final Set<String> _selectedStops = {};

  final List<Map<String, String>> _commonHardStops = [
    {'name': 'Non-Consensual', 'description': 'No non-con or dub-con content'},
    {'name': 'Cheating', 'description': 'No cheating storylines'},
    {'name': 'Sexual Assault', 'description': 'No SA or trauma content'},
    {
      'name': 'Child Endangerment',
      'description': 'No content involving minors',
    },
    {'name': 'Extreme Violence', 'description': 'No graphic violence'},
    {'name': 'Animal Content', 'description': 'No bestiality or zoophilia'},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Your Hard Stops',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select content you never want to see',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: _commonHardStops.length,
                    itemBuilder: (context, index) {
                      final stop = _commonHardStops[index];
                      final isSelected = _selectedStops.contains(stop['name']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) {
                            setState(() {
                              if (isSelected) {
                                _selectedStops.remove(stop['name']);
                              } else {
                                _selectedStops.add(stop['name']!);
                              }
                            });
                          },
                          title: Text(stop['name']!),
                          subtitle: Text(stop['description']!),
                          activeColor: Colors.pink,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Semantics(
                  button: true,
                  enabled: true,
                  onTap: widget.onPrevious,
                  label: 'Go back to previous step',
                  child: OutlinedButton(
                    onPressed: widget.onPrevious,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 56),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    button: true,
                    enabled: true,
                    onTap: () async {
                      final hardStopsService = Provider.of<HardStopsService>(
                        context,
                        listen: false,
                      );
                      await hardStopsService.setHardStops(
                        _selectedStops.toList(),
                      );
                      widget.onNext();
                    },
                    label: 'Continue to next step with hard stops saved',
                    child: ElevatedButton(
                      onPressed: () async {
                        // Save hard stops to Firebase
                        final hardStopsService = Provider.of<HardStopsService>(
                          context,
                          listen: false,
                        );
                        await hardStopsService.setHardStops(
                          _selectedStops.toList(),
                        );
                        widget.onNext();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text('Next'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
