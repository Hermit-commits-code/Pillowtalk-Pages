import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'config/router.dart';
import 'firebase_options.dart';
import 'services/theme_provider.dart';

// ThemeProvider is implemented in `lib/services/theme_provider.dart` and
// includes persistent theme loading/saving. Use that across the app so all
// screens (e.g. `ProfileScreen`) can access the same provider type.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated options if not already initialized
  // This guards against "A Firebase App named \"[DEFAULT]\" already exists" when
  // hot-restarting or when firebase_auto_init is enabled on some platforms.
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      // On some platforms (or with certain plugin setups) Firebase may be
      // auto-initialized on the native side which can lead to a duplicate
      // app error when Dart also attempts initialization. If that happens,
      // ignore the duplicate-app error and continue; other errors should
      // still be surfaced.
      if (e.code != 'duplicate-app') rethrow;
    }
  }

  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SpicyReadsApp(),
    );
  }
}

class SpicyReadsApp extends StatelessWidget {
  const SpicyReadsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp.router(
      title: 'Spicy Reads',
      theme: spicyLightTheme,
      darkTheme: spicyDarkTheme,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
