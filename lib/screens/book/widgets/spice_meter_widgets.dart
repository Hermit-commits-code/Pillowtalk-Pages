// lib/screens/book/widgets/spice_meter_widgets.dart

import 'package:flutter/material.dart';

/// Simplified S.P.I.C.E. Meter: 0-5 flames rating for overall spice/heat level
class SpiceMeter extends StatelessWidget {
  final double spiceLevel;
  final bool editable;
  final ValueChanged<double>? onChanged;

  const SpiceMeter({
    super.key,
    required this.spiceLevel,
    this.editable = false,
    this.onChanged,
  });

  String _getSpiceLabel(double level) {
    if (level <= 0.5) return 'Fade to Black';
    if (level <= 1.5) return 'Sweet & Chaste';
    if (level <= 2.5) return 'Warm & Steamy';
    if (level <= 3.5) return 'Hot & Sensual';
    if (level <= 4.5) return 'Scorching';
    return 'Inferno';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roundedLevel = spiceLevel.round();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Spice Level',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Icon(
                    Icons.local_fire_department,
                    size: 32,
                    color: index < roundedLevel
                        ? Colors.pinkAccent
                        : Colors.grey[300],
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${spiceLevel.toStringAsFixed(1)} / 5.0 - ${_getSpiceLabel(spiceLevel)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (editable && onChanged != null) ...[
              Slider(
                value: spiceLevel.clamp(0.0, 5.0),
                min: 0.0,
                max: 5.0,
                divisions: 10,
                label: spiceLevel.toStringAsFixed(1),
                onChanged: onChanged,
              ),
              Center(
                child: Text(
                  'Adjust spice level',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(
                      (0.7 * 255).round(),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Community average from readers',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.7 * 255).round(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
