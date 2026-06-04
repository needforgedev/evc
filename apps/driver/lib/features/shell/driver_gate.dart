import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/driver_documents.dart';
import '../documents/documents_screen.dart';
import 'main_shell.dart';

/// Decides the driver's landing screen: the dashboard is locked until **all**
/// documents are uploaded. Re-evaluated on every launch (so closing/reopening
/// the app keeps an unverified driver on the upload screen).
class DriverGate extends ConsumerWidget {
  const DriverGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(driverDocumentsProvider);
    return docsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      // On error, don't hard-lock the driver out — let them into the app.
      error: (_, _) => const MainShell(),
      data: (docs) => docs.length >= kDriverDocTypes.length
          ? const MainShell()
          : const DocumentsScreen(gate: true),
    );
  }
}
