import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../features/complaints/domain/enums.dart';
import '../../../features/auth/presentation/providers.dart';
import '../../../features/complaints/data/seed_data.dart';

class RolePickerScreen extends ConsumerStatefulWidget {
  const RolePickerScreen({super.key});

  @override
  ConsumerState<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends ConsumerState<RolePickerScreen> {
  UserRole? _selected;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectRole),
        leading: BackButton(onPressed: () => context.go(Routes.languageSelect)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Demo mode banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withAlpha(40),
              borderRadius: const BorderRadius.all(AppRadius.md),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.demoMode,
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.primary)),
                      Text(l10n.demoModeDesc,
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.selectRole, style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          ...UserRole.values.map((role) => _RoleTile(
                role: role,
                selected: _selected == role,
                onTap: () => setState(() => _selected = role),
                l10n: l10n,
              )),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _selected == null || _loading ? null : _proceed,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.continueLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _proceed() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    // In demo mode: set a seeded user matching the role
    final user = SeedData.userForRole(_selected!);
    await ref.read(authRepositoryProvider).setDemoUser(user);
    if (mounted) context.go(Routes.home);
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.selected,
    required this.onTap,
    required this.l10n,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            borderRadius: const BorderRadius.all(AppRadius.md),
            color: selected ? colorScheme.primary.withAlpha(15) : null,
          ),
          child: Row(
            children: [
              Icon(_icon(role),
                  color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label(l10n), style: AppTextStyles.titleSmall),
                    Text(_desc(l10n),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(UserRole r) => switch (r) {
        UserRole.citizen => Icons.person,
        UserRole.volunteer => Icons.volunteer_activism,
        UserRole.moderator => Icons.verified_user,
        UserRole.partner => Icons.business,
        UserRole.authority => Icons.account_balance,
      };

  String _label(AppLocalizations l) => switch (role) {
        UserRole.citizen => l.roleCitizen,
        UserRole.volunteer => l.roleVolunteer,
        UserRole.moderator => l.roleModerator,
        UserRole.partner => l.rolePartner,
        UserRole.authority => l.roleAuthority,
      };

  String _desc(AppLocalizations l) => switch (role) {
        UserRole.citizen => l.roleCitizenDesc,
        UserRole.volunteer => l.roleVolunteerDesc,
        UserRole.moderator => l.roleModeratorDesc,
        UserRole.partner => l.rolePartnerDesc,
        UserRole.authority => l.roleAuthorityDesc,
      };
}
