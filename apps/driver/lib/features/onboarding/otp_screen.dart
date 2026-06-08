import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/driver_account.dart';
import '../../state/onboarding_controller.dart';
import '../shell/driver_gate.dart';
import 'details_screen.dart';

/// Real OTP verification. On success we sign into the (existing or new) account
/// keyed by phone, then branch: registered driver → dashboard (LOGIN);
/// brand-new → collect details (REGISTER).
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  static const _length = 6;
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
    final phone = ref.read(onboardingControllerProvider).phone;
    setState(() => _busy = true);
    try {
      final ok = await EvcOtp.verifyOtp(phone, _code);
      if (!ok) {
        _focus.unfocus();
        if (mounted) {
          setState(() => _busy = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect or expired code.')),
          );
        }
        return;
      }

      // Establish the session (signs into the existing account, or creates one).
      final uid = await EvcDevAuth.signIn(role: 'driver', phone: phone);
      if (uid == null) throw Exception('Sign-in failed.');

      // Registered already? (has a vehicle) → LOGIN. Otherwise → REGISTER.
      final details = await EvcSupabase.client
          .from('driver_details')
          .select('current_vehicle_id')
          .eq('driver_id', uid)
          .maybeSingle();
      final registered = details?['current_vehicle_id'] != null;

      ref.invalidate(currentDriverProvider);
      if (!mounted) return;
      if (registered) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DriverGate()),
          (route) => false,
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DetailsScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
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
              Text('Enter the 6-digit code we sent to your WhatsApp for $phone.',
                  style: const TextStyle(color: EvcColors.slate, fontSize: 15)),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _focus.requestFocus,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        for (int i = 0; i < _length; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: _otpCell(i),
                            ),
                          ),
                      ],
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
              const Spacer(),
              FilledButton(
                onPressed: (_code.length == _length && !_busy) ? _verify : null,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Verify'),
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
    return AspectRatio(
      aspectRatio: 0.85,
      child: Container(
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
