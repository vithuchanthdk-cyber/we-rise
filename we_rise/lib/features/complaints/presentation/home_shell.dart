import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/shared/widgets/offline_banner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/complaints/data/seed_data.dart';
import '../../../features/complaints/domain/enums.dart';
import '../../auth/presentation/providers.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final role = user?.role ?? UserRole.citizen;

    final tabs = [
      (l10n.mapTab, Icons.map),
      (l10n.reportTab, Icons.add_circle_outline),
      (l10n.myReportsTab, Icons.list_alt),
      (l10n.volunteerTab, Icons.volunteer_activism),
      (l10n.profileTab, Icons.person),
    ];

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          if (role == UserRole.moderator ||
              role == UserRole.partner ||
              role == UserRole.authority)
            _RoleWorkspaceBar(role: role),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
        destinations: tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.$2),
                label: t.$1,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RoleWorkspaceBar extends ConsumerWidget {
  const _RoleWorkspaceBar({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, route, icon) = switch (role) {
      UserRole.moderator => (
          'Moderator Queue',
          Routes.moderation,
          Icons.verified_user,
        ),
      UserRole.partner => (
          'Partner Dashboard',
          Routes.partnerDashboard,
          Icons.business,
        ),
      UserRole.authority => (
          'Authority View',
          Routes.authorityView,
          Icons.account_balance,
        ),
      _ => ('', '', Icons.person),
    };

    return Material(
      color: AppColors.primary.withAlpha(25),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demo Role: ${role.displayName}',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => showDemoRoleSwitcher(context, ref),
                child: const Text('Switch'),
              ),
              FilledButton(
                onPressed: () => context.push(route),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Easy-to-reach Demo Role Switcher dialog/sheet.
Future<void> showDemoRoleSwitcher(BuildContext context, WidgetRef ref) async {
  final currentRole = ref.read(currentUserProvider)?.role ?? UserRole.citizen;
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Switch Demo Role', style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Explore WE RISE as any role without signing out.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...UserRole.values.map((r) {
              final selected = r == currentRole;
              return ListTile(
                leading: Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppColors.primary : null,
                ),
                title: Text(r.displayName),
                onTap: () async {
                  await ref
                      .read(authRepositoryProvider)
                      .setDemoUser(SeedData.userForRole(r));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    ),
  );
}
