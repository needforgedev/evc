import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../l10n/app_strings.dart';
import '../../state/onboarding_controller.dart';
import '../../state/rider_account.dart';
import '../home/home_screen.dart';

/// Collects a new rider's name (after their number is verified), then creates
/// the account and goes home.
class DetailsScreen extends ConsumerStatefulWidget {
  const DetailsScreen({super.key});

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;

  bool get _valid => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    ref.read(onboardingControllerProvider.notifier).setDetails(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
        );
    setState(() => _busy = true);
    try {
      await ref.read(onboardingControllerProvider.notifier).submit();
      ref.invalidate(currentRiderProvider);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your details')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.of(context).whatsYourName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(AppStrings.of(context).soDriversKnow,
                  style: const TextStyle(color: EvcColors.slate, fontSize: 15)),
              const SizedBox(height: 24),
              Text(AppStrings.of(context).fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Aisha Khan'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Text(AppStrings.of(context).emailOptional,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'you@email.com'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: (_valid && !_busy) ? _continue : null,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(AppStrings.of(context).continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
