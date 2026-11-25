import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/shared/widgets/status_chip.dart';
import '../../../core/theme/app_theme.dart';
import '../../complaints/data/providers.dart';
import '../../complaints/domain/enums.dart';

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final complaintsAsync = ref.watch(allComplaintsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moderationTitle),
        actions: [
          IconButton(
            tooltip: 'WhatsApp Intake Simulator',
            icon: const Icon(Icons.message_outlined),
            onPressed: () => context.push(Routes.whatsappIntake),
          ),
        ],
      ),
      body: complaintsAsync.when(
        data: (all) {
          final pending = all
              .where((c) =>
                  c.status == ComplaintStatus.PENDING_REVIEW ||
                  c.status == ComplaintStatus.REOPENED)
              .toList();
          if (pending.isEmpty) {
            return const Center(
              child: Text('No pending reports to review.'),
            );
          }
          return ListView.builder(
            itemCount: pending.length,
            itemBuilder: (context, i) {
              final c = pending[i];
              final hasGallery =
                  c.photos.any((p) => p.source == PhotoSource.gallery);
              final isFlagged = c.photos.any((p) => p.isGalleryFlagged);

              return Card(
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.trackingId,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isFlagged || hasGallery)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isFlagged
                                ? AppColors.warning
                                : AppColors.info.withAlpha(40),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isFlagged ? 'Gallery >24h' : 'Gallery photo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isFlagged ? Colors.white : AppColors.info,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${c.category.displayName} · ${c.wardId}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip(status: c.status, small: true),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => context.push('/moderation/review/${c.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
