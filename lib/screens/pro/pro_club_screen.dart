// lib/screens/pro/pro_club_screen.dart
import 'package:flutter/material.dart';

class ProClubScreen extends StatelessWidget {
  const ProClubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "The Connoisseur's Club",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: Center(
        child: Card(
          color: Theme.of(context).cardTheme.color,
          shape: Theme.of(context).cardTheme.shape,
          elevation: Theme.of(context).cardTheme.elevation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Pro subscription implementation coming soon',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
