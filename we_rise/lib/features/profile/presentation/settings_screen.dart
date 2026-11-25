import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers.dart';
import '../../complaints/presentation/home_shell.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.language),
            subtitle: Text(
              locale.languageCode == 'ta'
                  ? l10n.languageTamil
                  : l10n.languageEnglish,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.languageSelect),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch Demo Role'),
            subtitle: Text('Current: ${user?.role.displayName ?? 'Citizen'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDemoRoleSwitcher(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(
              l10n.deleteAccount,
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () => context.push(Routes.deleteAccount),
          ),
        ],
      ),
    );
  }
}
