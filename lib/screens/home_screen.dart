import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'Reader';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pillowtalk Pages'),
        backgroundColor: backgroundMidnight,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, size: 72, color: primaryRose),
            const SizedBox(height: 24),
            Text(
              'Welcome back, $displayName!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textSoftWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This is your home dashboard. More features coming soon!',
              style: TextStyle(fontSize: 16, color: secondaryGold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      backgroundColor: backgroundMidnight,
    );
  }
}
