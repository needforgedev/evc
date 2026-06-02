import 'package:flutter/material.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../shell/main_shell.dart';

/// Driver compliance / verification status. A driver can't go online until
/// Admin approves their documents — here everything is verified.
class ApprovalScreen extends StatelessWidget {
  const ApprovalScreen({super.key});

  static const _docs = [
    ('Driving license', 'Verified'),
    ('RTA driver permit', 'Verified'),
    ('Emirates ID', 'Verified'),
    ('Vehicle registration & insurance', 'Verified'),
    ('EV — Tesla Model 3 · K 48213', 'Approved'),
    ('Onboarding training', 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: EvcColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(EvcRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: EvcColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("You're approved to drive",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                  const Text(
                                      'All documents verified by EVC ops',
                                      style: TextStyle(color: EvcColors.slate)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Your documents',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  for (final (title, status) in _docs)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.check_circle,
                            color: EvcColors.primary),
                        title: Text(title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        trailing: Text(status,
                            style: const TextStyle(
                                color: EvcColors.primaryDark,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (route) => false,
                ),
                child: const Text('Start driving'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}