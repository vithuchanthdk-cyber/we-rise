import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/shared/widgets/status_chip.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers.dart';
import '../data/providers.dart';
import '../domain/enums.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  bool _syncing = false;

  Future<void> _syncOffline() async {
    setState(() => _syncing = true);
    try {
      final count = await ref.read(syncServiceProvider).syncPending();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synced $count offline report(s).')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final complaintsAsync = ref.watch(allComplaintsProvider);
    final queueSize = ref.watch(offlineQueueSizeProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myReportsTab)),
      body: Column(
        children: [
          if (queueSize > 0)
            Container(
              width: double.infinity,
              color: AppColors.warning.withAlpha(30),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined,
                      color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('$queueSize ${l10n.pendingUploads}'),
                  ),
                  TextButton(
                    onPressed: _syncing ? null : _syncOffline,
                    child: _syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.syncNow),
                  ),
                ],
              ),
            ),
          Expanded(
            child: complaintsAsync.when(
              data: (all) {
                final mine = user == null
                    ? all
                    : all.where((c) => c.reporterId == user.id).toList();
                final awaiting = mine
                    .where((c) =>
                        c.status == ComplaintStatus.AWAITING_CONFIRMATION)
                    .toList();

                if (mine.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox,
                            size: 64, color: AppColors.textDisabled),
                        SizedBox(height: AppSpacing.md),
                        Text('No reports yet', style: AppTextStyles.titleMedium),
                      ],
                    ),
                  );
                }

                return ListView(
                  children: [
                    if (awaiting.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          'Action needed: Confirm fix (${awaiting.length})',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.warning),
                        ),
                      ),
                      ...awaiting.map(
                        (c) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.verified_outlined,
                                color: AppColors.warning),
                            title: Text(
                              c.trackingId,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Text(
                              '${c.category.displayName} · ${c.wardId}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            trailing: SizedBox(
                              width: 110,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () =>
                                    context.push('/complaint/${c.id}'),
                                child: Text(
                                  l10n.confirmFixed,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            onTap: () => context.push('/complaint/${c.id}'),
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'All my reports (${mine.length})',
                        style: AppTextStyles.titleSmall,
                      ),
                    ),
                    ...mine.map(
                      (c) => ListTile(
                        title: Text(
                          c.trackingId,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: Text(
                          '${c.category.displayName} · ${c.wardId}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        trailing: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: StatusChip(status: c.status, small: true),
                        ),
                        onTap: () => context.push('/complaint/${c.id}'),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}
