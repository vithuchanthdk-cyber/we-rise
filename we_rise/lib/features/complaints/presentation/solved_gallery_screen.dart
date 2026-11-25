import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/shared/widgets/status_chip.dart';
import '../../../core/shared/widgets/we_rise_card.dart';
import '../../../core/theme/app_theme.dart';
import '../data/providers.dart';
import '../domain/enums.dart';
import '../domain/models.dart';

class SolvedGalleryScreen extends ConsumerWidget {
  const SolvedGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final complaintsAsync = ref.watch(allComplaintsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.problemsSolvedTitle)),
      body: complaintsAsync.when(
        data: (all) {
          final solved = all
              .where((c) => c.status == ComplaintStatus.SOLVED)
              .toList()
            ..sort((a, b) =>
                b.lastStatusChangeAt.compareTo(a.lastStatusChangeAt));

          if (solved.isEmpty) {
            return const Center(child: Text('No solved issues yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: solved.length,
            itemBuilder: (context, i) {
              final c = solved[i];
              final days = c.lastStatusChangeAt
                  .difference(c.createdAt)
                  .inDays
                  .clamp(1, 365);

              return WeRiseCard(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                onTap: () => context.push('/complaint/${c.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${c.category.displayName} · ${c.wardId}',
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        StatusChip(status: c.status, small: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.trackingId} · Resolved in $days day(s)',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _PhotoBox(
                            label: 'Before',
                            photo: c.photos.firstOrNull,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PhotoBox(
                            label: 'After',
                            photo: c.afterPhotos.firstOrNull,
                          ),
                        ),
                      ],
                    ),
                  ],
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

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.label, this.photo});
  final String label;
  final ComplaintPhoto? photo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 100,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: photo == null
                ? const Center(
                    child: Icon(Icons.verified, color: AppColors.success),
                  )
                : photo!.url.startsWith('http')
                    ? Image.network(
                        photo!.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image_outlined),
                        ),
                      )
                    : File(photo!.url).existsSync()
                        ? Image.file(File(photo!.url), fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.image_outlined)),
          ),
        ),
      ],
    );
  }
}
