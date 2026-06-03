import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/onboarding_controller.dart';
import 'details_screen.dart';

/// Driver phone-number entry (UAE) — first onboarding step. Any number works.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  bool get _valid => _controller.text.length >= 9;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    ref.read(onboardingControllerProvider.notifier)
        .setPhone('+971${_controller.text}');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DetailsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Driver sign up',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Enter your mobile number to get started.',
                  style: TextStyle(color: EvcColors.slate, fontSize: 15)),
              const SizedBox(height: 28),
              Row(
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: EvcColors.mist,
                      borderRadius: BorderRadius.circular(EvcRadius.sm),
                      border: Border.all(color: EvcColors.line),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🇦🇪  +971',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(hintText: '50 123 4567'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
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
