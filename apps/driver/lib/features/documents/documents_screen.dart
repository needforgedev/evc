import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/driver_documents.dart';

/// Real document upload — each document is captured/picked and uploaded
/// individually to Supabase Storage. In [gate] mode there's no back button:
/// the driver must upload every document before reaching the dashboard.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key, this.gate = false});

  final bool gate;

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final _picker = ImagePicker();
  final Set<String> _busy = {};

  Future<void> _upload(String type, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked == null) return;
      setState(() => _busy.add(type));
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'jpg';
      await DocActions.upload(type, bytes, ext);
      ref.invalidate(driverDocumentsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(type));
    }
  }

  void _pickSource(String type) {
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
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: EvcColors.ink),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _upload(type, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: EvcColors.ink),
              title: const Text('Choose from library'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _upload(type, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(driverDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.gate,
        title: Text(widget.gate ? 'Upload documents' : 'Documents'),
      ),
      body: SafeArea(
        child: docsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load documents.\n$e')),
          data: (docs) {
            final uploaded = docs.length;
            final total = kDriverDocTypes.length;
            final complete = uploaded >= total;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    children: [
                      Text(
                        widget.gate
                            ? 'Upload all $total documents to finish setting up '
                                'your account. Ops verify them before you go online.'
                            : 'Upload a clear photo of each document.',
                        style: const TextStyle(color: EvcColors.slate),
                      ),
                      const SizedBox(height: 16),
                      for (final (type, label) in kDriverDocTypes)
                        _DocRow(
                          label: label,
                          info: docs[type],
                          busy: _busy.contains(type),
                          onUpload: () => _pickSource(type),
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: EvcColors.surface,
                    border: Border(top: BorderSide(color: EvcColors.line)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Row(
                        children: [
                          Icon(
                              complete
                                  ? Icons.check_circle
                                  : Icons.cloud_upload_outlined,
                              color: complete
                                  ? EvcColors.primary
                                  : EvcColors.slate,
                              size: 20),
                          const SizedBox(width: 8),
                          Text('$uploaded of $total uploaded',
                              style: TextStyle(
                                  color: complete
                                      ? EvcColors.primaryDark
                                      : EvcColors.slate,
                                  fontWeight: FontWeight.w700)),
                          const Spacer(),
                          if (widget.gate && complete)
                            const Text('Opening dashboard…',
                                style: TextStyle(
                                    color: EvcColors.slate, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Robust card: a stretch Column so the label/status always lay out
/// horizontally (no `Expanded` inside a Row → no zero-width vertical text).
class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.label,
    required this.info,
    required this.busy,
    required this.onUpload,
  });

  final String label;
  final DocInfo? info;
  final bool busy;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final uploaded = info != null;
    final (statusText, statusColor) = switch (info?.reviewStatus) {
      'approved' => ('Verified', EvcColors.primaryDark),
      'rejected' => ('Rejected — please re-upload', EvcColors.danger),
      'pending' => ('In review', EvcColors.warning),
      _ => ('Not uploaded', EvcColors.slate),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EvcColors.surface,
        borderRadius: BorderRadius.circular(EvcRadius.md),
        border: Border.all(color: EvcColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  uploaded ? Icons.check_circle : Icons.circle_outlined,
                  size: 15,
                  color: statusColor),
              const SizedBox(width: 6),
              Text(statusText,
                  style: TextStyle(color: statusColor, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          if (busy)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5)),
            ))
          else if (uploaded)
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Replace'),
            )
          else
            FilledButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Upload'),
            ),
        ],
      ),
    );
  }
}
