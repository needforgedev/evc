import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/onboarding_controller.dart';
import '../../state/rider_account.dart';
import '../home/home_screen.dart';

/// Verification step. Dev OTP: any number signs in with the fixed code (7464).
/// On success the rider account is created (real Supabase rows, or mock).
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  static const _length = 4;
  bool _busy = false;

  String get _code => _controller.text;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!verifyDevOtp(_code)) {
      _focus.unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect code. Try the demo code 7464.')),
      );
      return;
    }
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
    final phone = ref.watch(onboardingControllerProvider).phone;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify your number',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Enter the code sent to $phone',
                  style: const TextStyle(color: EvcColors.slate, fontSize: 15)),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _focus.requestFocus,
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_length, _otpCell),
                    ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_length),
                          ],
                          onChanged: (_) => setState(() {}),
                          showCursor: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('Demo code: 7464',
                    style: TextStyle(color: EvcColors.slate, fontSize: 12)),
              ),
              const Spacer(),
              FilledButton(
                onPressed: (_code.length == _length && !_busy) ? _verify : null,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Verify & continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpCell(int i) {
    final filled = i < _code.length;
    final isCursor = i == _code.length;
    return Container(
      width: 64,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: EvcColors.surface,
        borderRadius: BorderRadius.circular(EvcRadius.sm),
        border: Border.all(
          color: isCursor ? EvcColors.primary : EvcColors.line,
          width: isCursor ? 1.8 : 1,
        ),
      ),
      child: Text(filled ? _code[i] : '',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
    );
  }
}
