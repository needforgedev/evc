import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

import '../../state/driver_account.dart';
import '../../state/onboarding_controller.dart';
import 'registration_complete_screen.dart';

/// Collects a new driver's profile + EV details (after their number is verified),
/// then persists the account and moves to document upload.
class DetailsScreen extends ConsumerStatefulWidget {
  const DetailsScreen({super.key});

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _model = TextEditingController();
  final _plate = TextEditingController();
  final _battery = TextEditingController(text: '80');
  final _range = TextEditingController(text: '320');
  OwnershipType _ownership = OwnershipType.driver;
  bool _busy = false;

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _model.text.trim().isNotEmpty &&
      _plate.text.trim().isNotEmpty;

  @override
  void dispose() {
    for (final c in [_name, _email, _model, _plate, _battery, _range]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _continue() async {
    ref.read(onboardingControllerProvider.notifier).setDetails(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          vehicleModel: _model.text.trim(),
          plate: _plate.text.trim(),
          ownership: _ownership,
          batteryPercent: int.tryParse(_battery.text) ?? 80,
          rangeKm: int.tryParse(_range.text) ?? 320,
        );
    setState(() => _busy = true);
    try {
      await ref.read(onboardingControllerProvider.notifier).submit();
      ref.invalidate(currentDriverProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RegistrationCompleteScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your details')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  _label('Full name'),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Omar Al Farsi'),
                    onChanged: (_) => setState(() {}),
                  ),
                  _label('Email (optional)'),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'you@email.com'),
                  ),
                  const SizedBox(height: 20),
                  const Text('Your EV',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  _label('Model'),
                  TextField(
                    controller: _model,
                    decoration:
                        const InputDecoration(hintText: 'Tesla Model 3'),
                    onChanged: (_) => setState(() {}),
                  ),
                  _label('Plate'),
                  TextField(
                    controller: _plate,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'K 48213'),
                    onChanged: (_) => setState(() {}),
                  ),
                  _label('Ownership'),
                  SegmentedButton<OwnershipType>(
                    segments: const [
                      ButtonSegment(
                          value: OwnershipType.driver,
                          label: Text('Driver-owned')),
                      ButtonSegment(
                          value: OwnershipType.company,
                          label: Text('Company')),
                    ],
                    selected: {_ownership},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) =>
                        setState(() => _ownership = v.first),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Battery %'),
                            TextField(
                              controller: _battery,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Range (km)'),
                            TextField(
                              controller: _range,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: FilledButton(
                onPressed: (_valid && !_busy) ? _continue : null,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}
