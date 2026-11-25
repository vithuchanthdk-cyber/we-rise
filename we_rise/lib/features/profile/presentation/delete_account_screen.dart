import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/shared/widgets/we_rise_button.dart';
import '../../auth/presentation/providers.dart';
import '../../../core/router/app_router.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _loading = false;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccount)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.deleteAccount, style: AppTextStyles.titleLarge.copyWith(color: AppColors.error)),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.deleteAccountConfirm, style: AppTextStyles.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              title: const Text('I understand this cannot be undone', style: AppTextStyles.bodyMedium),
              contentPadding: EdgeInsets.zero,
            ),
            const Spacer(),
            WeRiseButton(
              label: l10n.deleteAccount,
              style: WeRiseButtonStyle.destructive,
              loading: _loading,
              onPressed: _confirmed ? _delete : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    setState(() => _loading = true);
    await ref.read(authRepositoryProvider).deleteAccount();
    if (mounted) context.go(Routes.languageSelect);
  }
}
