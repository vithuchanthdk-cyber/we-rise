import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class PermissionRationaleScreen extends StatelessWidget {
  const PermissionRationaleScreen({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, body, icon) = _resolve(type, l10n);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppSpacing.xl),
              Text(title,
                  style: AppTextStyles.displayMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              Text(body,
                  style: AppTextStyles.bodyLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: () async {
                  await openAppSettings();
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.settings),
                label: Text(l10n.permOpenSettings),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.permDeny),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (String, String, IconData) _resolve(String type, AppLocalizations l) =>
      switch (type) {
        'location' => (l.permLocationTitle, l.permLocationBody, Icons.location_on),
        'camera' => (l.permCameraTitle, l.permCameraBody, Icons.camera_alt),
        'microphone' => (l.permMicTitle, l.permMicBody, Icons.mic),
        'notification' => (l.permNotifTitle, l.permNotifBody, Icons.notifications),
        _ => ('Permission required', 'This feature needs a permission.', Icons.lock),
      };
}
