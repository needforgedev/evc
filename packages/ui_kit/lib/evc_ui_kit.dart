/// EVC design system — shared theme and widgets used by all three apps.
///
/// Edit anything here once and Rider, Driver and Admin all pick it up on their
/// next build. This is the "single source of truth" for the look & feel.
library;

import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';

/// EVC brand palette. Green carries the all-electric, zero-emission promise.
abstract final class EvcColors {
  static const Color primary = Color(0xFF00C853); // EV green
  static const Color ink = Color(0xFF0B1F17);
}

/// The shared Material 3 theme for every EVC app.
ThemeData evcTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: EvcColors.primary,
        brightness: Brightness.light,
      ),
    );

/// Temporary branded landing screen proving an app shell is wired to the shared
/// UI kit and core. Each app passes its [EvcApp] identity; replace with the
/// real app UI as the phases in PLAN.md are built out.
class EvcLandingScreen extends StatelessWidget {
  const EvcLandingScreen({super.key, required this.app});

  final EvcApp app;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.electric_car, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              app.displayName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(app.tagline, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            Chip(label: const Text('Shared core + UI kit ✓')),
          ],
        ),
      ),
    );
  }
}
