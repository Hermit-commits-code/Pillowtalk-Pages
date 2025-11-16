import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'screens/onboarding/onboarding_flow.dart';
import 'config/app_theme.dart';
import 'config/router.dart';
import 'firebase_options.dart';
import 'services/theme_provider.dart';
import 'services/auth_service.dart';
import 'widgets/update_check_wrapper.dart';

import 'dart:io' show Platform;

class OnboardingWrapper extends StatelessWidget {
  const OnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingFlow();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // If building for Android (or other mobile platforms where the native
  // `google-services.json` / `GoogleService-Info.plist` files are present),
  // prefer the platform-default initialization which reads those files.
  // This avoids requiring the generated `firebase_options.dart` when you
  // only build for Android.
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Fall back to explicit options if the platform-default init fails.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // Debug: print runtime Firebase configuration so we can verify which
  // project and API key the app actually initialized with.
  try {
    final opts = Firebase.app().options;
    // Avoid logging secrets in production; this is a short-lived debug aid.
    // It prints the projectId and masked apiKey.
    final apiKey = opts.apiKey;
    final maskedKey = apiKey.length > 8
        ? '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}'
        : apiKey;
    // ignore: avoid_print
    print(
      'Firebase initialized for project: ${opts.projectId}, apiKey: $maskedKey, appId: ${opts.appId}',
    );
  } catch (_) {}

  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: UpdateCheckWrapper(
        child: FutureBuilder<User?>(
          future: AuthService.instance.authStateChanges().first,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final user = snapshot.data;
            if (user == null) {
              return const SpicyReadsApp();
            }

            // If the user hasn't completed onboarding, show the onboarding flow first.
            return FutureBuilder<DocumentSnapshot?>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get()
                  .then((d) => d),
              builder: (context, snap2) {
                if (snap2.connectionState == ConnectionState.waiting) {
                  return const MaterialApp(
                    home: Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final doc = snap2.data;
                final onboarding =
                    (doc?.data() as Map<String, dynamic>?)?['onboarding']
                        as Map<String, dynamic>?;
                if (onboarding == null || onboarding['completedAt'] == null) {
                  return MaterialApp(
                    home: Builder(builder: (c) => const OnboardingWrapper()),
                  );
                }

                return const SpicyReadsApp();
              },
            );
          },
        ),
      ),
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
