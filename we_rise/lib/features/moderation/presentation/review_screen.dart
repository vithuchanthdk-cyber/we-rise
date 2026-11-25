import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/shared/widgets/status_chip.dart';
import '../../../core/shared/widgets/we_rise_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../complaints/data/providers.dart';
import '../../complaints/domain/duplicate_detector.dart';
import '../../complaints/domain/enums.dart';
import '../../complaints/domain/models.dart';
import '../../complaints/domain/routing_engine.dart';
import '../../complaints/domain/status_machine.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.complaintId});
  final String complaintId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  static const _uuid = Uuid();
  bool _busy = false;

  Future<void> _approve(Complaint c) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(complaintRepositoryProvider);
      final taskRepo = ref.read(taskRepositoryProvider);

      final verified = StatusMachine.transition(
        c.status,
        ComplaintStatus.VERIFIED,
      );
      final routing = RoutingEngine.route(c.category, c.riskClass);

      final updated = await repo.addStatusEvent(
        c.id,
        StatusEvent(
          complaintId: c.id,
          status: verified,
          at: DateTime.now(),
          actorRole: 'moderator',
          note: 'Approved and routed to ${routing.assignedTo}.',
        ),
      );

      if (routing.isAuthority) {
        await repo.update(
          updated.copyWith(assignedAuthorityId: 'org-gcc-1'),
        );
      } else {
        const partnerOrgId = 'org-ngo-1';
        await repo.update(
          updated.copyWith(assignedOrgId: partnerOrgId),
        );
        await taskRepo.create(
          Task(
            id: _uuid.v4(),
            complaintId: c.id,
            partnerOrgId: partnerOrgId,
            requirements: const ['gloves', 'trash bags'],
            createdAt: DateTime.now(),
            supervisorId: 'u-partner-1',
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approved (${routing.assignedTo}).')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(Complaint c) async {
    final l10n = AppLocalizations.of(context);
    RejectionReason selected = RejectionReason.fakePhoto;
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.reject),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...RejectionReason.values.map(
                (r) => RadioListTile<RejectionReason>(
                  title: Text(r.displayName),
                  value: r,
                  groupValue: selected,
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selected = v);
                  },
                ),
              ),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Optional moderator note',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.reject),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(complaintRepositoryProvider);
      final rejected = StatusMachine.transition(
        c.status,
        ComplaintStatus.REJECTED,
      );
      final updated = await repo.addStatusEvent(
        c.id,
        StatusEvent(
          complaintId: c.id,
          status: rejected,
          at: DateTime.now(),
          actorRole: 'moderator',
          note: '${selected.displayName} ${noteCtrl.text.trim()}'.trim(),
        ),
      );
      await repo.update(
        updated.copyWith(
          rejectionReason: selected,
          rejectionNote:
              noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mergeDuplicate(Complaint incoming, Complaint target) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(complaintRepositoryProvider);
      await repo.addSupporter(target.id, incoming.reporterId);
      final rejected = StatusMachine.transition(
        incoming.status,
        ComplaintStatus.REJECTED,
      );
      final updated = await repo.addStatusEvent(
        incoming.id,
        StatusEvent(
          complaintId: incoming.id,
          status: rejected,
          at: DateTime.now(),
          actorRole: 'moderator',
          note: 'Merged as duplicate into ${target.trackingId}.',
        ),
      );
      await repo.update(updated.copyWith(mergedIntoId: target.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Merged into ${target.trackingId}.')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final complaintsAsync = ref.watch(allComplaintsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moderator Review')),
      body: complaintsAsync.when(
        data: (all) {
          final c = all.where((x) => x.id == widget.complaintId).firstOrNull;
          if (c == null) {
            return const Center(child: Text('Complaint not found'));
          }

          final duplicates = DuplicateDetector.findCandidates(c, all);
          final hasGallery =
              c.photos.any((p) => p.source == PhotoSource.gallery);
          final isFlagged = c.photos.any((p) => p.isGalleryFlagged);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(c.trackingId, style: AppTextStyles.titleLarge),
                  StatusChip(status: c.status),
                ],
              ),
              const SizedBox(height: 8),
              if (hasGallery || isFlagged)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(30),
                    border: Border.all(color: AppColors.warning),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isFlagged
                              ? 'Gallery photo (>24h old EXIF). Location came from live device GPS.'
                              : 'Submitted from device gallery.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

              // Photos
              if (c.photos.isNotEmpty) ...[
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: c.photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final p = c.photos[i];
                      return ClipRRect(
                        borderRadius: const BorderRadius.all(AppRadius.md),
                        child: Container(
                          width: 200,
                          color: Colors.grey.shade200,
                          child: p.url.startsWith('http')
                              ? Image.network(
                                  p.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 40),
                                )
                              : File(p.url).existsSync()
                                  ? Image.file(File(p.url), fit: BoxFit.cover)
                                  : const Icon(Icons.image, size: 40),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              WeRiseCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.category.displayName} · Risk: ${c.riskClass.name.toUpperCase()}',
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('Ward: ${c.wardId}', style: AppTextStyles.bodyMedium),
                    if (c.note != null) ...[
                      const SizedBox(height: 6),
                      Text(c.note!, style: AppTextStyles.bodyMedium),
                    ],
                    // Moderator-only visibility of on-behalf-of details
                    if (c.onBehalfOf != null) ...[
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.person_pin,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'On behalf of (Moderator only): ${c.onBehalfOf}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Duplicate suggestions
              if (duplicates.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(25),
                    border: Border.all(color: AppColors.secondary),
                    borderRadius: const BorderRadius.all(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.duplicateWarning,
                        style: AppTextStyles.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...duplicates.map(
                        (dup) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(dup.trackingId),
                          subtitle: Text(
                            '${dup.category.displayName} · ${dup.supportCount} supporters',
                          ),
                          trailing: FilledButton(
                            key: const Key('merge_duplicate_btn'),
                            onPressed:
                                _busy ? null : () => _mergeDuplicate(c, dup),
                            child: Text(l10n.markDuplicate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('approve_btn'),
                      onPressed: _busy ? null : () => _approve(c),
                      icon: const Icon(Icons.check),
                      label: Text(l10n.approve),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('reject_btn'),
                      onPressed: _busy ? null : () => _reject(c),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.reject),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
