import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import 'features/onboarding/splash_screen.dart';

void main() => runApp(const ProviderScope(child: EvcRiderApp()));

/// EVC Rider — passenger app. A thin shell over the shared evc_* packages,
/// running a full mock journey (onboarding → book → track → pay → rate).
class EvcRiderApp extends StatelessWidget {
  const EvcRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EvcApp.rider.displayName,
      theme: evcTheme(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}