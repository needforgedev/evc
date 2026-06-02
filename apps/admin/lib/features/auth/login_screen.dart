import 'package:flutter/material.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../shell/main_shell.dart';

/// Admin sign-in (email + password) — ops team access.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'ops@evc.ae');
  final _password = TextEditingController(text: '••••••••');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signIn() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
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
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.alternate_email)),
              ),
              const SizedBox(height: 16),
              const Text('Password',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline)),
              ),
              const Spacer(),
              FilledButton(
                  onPressed: _signIn, child: const Text('Sign in')),
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