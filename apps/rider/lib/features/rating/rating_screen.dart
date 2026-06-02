import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/mock_data.dart';
import '../../state/booking_controller.dart';
import '../../state/trip_controller.dart';
import '../home/home_screen.dart';

/// Post-ride rating, tags and tip.
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _rating = 5;
  int? _tip = 5;
  final Set<String> _tags = {};

  static const _tagOptions = [
    'Clean car',
    'Great driving',
    'On time',
    'Friendly',
    'Quiet ride',
    'Safe',
  ];
  static const _tipOptions = [0, 5, 10, 20];

  void _submit() {
    ref.read(tripControllerProvider.notifier).reset();
    ref.read(bookingControllerProvider.notifier).reset();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = MockData.driver;
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Skip',
                style: TextStyle(color: EvcColors.slate)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: driver.avatarColor,
                      child: Text(driver.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('How was your trip\nwith ${driver.name.split(' ').first}?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final active = i < _rating;
                      return IconButton(
                        iconSize: 40,
                        onPressed: () => setState(() => _rating = i + 1),
                        icon: Icon(
                          active ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: active ? EvcColors.warning : EvcColors.line,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _tagOptions.map((t) {
                      final on = _tags.contains(t);
                      return FilterChip(
                        label: Text(t),
                        selected: on,
                        showCheckmark: false,
                        selectedColor: EvcColors.primary.withValues(alpha: 0.14),
                        onSelected: (_) => setState(
                            () => on ? _tags.remove(t) : _tags.add(t)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Add a tip',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: _tipOptions.map((amount) {
                      final on = _tip == amount;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () => setState(() => _tip = amount),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: on
                                  ? EvcColors.primary.withValues(alpha: 0.10)
                                  : null,
                              side: BorderSide(
                                  color:
                                      on ? EvcColors.primary : EvcColors.line),
                            ),
                            child: Text(amount == 0 ? 'None' : 'AED $amount',
                                style: TextStyle(
                                    color: EvcColors.ink,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  const TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                        hintText: 'Leave a comment (optional)'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}