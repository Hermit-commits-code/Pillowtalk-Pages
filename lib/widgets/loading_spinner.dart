// lib/widgets/loading_spinner.dart

import 'package:flutter/material.dart';

/// Simple loading spinner widget used across the app
class LoadingSpinner extends StatelessWidget {
  final double? size;
  final Color? color;

  const LoadingSpinner({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget spinner = CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(
        color ?? theme.colorScheme.primary,
      ),
    );

    if (size != null) {
      spinner = SizedBox(width: size, height: size, child: spinner);
    }

    return spinner;
  }
}
