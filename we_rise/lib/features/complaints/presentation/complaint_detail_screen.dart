import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/shared/widgets/priority_badge.dart';
import '../../../core/shared/widgets/status_chip.dart';
import '../../../core/shared/widgets/we_rise_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers.dart';
import '../data/providers.dart';
import '../data/seed_data.dart';
import '../domain/closure_rule_validator.dart';
import '../domain/duplicate_detector.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/priority_calculator.dart';
import '../domain/status_machine.dart';

class ComplaintDetailScreen extends ConsumerStatefulWidget {
  const ComplaintDetailScreen({super.key, required this.complaintId});

  final String complaintId;

  @override
  ConsumerState<ComplaintDetailScreen> createState() =>
      _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen> {
  static const _uuid = Uuid();
  bool _busy = false;
  List<Confirmation> _confirmations = const [];

  @override
  void initState() {
    super.initState();
    _loadConfirmations();
  }

  Future<void> _loadConfirmations() async {
    final list = await ref
        .read(confirmationRepositoryProvider)
        .getForComplaint(widget.complaintId);
    if (mounted) {
      setState(() => _confirmations = list);
    }
  }

  Future<void> _support(Complaint complaint) async {
    final userId = ref.read(currentUserProvider)?.id ?? 'u-citizen-1';
    if (complaint.supporterIds.contains(userId)) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(complaintRepositoryProvider);
      final updated = await repo.addSupporter(complaint.id, userId);
      final newScore = const PriorityCalculator()
          .score(updated, recurrenceCount: updated.reopenCount)
          .total;
      await repo.update(updated.copyWith(priorityScore: newScore));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmFix(Complaint complaint, {required bool approved}) async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? 'u-citizen-1';

    final confRepo = ref.read(confirmationRepositoryProvider);
    final already = await confRepo.hasUserConfirmed(complaint.id, userId);
    if (already) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already submitted a confirmation.')),
        );
      }
      return;
    }

    String? rejectReason;
    if (!approved && mounted) {
      rejectReason = await _askRejectReason(context);
      if (rejectReason == null) return;
    }

    setState(() => _busy = true);
    try {
      final locRes =
          await ref.read(locationServiceProvider).getCurrentLocation();
      // In demo mode (non-live GPS), use complaint location if user is testing
      final userLoc =
          locRes.isLiveGps ? locRes.location : complaint.location;

      final dist = DuplicateDetector.haversineMetres(
        userLoc.latitude,
        userLoc.longitude,
        complaint.location.latitude,
        complaint.location.longitude,
      );

      final isReporter = userId == complaint.reporterId;
      if (!isReporter && dist > ClosureRuleValidator.kNearbyMetres) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be within 300 m of the issue to confirm.'),
            ),
          );
        }
        return;
      }

      final conf = Confirmation(
        id: _uuid.v4(),
        complaintId: complaint.id,
        userId: userId,
        kind: isReporter
            ? ConfirmationKind.reporter
            : ConfirmationKind.nearby,
        approved: approved,
        at: DateTime.now(),
        userLocation: userLoc,
        reason: rejectReason,
      );
      await confRepo.create(conf);
      final allConfs = await confRepo.getForComplaint(complaint.id);
      if (mounted) setState(() => _confirmations = allConfs);

      final compRepo = ref.read(complaintRepositoryProvider);
      if (!approved) {
        final next = StatusMachine.transition(
          complaint.status,
          ComplaintStatus.REOPENED,
        );
        final updated = await compRepo.addStatusEvent(
          complaint.id,
          StatusEvent(
            complaintId: complaint.id,
            status: next,
            at: DateTime.now(),
            actorRole: user?.role.name ?? 'citizen',
            note: rejectReason,
          ),
        );
        await compRepo
            .update(updated.copyWith(reopenCount: updated.reopenCount + 1));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.rejectedReopened)),
          );
        }
        return;
      }

      final check = ClosureRuleValidator.canClose(
        complaint: complaint,
        confirmations: allConfs,
        resolverId: complaint.assignedOrgId ?? 'resolver-unknown',
      );

      if (check.isAllowed) {
        final next = StatusMachine.transition(
          complaint.status,
          ComplaintStatus.SOLVED,
        );
        await compRepo.addStatusEvent(
          complaint.id,
          StatusEvent(
            complaintId: complaint.id,
            status: next,
            at: DateTime.now(),
            actorRole: 'community',
            note: 'Verified by original reporter and 2 nearby residents.',
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as Problem Solved!')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Confirmation recorded. ${check.reason}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askRejectReason(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Why is this not fixed?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Briefly describe what is still broken...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(ctx, text.isEmpty ? 'Issue persists' : text);
            },
            child: const Text('Reopen'),
          ),
        ],
      ),
    );
  }

  Future<void> _reportAbuse(Complaint complaint) async {
    final reported = ref.read(reportedAbuseIdsProvider);
    ref.read(reportedAbuseIdsProvider.notifier).state = {
      ...reported,
      complaint.id,
    };
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abuse report submitted to moderators.'),
        ),
      );
    }
  }

  Future<void> _blockReporter(Complaint complaint) async {
    final blocked = ref.read(blockedUsersProvider);
    ref.read(blockedUsersProvider.notifier).state = {
      ...blocked,
      complaint.reporterId,
    };
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked. Their reports are hidden.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? 'u-citizen-1';
    final complaintsAsync = ref.watch(allComplaintsProvider);
    final reportedAbuse = ref.watch(reportedAbuseIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trackingIdLabel),
        actions: [
          complaintsAsync.whenOrNull(
                data: (all) {
                  final c =
                      all.where((x) => x.id == widget.complaintId).firstOrNull;
                  if (c == null) return const SizedBox.shrink();
                  return PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'abuse') _reportAbuse(c);
                      if (val == 'block') _blockReporter(c);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'abuse',
                        child: Row(
                          children: [
                            const Icon(Icons.flag_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              reportedAbuse.contains(c.id)
                                  ? 'Abuse reported'
                                  : l10n.reportAbuse,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            const Icon(Icons.block, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.blockUser),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: complaintsAsync.when(
        data: (all) {
          final complaint =
              all.where((c) => c.id == widget.complaintId).firstOrNull;
          if (complaint == null) {
            return const Center(child: Text('Complaint not found'));
          }

          final hasSupported = complaint.supporterIds.contains(userId);
          final priority = const PriorityCalculator().score(
            complaint,
            recurrenceCount: complaint.reopenCount,
          );
          final isGalleryFlagged =
              complaint.photos.any((p) => p.isGalleryFlagged);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      complaint.trackingId,
                      style: AppTextStyles.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: complaint.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PriorityBadge(score: priority.total),
                  if (complaint.escalated)
                    Chip(
                      label: Text(
                        l10n.statusEscalated,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: AppColors.statusEscalated,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (isGalleryFlagged)
                    const Chip(
                      label: Text(
                        'Gallery photo (>24h)',
                        style: TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Color(0xFFFFF3CD),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Photos ───────────────────────────────────────────────────
              if (complaint.photos.isNotEmpty) ...[
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: complaint.photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final p = complaint.photos[i];
                      return ClipRRect(
                        borderRadius: const BorderRadius.all(AppRadius.md),
                        child: Container(
                          width: 220,
                          color: Colors.grey.shade200,
                          child: p.url.startsWith('http')
                              ? Image.network(
                                  p.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image, size: 40),
                                  ),
                                )
                              : File(p.url).existsSync()
                                  ? Image.file(File(p.url), fit: BoxFit.cover)
                                  : const Center(
                                      child: Icon(Icons.image, size: 40),
                                    ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Issue metadata ───────────────────────────────────────────
              WeRiseCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.category.displayName,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ward: ${_wardName(complaint.wardId)}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (complaint.note != null) ...[
                      const SizedBox(height: 8),
                      Text(complaint.note!, style: AppTextStyles.bodyLarge),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── DEMAND ACTION (Support) ──────────────────────────────────
              if (complaint.status != ComplaintStatus.SOLVED &&
                  complaint.status != ComplaintStatus.REJECTED)
                FilledButton.icon(
                  key: const Key('demand_action_btn'),
                  onPressed: _busy || hasSupported
                      ? null
                      : () => _support(complaint),
                  icon: Icon(
                    hasSupported ? Icons.check_circle : Icons.campaign_outlined,
                  ),
                  label: Text(
                    hasSupported
                        ? '${l10n.supported} (${complaint.supportCount})'
                        : '${l10n.supportComplaint} (${complaint.supportCount})',
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // ── Confirm Fix Flow (when AWAITING_CONFIRMATION) ────────────
              if (complaint.status == ComplaintStatus.AWAITING_CONFIRMATION)
                WeRiseCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  highlighted: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.confirmFixed, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        l10n.confirmFixedDesc,
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_confirmations.where((c) => c.approved).length} ${l10n.confirmations} recorded '
                        '(requires original reporter + 2 nearby residents)',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _confirmFix(complaint, approved: true),
                              icon: const Icon(Icons.check),
                              label: Text(l10n.confirmLabel),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () =>
                                      _confirmFix(complaint, approved: false),
                              icon: const Icon(Icons.close),
                              label: Text(l10n.rejectLabel),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ── "Why this priority?" Explainer ───────────────────────────
              WeRiseCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  key: const Key('priority_explainer_tile'),
                  leading: const Icon(Icons.analytics_outlined,
                      color: AppColors.primary),
                  title: Text(l10n.whyThisPriority,
                      style: AppTextStyles.titleSmall),
                  subtitle: Text(
                    'Score: ${priority.total.toStringAsFixed(1)} / 100',
                    style: AppTextStyles.caption,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: priority.components.map((comp) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${comp.label} (${(comp.weight * 100).round()}%)',
                                        style: AppTextStyles.titleSmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+${(comp.contribution * 100).toStringAsFixed(1)}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(value: comp.score),
                                const SizedBox(height: 2),
                                Text(comp.explanation,
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Timeline Stepper ─────────────────────────────────────────
              const Text('Timeline', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (complaint.timeline.isEmpty)
                const Text('No status events recorded.',
                    style: AppTextStyles.bodySmall)
              else
                ...List.generate(complaint.timeline.length, (i) {
                  final e = complaint.timeline[i];
                  final isLast = i == complaint.timeline.length - 1;
                  return _TimelineStepRow(event: e, isLast: isLast);
                }),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  static String _wardName(String wardId) {
    for (final w in SeedData.wards) {
      if (w.id == wardId) return w.name;
    }
    return wardId;
  }
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({required this.event, required this.isLast});

  final StatusEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ts = '${event.at.day.toString().padLeft(2, '0')}/'
        '${event.at.month.toString().padLeft(2, '0')}/${event.at.year} '
        '${event.at.hour.toString().padLeft(2, '0')}:'
        '${event.at.minute.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: isLast ? AppColors.primary : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.status.displayName,
                      style: AppTextStyles.titleSmall),
                  Text('Role: ${event.actorRole} · $ts',
                      style: AppTextStyles.caption),
                  if (event.note != null) ...[
                    const SizedBox(height: 2),
                    Text(event.note!, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
