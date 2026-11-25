import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';

class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // Logo / wordmark
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.all(AppRadius.md),
                    ),
                    child: const Icon(Icons.trending_up, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WE RISE',
                          style: AppTextStyles.displayMedium
                              .copyWith(color: AppColors.primary)),
                      Text('Chennai Civic',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              const Text('Select language', style: AppTextStyles.titleLarge),
              Text('மொழியைத் தேர்ந்தெடு',
                  style: AppTextStyles.tamilTitle
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              _LangTile(
                label: 'English',
                subtitle: 'English',
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('en');
                  context.go(Routes.rolePicker);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _LangTile(
                label: 'தமிழ்',
                subtitle: 'Tamil',
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('ta');
                  context.go(Routes.rolePicker);
                },
                tamil: true,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.tamil = false,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool tamil;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: const BorderRadius.all(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: tamil
                        ? AppTextStyles.tamilTitle
                        : AppTextStyles.titleMedium,
                  ),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
