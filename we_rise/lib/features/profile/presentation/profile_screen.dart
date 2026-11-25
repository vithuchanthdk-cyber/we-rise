import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers.dart';
import '../../complaints/data/seed_data.dart';
import '../../complaints/domain/enums.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTab),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user?.anonymousHandle.substring(0, 1) ?? '?',
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  user?.anonymousHandle ?? 'Guest',
                  style: AppTextStyles.titleMedium,
                ),
                Text(
                  user?.role.displayName ?? '',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                if ((user?.volunteerHours ?? 0) > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${user!.volunteerHours.toStringAsFixed(1)} ${l10n.earnedHours}',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Demo Mode Role Switcher ──────────────────────────────────────
          const Text('Switch Demo Role', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: UserRole.values.map((role) {
              final selected = user?.role == role;
              return ChoiceChip(
                label: Text(role.displayName),
                selected: selected,
                onSelected: (_) async {
                  await ref
                      .read(authRepositoryProvider)
                      .setDemoUser(SeedData.userForRole(role));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),

          // ── Role Workspaces & Problem Solved Gallery ─────────────────────
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppColors.success),
            title: Text(l10n.problemsSolvedTitle),
            subtitle: const Text('Before & after proof with time-to-resolve'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.solvedGallery),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined,
                color: AppColors.primary),
            title: Text(l10n.certificate),
            subtitle: const Text('NSS hours & verified PDF'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.certificate),
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Partner NGO Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/ngo/org-ngo-1'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(l10n.moderationTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.moderation),
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: Text(l10n.rolePartner),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.partnerDashboard),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(l10n.roleAuthority),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.authorityView),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.settingsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.settings),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: Text(l10n.termsOfService),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.terms),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              l10n.signOut,
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(Routes.languageSelect);
            },
          ),
        ],
      ),
    );
  }
}
