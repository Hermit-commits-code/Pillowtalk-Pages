import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    if (!mounted) return;

    if (!isVerified) {
      final accepted = await _showAgeVerificationDialog();
      if (!mounted) return;
      if (accepted == true) {
        context.go('/login');
        return;
      }
      return;
    } else {
      if (!mounted) return;
      context.go('/login');
    }
  }

  Future<bool?> _showAgeVerificationDialog() async {
    if (!mounted) return null;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          backgroundColor: theme.cardTheme.color,
          title: Text(
            '🔞 Mandatory Age Verification',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "This app tracks and discusses mature, adult themes, including graphic sexual content (The Spice Meter). You must be 18 years of age or older to use Spicy Reads.\n\nBy continuing, you affirm that you are 18 or older.",
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor:
                    theme.colorScheme.primary, // High-contrast purple
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('I am UNDER 18'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor:
                    theme.colorScheme.onPrimary, // Cream text on purple
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('I am 18 or older'),
              onPressed: () {
                // Close the dialog immediately and persist verification in background.
                Navigator.of(dialogContext).pop(true);
                SharedPreferences.getInstance().then(
                  (prefs) => prefs.setBool('age_verified', true),
                );
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.scaffoldBackgroundColor, Color(0xFF1A0000)],
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
                'Spicy Reads',
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
