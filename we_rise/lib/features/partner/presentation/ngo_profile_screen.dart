import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shared/widgets/we_rise_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../complaints/data/providers.dart';
import '../../complaints/domain/enums.dart';
import '../../complaints/domain/models.dart';

class NgoProfileScreen extends ConsumerWidget {
  const NgoProfileScreen({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgRepo = ref.watch(orgRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Profile')),
      body: FutureBuilder<Organisation?>(
        future: orgRepo.getById(orgId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final org = snap.data;
          if (org == null) {
            return const Center(child: Text('Organisation not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              WeRiseCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            org.name.substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(org.name, style: AppTextStyles.titleLarge),
                              Text(
                                org.type.name.toUpperCase(),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Wards served: ${org.wardIds.join(', ')}'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(label: 'Resolved', value: '${org.resolvedCount}'),
                        _Stat(
                          label: 'Volunteers',
                          value: '${org.activeVolunteerCount}',
                        ),
                        _Stat(
                          label: 'Avg Days',
                          value: org.avgResolutionDays.toStringAsFixed(1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Community Badges (Secondary)',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BadgeType.values
                    .map(
                      (b) => Chip(
                        avatar: const Icon(Icons.verified, size: 18),
                        label: Text(b.displayName),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
