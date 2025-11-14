import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/hard_stops_service.dart';
import '../../../services/kink_filter_service.dart';

class SummaryScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const SummaryScreen({
    Key? key,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  List<String> hardStops = [];
  List<String> kinkFilters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final hardStopsService = Provider.of<HardStopsService>(
        context,
        listen: false,
      );
      final kinkFilterService = Provider.of<KinkFilterService>(
        context,
        listen: false,
      );

      final stopsData = await hardStopsService.getHardStopsOnce();
      final kinksData = await kinkFilterService.getKinkFilterOnce();

      if (mounted) {
        setState(() {
          hardStops = stopsData['hardStops'] ?? [];
          kinkFilters = kinksData['kinkFilter'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

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
                  'Your Preferences',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Review what you've selected",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                // Hard Stops Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha((0.05 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Semantics(
                            image: true,
                            label: 'Hard stops configured',
                            child: Icon(
                              Icons.shield,
                              size: 32,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hard Stops',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Content you never want to see',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (hardStops.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: hardStops.map((stop) {
                            return Chip(
                              label: Text(stop),
                              backgroundColor: Colors.blue.withAlpha((0.15 * 255).round()),
                              side: BorderSide(
                                color: Colors.blue.withAlpha((0.3 * 255).round()),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'None selected',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Kink Filters Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Semantics(
                            image: true,
                            label: 'Kink filters configured',
                            child: Icon(
                              Icons.filter_alt,
                              size: 32,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Favorite Tropes',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Tropes you love',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (kinkFilters.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: kinkFilters.map((kink) {
                            return Chip(
                              label: Text(kink),
                              backgroundColor: Colors.purple.withOpacity(0.15),
                              side: BorderSide(
                                color: Colors.purple.withOpacity(0.3),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'None selected',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'You can always adjust these in Settings.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
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
                    onTap: widget.onNext,
                    label: 'Continue to final step',
                    child: ElevatedButton(
                      onPressed: widget.onNext,
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
  