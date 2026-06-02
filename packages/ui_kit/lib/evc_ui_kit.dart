/// EVC design system — shared theme, tokens and brand widgets used by all
/// three apps. Edit once here and Rider, Driver and Admin all pick it up.
library;

import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';

/// EVC brand palette. Green carries the all-electric, zero-emission promise.
abstract final class EvcColors {
  static const Color primary = Color(0xFF00C853); // EV green
  static const Color primaryDark = Color(0xFF009C42);
  static const Color ink = Color(0xFF0B1F17); // near-black, slightly green
  static const Color slate = Color(0xFF5B6B63); // muted text
  static const Color mist = Color(0xFFF4F7F5); // app background
  static const Color line = Color(0xFFE4EAE6); // hairlines
  static const Color surface = Color(0xFFFFFFFF);
  static const Color positive = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB300);
  static const Color danger = Color(0xFFE53935);
}

/// Corner radius scale used across the apps.
abstract final class EvcRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
}

/// The shared Material 3 theme for every EVC app.
ThemeData evcTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: EvcColors.primary,
    primary: EvcColors.primary,
    brightness: Brightness.light,
  ).copyWith(surface: EvcColors.surface);

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  return base.copyWith(
    scaffoldBackgroundColor: EvcColors.mist,
    textTheme: base.textTheme.apply(
      bodyColor: EvcColors.ink,
      displayColor: EvcColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: EvcColors.ink,
      titleTextStyle: TextStyle(
        color: EvcColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: EvcColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvcRadius.md),
        side: const BorderSide(color: EvcColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: EvcColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EvcRadius.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: EvcColors.ink,
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: EvcColors.line),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EvcRadius.md),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: EvcColors.mist,
      hintStyle: const TextStyle(color: EvcColors.slate),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EvcRadius.sm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EvcRadius.sm),
        borderSide: const BorderSide(color: EvcColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EvcRadius.sm),
        borderSide: const BorderSide(color: EvcColors.primary, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: EvcColors.line,
      thickness: 1,
      space: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: EvcColors.mist,
      side: const BorderSide(color: EvcColors.line),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvcRadius.sm),
      ),
    ),
  );
}

/// Small "CO₂ saved" pill — the sustainability brand hook, reused across apps.
class Co2Badge extends StatelessWidget {
  const Co2Badge({super.key, required this.kg, this.compact = false});

  final double kg;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: EvcColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(EvcRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_rounded, size: 14, color: EvcColors.primaryDark),
          const SizedBox(width: 4),
          Text(
            '${kg.toStringAsFixed(1)} kg CO₂ saved',
            style: TextStyle(
              color: EvcColors.primaryDark,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Temporary branded landing screen used by app shells not yet built out
/// (Driver, Admin). Rider has its own full UI.
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
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(app.tagline, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            const Chip(label: Text('Shared core + UI kit ✓')),
          ],
        ),
      ),
    );
  }
}