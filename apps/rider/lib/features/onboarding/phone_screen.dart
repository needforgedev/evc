import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../l10n/app_strings.dart';
import '../../state/onboarding_controller.dart';
import 'otp_screen.dart';

/// Phone-number entry (UAE) — first onboarding step. Sends a real OTP.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  bool get _valid => _controller.text.length >= 9;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final phone = '+971${_controller.text}';
    ref.read(onboardingControllerProvider.notifier).setPhone(phone);
    setState(() => _busy = true);
    try {
      await EvcOtp.requestOtp(phone);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OtpScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
              Text(
                AppStrings.of(context).enterMobile,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.of(context).otpSubtitle,
                style: const TextStyle(color: EvcColors.slate, fontSize: 15),
              ),
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
                onPressed: (_valid && !_busy) ? _continue : null,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(AppStrings.of(context).sendCode),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.of(context).termsNote,
                textAlign: TextAlign.center,
                style: const TextStyle(color: EvcColors.slate, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
