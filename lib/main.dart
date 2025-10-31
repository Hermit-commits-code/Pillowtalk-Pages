import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const PillowtalkPagesApp());
}

class PillowtalkPagesApp extends StatelessWidget {
  const PillowtalkPagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pillowtalk Pages',
      theme: pillowtalkTheme,
      debugShowCheckedModeBanner: false,
      home: const TemporaryHomeScreen(),
    );
  }
}

class TemporaryHomeScreen extends StatelessWidget {
  const TemporaryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundMidnight,
              Color(0xFF1A0000), // Darker rose gradient
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories,
                size: 80,
                color: primaryRose,
              ),
              SizedBox(height: 24),
              Text(
                'Pillowtalk Pages',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textSoftWhite,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The Ultimate Sanctuary for Romance Readers',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryGold,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              Text(
                'Firebase initialized successfully! 🔥',
                style: TextStyle(
                  fontSize: 14,
                  color: primaryRose,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Theme applied successfully! ✨',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
