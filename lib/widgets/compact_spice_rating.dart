// lib/widgets/compact_spice_rating.dart

import 'package:flutter/material.dart';

/// Compact spice rating widget showing flames + numeric rating + count
/// Uses realistic flame colors: grey → red → orange → yellow → white → blue
class CompactSpiceRating extends StatelessWidget {
  final double rating;
  final int? ratingCount;
  final double size;
  final TextStyle? textStyle;

  const CompactSpiceRating({
    super.key,
    required this.rating,
    this.ratingCount,
    this.size = 14,
    this.textStyle,
  });

  Color _getFlameColor(double rating) {
    // Map 0-5 scale to realistic flame colors:
    // 0 = grey (no flame)
    // 1 = red (low heat)
    // 2 = orange (medium heat)
    // 3 = yellow (hot)
    // 4 = white (very hot)
    // 5 = blue (hottest)

    if (rating < 0.5) {
      return Colors.grey[400]!;
    }
    if (rating < 1.5) return const Color(0xFFD32F2F); // Red (#D32F2F)
    if (rating < 2.5) return const Color(0xFFF57C00); // Orange (#F57C00)
    if (rating < 3.5) return const Color(0xFFFBC02D); // Yellow (#FBC02D)
    if (rating < 4.5) {
      return const Color(0xFFFFF59D); // Light yellow/white (#FFF59D)
    }
    return const Color(0xFF1976D2); // Blue (#1976D2) - hottest flame
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayStyle =
        textStyle ??
        theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: size * 1.0,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department,
          size: size,
          color: _getFlameColor(rating),
        ),
        SizedBox(width: size * 0.3),
        Text(rating.toStringAsFixed(1), style: displayStyle),
        if (ratingCount != null && ratingCount! > 0) ...[
          SizedBox(width: size * 0.3),
          Text(
            '($ratingCount)',
            style: displayStyle?.copyWith(
              fontSize: size * 0.8,
              color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()),
            ),
          ),
        ],
      ],
    );
  }
}
