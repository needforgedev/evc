import 'package:flutter/material.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import 'phone_screen.dart';

/// Branded welcome screen — entry point of the Rider mock.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [EvcColors.primaryDark, EvcColors.primary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(EvcRadius.lg),
                  ),
                  child: const Icon(Icons.electric_car,
                      color: Colors.white, size: 56),
                ),
                const SizedBox(height: 28),
                const Text(
                  'EVC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Dubai's all-electric ride.\nZero emissions, every trip.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const Spacer(flex: 3),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: EvcColors.primaryDark,
                  ),
                  onPressed: () => _goToPhone(context),
                  child: const Text('Get started'),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => _goToPhone(context),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('I already have an account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToPhone(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneScreen()),
    );
  }
}