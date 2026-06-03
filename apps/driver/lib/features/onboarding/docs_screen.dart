import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/onboarding_controller.dart';
import 'otp_screen.dart';

/// Mock document upload page. No storage bucket yet — "upload" picks a source
/// and records that the document was provided (metadata persisted on register).
class DocsScreen extends ConsumerWidget {
  const DocsScreen({super.key});

  void _pickSource(BuildContext context, WidgetRef ref, String type) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: EvcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Add document',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            _sourceTile(Icons.photo_camera_outlined, 'Take a photo', ref, type,
                sheetCtx),
            _sourceTile(Icons.photo_library_outlined, 'Choose from library',
                ref, type, sheetCtx),
            _sourceTile(Icons.insert_drive_file_outlined, 'Choose a file', ref,
                type, sheetCtx),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sourceTile(IconData icon, String label, WidgetRef ref, String type,
      BuildContext sheetCtx) {
    return ListTile(
      leading: Icon(icon, color: EvcColors.ink),
      title: Text(label),
      onTap: () {
        ref.read(onboardingControllerProvider.notifier).toggleDoc(type);
        Navigator.of(sheetCtx).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  const Text(
                    'Add your documents for verification. You can finish '
                    'sign-up now — ops review them before you go online.',
                    style: TextStyle(color: EvcColors.slate),
                  ),
                  const SizedBox(height: 16),
                  for (int i = 0; i < kDriverDocTypes.length; i++)
                    _DocRow(
                      label: kDriverDocTypes[i].$2,
                      provided: draft.docs.contains(kDriverDocTypes[i].$1),
                      onUpload: () =>
                          _pickSource(context, ref, kDriverDocTypes[i].$1),
                      onRemove: () => ctrl.toggleDoc(kDriverDocTypes[i].$1),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      '${draft.docs.length} of ${kDriverDocTypes.length} provided',
                      style:
                          const TextStyle(color: EvcColors.slate, fontSize: 13)),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OtpScreen()),
                    ),
                    child: const Text('Continue to verification'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.label,
    required this.provided,
    required this.onUpload,
    required this.onRemove,
  });

  final String label;
  final bool provided;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EvcColors.surface,
        borderRadius: BorderRadius.circular(EvcRadius.md),
        border: Border.all(color: EvcColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: provided
                  ? EvcColors.primary.withValues(alpha: 0.12)
                  : EvcColors.mist,
              borderRadius: BorderRadius.circular(EvcRadius.sm),
            ),
            child: Icon(
              provided ? Icons.check_circle : Icons.description_outlined,
              color: provided ? EvcColors.primary : EvcColors.slate,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(provided ? 'Uploaded · document.jpg' : 'Not uploaded',
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            provided ? EvcColors.primaryDark : EvcColors.slate)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          provided
              ? TextButton(onPressed: onRemove, child: const Text('Remove'))
              : FilledButton.tonal(
                  onPressed: onUpload, child: const Text('Upload')),
        ],
      ),
    );
  }
}
