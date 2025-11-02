import 'package:flutter/material.dart';

class TropesChips extends StatelessWidget {
  final List<String> tropes;
  final void Function(String)? onDeleted;
  const TropesChips({super.key, required this.tropes, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: tropes
          .map(
            (t) => Chip(
              label: Text(t),
              onDeleted: onDeleted != null ? () => onDeleted!(t) : null,
            ),
          )
          .toList(),
    );
  }
}
