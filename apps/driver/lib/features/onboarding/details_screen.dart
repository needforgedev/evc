import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

import '../../l10n/app_strings.dart';
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
  String _tier = 'go';
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
          tier: _tier,
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
    final tr = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr.yourDetails)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  _label(tr.fullName),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Omar Al Farsi'),
                    onChanged: (_) => setState(() {}),
                  ),
                  _label(tr.emailOptional),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'you@email.com'),
                  ),
                  const SizedBox(height: 20),
                  Text(tr.yourEv,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  _label(tr.model),
                  TextField(
                    controller: _model,
                    decoration:
                        const InputDecoration(hintText: 'Tesla Model 3'),
                    onChanged: (_) => setState(() {}),
                  ),
                  _label(tr.plate),
                  TextField(
                    controller: _plate,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'K 48213'),
                    onChanged: (_) => setState(() {}),
                  ),
                  _label(tr.ownership),
                  SegmentedButton<OwnershipType>(
                    segments: [
                      ButtonSegment(
                          value: OwnershipType.driver,
                          label: Text(tr.driverOwned)),
                      ButtonSegment(
                          value: OwnershipType.company,
                          label: Text(tr.company)),
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
                            _label(tr.batteryPct),
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
                            _label(tr.rangeKm),
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
                  _label(tr.serviceTier),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final t in const [
                        ('go', 'EVC Go'),
                        ('comfort', 'Comfort'),
                        ('xl', 'XL'),
                        ('premium', 'Premium'),
                      ])
                        ChoiceChip(
                          label: Text(t.$2),
                          selected: _tier == t.$1,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _tier = t.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'The ride class your vehicle serves — riders requesting it are matched to you.',
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
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
                    : Text(tr.continueLabel),
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
