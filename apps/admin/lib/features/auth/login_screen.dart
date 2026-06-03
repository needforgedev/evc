import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/admin_session.dart';
import '../shell/main_shell.dart';

/// Admin sign-in (email + password). Admins are provisioned in the Supabase
/// dashboard — there is no in-app signup.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      await AdminAuth.signIn(_email.text, _password.text);
      ref.invalidate(currentAdminProvider);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_message(e))));
    }
  }

  String _message(Object e) {
    final s = e.toString();
    if (s.contains('Invalid login')) return 'Invalid email or password.';
    return s.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: EvcColors.ink,
                  borderRadius: BorderRadius.circular(EvcRadius.md),
                ),
                child: const Icon(Icons.shield_moon_outlined,
                    color: EvcColors.primary, size: 32),
              ),
              const SizedBox(height: 20),
              Text('EVC Admin',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Text('Operations control panel',
                  style: TextStyle(color: EvcColors.slate, fontSize: 15)),
              const SizedBox(height: 32),
              const Text('Work email',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.alternate_email),
                    hintText: 'you@evc.ae'),
              ),
              const SizedBox(height: 16),
              const Text('Password',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _password,
                obscureText: true,
                onSubmitted: (_) => _busy ? null : _signIn(),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline)),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _signIn,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Super-admin · Ops · Finance · Support',
                    style: TextStyle(color: EvcColors.slate, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
