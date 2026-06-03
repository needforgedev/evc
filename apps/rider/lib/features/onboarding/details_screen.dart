import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/onboarding_controller.dart';
import 'otp_screen.dart';

/// Collects the rider's name (and optional email) before verification.
class DetailsScreen extends ConsumerStatefulWidget {
  const DetailsScreen({super.key});

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();

  bool get _valid => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _continue() {
    ref.read(onboardingControllerProvider.notifier).setDetails(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
        );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OtpScreen()),
    );
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
              Text("What's your name?",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('So drivers know who to pick up.',
                  style: TextStyle(color: EvcColors.slate, fontSize: 15)),
              const SizedBox(height: 24),
              const Text('Full name',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Aisha Khan'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              const Text('Email (optional)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'you@email.com'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _valid ? _continue : null,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
