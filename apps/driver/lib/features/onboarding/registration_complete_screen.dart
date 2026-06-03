import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/driver_account.dart';
import '../../state/onboarding_controller.dart';
import '../shell/main_shell.dart';

/// Shown after a successful registration. The driver account is created and
/// sits in the approval queue until ops verify the documents.
class RegistrationCompleteScreen extends ConsumerWidget {
  const RegistrationCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.read(onboardingControllerProvider);
    final persisted = EvcSupabase.isReady;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: EvcColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.how_to_reg,
                      color: EvcColors.primaryDark, size: 44),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Registration submitted',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome, ${draft.fullName.isEmpty ? 'driver' : draft.fullName}. '
                "Your account and ${draft.vehicleModel.isEmpty ? 'EV' : draft.vehicleModel} "
                'are registered and pending ops approval.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: EvcColors.slate, fontSize: 15),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EvcColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(EvcRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_bottom,
                        color: Color(0xFFB78000)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Status: pending approval. You can explore the app, '
                        "but you can't go online until approved.",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              if (!persisted) ...[
                const SizedBox(height: 12),
                const Text(
                  'Running in mock mode — add Supabase credentials to persist '
                  'this driver to the backend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: EvcColors.slate, fontSize: 12),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () {
                  ref.read(onboardingControllerProvider.notifier).reset();
                  ref.invalidate(currentDriverProvider); // load the new driver
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                },
                child: const Text('Continue to dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
