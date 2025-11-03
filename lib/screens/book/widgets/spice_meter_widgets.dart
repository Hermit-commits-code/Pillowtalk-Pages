// lib/screens/book/widgets/spice_meter_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simplified S.P.I.C.E. Meter: 0-5 flames rating for overall spice/heat level
/// Features: Tappable flames, realistic flame colors, animations, haptic feedback
class SpiceMeter extends StatefulWidget {
  final double spiceLevel;
  final bool editable;
  final ValueChanged<double>? onChanged;

  const SpiceMeter({
    super.key,
    required this.spiceLevel,
    this.editable = false,
    this.onChanged,
  });

  @override
  State<SpiceMeter> createState() => _SpiceMeterState();
}

class _SpiceMeterState extends State<SpiceMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  String _getSpiceLabel(double level) {
    if (level <= 0.5) return 'Fade to Black';
    if (level <= 1.5) return 'Sweet & Chaste';
    if (level <= 2.5) return 'Warm & Steamy';
    if (level <= 3.5) return 'Hot & Sensual';
    if (level <= 4.5) return 'Scorching';
    return 'Inferno';
  }

  Color _getFlameColor(double rating) {
    // Realistic flame colors based on temperature:
    // 0 = grey (no flame)
    // 1 = red (low heat)
    // 2 = orange (medium heat)
    // 3 = yellow (hot)
    // 4 = white (very hot)
    // 5 = blue (hottest flame)

    if (rating < 0.5) return Colors.grey[400]!;
    if (rating < 1.5) return const Color(0xFFD32F2F); // Red (#D32F2F)
    if (rating < 2.5) return const Color(0xFFF57C00); // Orange (#F57C00)
    if (rating < 3.5) return const Color(0xFFFBC02D); // Yellow (#FBC02D)
    if (rating < 4.5) {
      return const Color(0xFFFFF59D); // Light yellow/white (#FFF59D)
    }
    return const Color(0xFF1976D2); // Blue (#1976D2) - hottest flame
  }

  void _onFlamePressed(int flameIndex) {
    if (!widget.editable || widget.onChanged == null) return;

    // Set rating to (flameIndex + 1).toDouble()
    final newRating = (flameIndex + 1).toDouble();
    widget.onChanged!(newRating);

    // Haptic feedback
    HapticFeedback.selectionClick();

    // Trigger animation
    _triggerAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roundedLevel = widget.spiceLevel.round();

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
                  color: _getFlameColor(widget.spiceLevel),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Spice Level',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getFlameColor(widget.spiceLevel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tappable flames with animations
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final isFilled = index < roundedLevel;
                final isAnimating = widget.editable && isFilled;

                return ScaleTransition(
                  scale: isAnimating
                      ? _scaleAnimation
                      : AlwaysStoppedAnimation(1.0),
                  child: GestureDetector(
                    onTap: () => _onFlamePressed(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          Icons.local_fire_department,
                          key: ValueKey('flame_${index}_${widget.spiceLevel}'),
                          size: 48,
                          color: _getFlameColor(index + 1.0),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Rating display text
            Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style:
                    theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getFlameColor(widget.spiceLevel),
                    ) ??
                    const TextStyle(),
                child: Text(
                  '${widget.spiceLevel.toStringAsFixed(1)} / 5.0 - ${_getSpiceLabel(widget.spiceLevel)}',
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Helper text
            Center(
              child: Text(
                widget.editable
                    ? 'Tap flames to rate'
                    : 'Community average from readers',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.7 * 255).round(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
