import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/kink_filter_service.dart';

class KinkFiltersScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const KinkFiltersScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<KinkFiltersScreen> createState() => _KinkFiltersScreenState();
}

class _KinkFiltersScreenState extends State<KinkFiltersScreen> {
  final Set<String> _selectedKinks = {};

  final List<Map<String, String>> _commonKinks = [
    {
      'name': 'BDSM',
      'description': 'Bondage, discipline, dominance, submission',
    },
    {
      'name': 'Dubious Consent',
      'description': 'Morally gray consent situations',
    },
    {
      'name': 'Age Gap',
      'description': 'Significant age differences between characters',
    },
    {'name': 'Paranormal', 'description': 'Supernatural or paranormal themes'},
    {'name': 'Reverse Harem', 'description': 'One woman with multiple men'},
    {
      'name': 'Menage',
      'description': 'Multiple character romantic/sexual relationships',
    },
    {'name': 'Fated Mates', 'description': 'Paranormal soulmate connections'},
    {
      'name': 'Enemies to Lovers',
      'description': 'Adversaries who become romantic',
    },
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
                  'Set Your Kink Filters',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select tropes you want to include in results',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: _commonKinks.length,
                    itemBuilder: (context, index) {
                      final kink = _commonKinks[index];
                      final isSelected = _selectedKinks.contains(kink['name']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) {
                            setState(() {
                              if (isSelected) {
                                _selectedKinks.remove(kink['name']);
                              } else {
                                _selectedKinks.add(kink['name']!);
                              }
                            });
                          },
                          title: Text(kink['name']!),
                          subtitle: Text(kink['description']!),
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
                OutlinedButton(
                  onPressed: widget.onPrevious,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(100, 56),
                  ),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Save kink filters to Firebase
                      final kinkFilterService = Provider.of<KinkFilterService>(
                        context,
                        listen: false,
                      );
                      await kinkFilterService.setKinkFilter(
                        _selectedKinks.toList(),
                      );
                      widget.onNext();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('Next'),
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
