import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../home/home_screen.dart';

/// 4-digit OTP verification (mock — any 4 digits work; hint shows "1234").
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  static const _length = 4;

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

  void _verify() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
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
              Text(
                'Verify your number',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the code sent to ${widget.phone}',
                style: const TextStyle(color: EvcColors.slate, fontSize: 15),
              ),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Didn\'t get it? ',
                      style: TextStyle(color: EvcColors.slate)),
                  Text('Resend in 0:24',
                      style: TextStyle(
                          color: EvcColors.ink, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Text('Demo code: 1234',
                      style: TextStyle(color: EvcColors.slate, fontSize: 12)),
                ],
              ),
              const Spacer(),
              FilledButton(
                onPressed: _code.length == _length ? _verify : null,
                child: const Text('Verify'),
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
      child: Text(
        filled ? _code[i] : '',
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
      ),
    );
  }
}