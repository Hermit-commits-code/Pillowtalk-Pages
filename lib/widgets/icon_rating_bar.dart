import 'package:flutter/material.dart';

class IconRatingBar extends StatelessWidget {
  final String title;
  final double rating;
  final int iconCount;
  final IconData filledIcon;
  final IconData emptyIcon;
  final ValueChanged<double> onRatingUpdate;
  final Color color;

  const IconRatingBar({
    super.key,
    required this.title,
    required this.rating,
    required this.onRatingUpdate,
    this.iconCount = 5,
    required this.filledIcon,
    required this.emptyIcon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      // center the title and icons so "Overall Spice" and "Emotional Arc" render centered
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // wrap title in Center to guarantee it's centered relative to the icons below
        Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        // ensure the row of icons is centered
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(iconCount, (index) {
              return IconButton(
                iconSize: 36,
                icon: Icon(
                  index < rating ? filledIcon : emptyIcon,
                  color: color,
                ),
                onPressed: () {
                  onRatingUpdate(index + 1.0);
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}
