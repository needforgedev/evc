import 'package:flutter/material.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import 'phone_screen.dart';

/// Driver welcome screen — entry point of the Driver mock.
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
            colors: [EvcColors.ink, EvcColors.primaryDark],
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
                  child: const Icon(Icons.ev_station,
                      color: Colors.white, size: 56),
                ),
                const SizedBox(height: 28),
                const Text(
                  'EVC\nDriver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Drive electric. Earn smart.\nRange-aware trips, charging built in.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PhoneScreen()),
                  ),
                  child: const Text('Sign in to drive'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}