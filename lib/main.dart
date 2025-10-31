import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'config/router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PillowtalkPagesApp());
}

class PillowtalkPagesApp extends StatelessWidget {
  const PillowtalkPagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pillowtalk Pages',
      theme: pillowtalkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
