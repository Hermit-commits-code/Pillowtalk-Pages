import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final bool isVerified = prefs.getBool('age_verified') ?? false;

    if (!isVerified) {
      await _showAgeVerificationDialog();
    } else {
      if (!mounted) return;
      context.go('/login');
    }
  }

  Future<void> _showAgeVerificationDialog() async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardDark,
          title: const Text(
            '\ud83d\udd1e Mandatory Age Verification',
            style: TextStyle(color: primaryRose, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "This app tracks and discusses mature, adult themes, including graphic sexual content (The Spice Meter). You must be 18 years of age or older to use Pillowtalk Pages.\\n\\nBy continuing, you affirm that you are 18 or older.",
            style: TextStyle(color: textSoftWhite),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'I am UNDER 18',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryRose),
              child: const Text(
                'I am 18 or older',
                style: TextStyle(color: textSoftWhite),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('age_verified', true);
                if (!mounted) return;
                Navigator.of(context).pop();
                if (!mounted) return;
                // After dialog closes, navigate to login
                context.go('/login');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundMidnight, Color(0xFF1A0000)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                'Pillowtalk Pages',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The Ultimate Sanctuary for Romance Readers',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
