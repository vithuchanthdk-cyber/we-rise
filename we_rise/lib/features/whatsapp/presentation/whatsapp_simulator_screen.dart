import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../complaints/data/providers.dart';
import '../domain/whatsapp_parser.dart';

/// Moderator/Admin-only WhatsApp intake simulator (no external API calls).
class WhatsAppSimulatorScreen extends ConsumerStatefulWidget {
  const WhatsAppSimulatorScreen({super.key});

  @override
  ConsumerState<WhatsAppSimulatorScreen> createState() =>
      _WhatsAppSimulatorScreenState();
}

class _WhatsAppSimulatorScreenState
    extends ConsumerState<WhatsAppSimulatorScreen> {
  final _msgController = TextEditingController();
  final _senderController = TextEditingController(text: 'WA-ANON-01');
  bool _submitting = false;

  @override
  void dispose() {
    _msgController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  Future<void> _simulate() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final repo = ref.read(complaintRepositoryProvider);
      final seq = await repo.nextSequenceNumber();
      final complaint = WhatsAppParser.parseToComplaint(
        message: text,
        senderToken: _senderController.text.trim().isEmpty
            ? 'WA-ANON'
            : _senderController.text.trim(),
        sequenceNumber: seq,
      );
      await repo.create(complaint);
      _msgController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Created PENDING_REVIEW report: ${complaint.trackingId}',
            ),
            action: SnackBarAction(
              label: 'Review',
              onPressed: () =>
                  context.push('/moderation/review/${complaint.id}'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp Intake Simulator')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: const BorderRadius.all(AppRadius.md),
            ),
            child: const Text(
              'Demo Simulator (offline, no external API calls). '
              'Paste an English or Tamil WhatsApp message to create a '
              'PENDING_REVIEW report for moderator verification.',
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _senderController,
            decoration: const InputDecoration(
              labelText: 'Sender token (hashed in production)',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('wa_message_field'),
            controller: _msgController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Incoming WhatsApp message (EN or தமிழ்)',
              hintText:
                  'e.g. Sewage leak near Tondiarpet / தண்டையார்பேட்டை கழிவுநீர் கசிவு',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Sample (EN)'),
                onPressed: () => _msgController.text =
                    'Sewage overflow near Tondiarpet school gate',
              ),
              ActionChip(
                label: const Text('Sample (தமிழ்)'),
                onPressed: () => _msgController.text =
                    'பெருங்குடி பகுதியில் குப்பை தேங்கியுள்ளது',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: const Key('wa_ingest_btn'),
            onPressed: _submitting ? null : _simulate,
            icon: const Icon(Icons.message),
            label: const Text('Ingest into Moderation Queue'),
          ),
        ],
      ),
    );
  }
}
