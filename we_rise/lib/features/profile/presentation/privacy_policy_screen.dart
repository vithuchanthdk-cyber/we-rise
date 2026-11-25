import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).privacyPolicy)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          Text('Privacy Policy', style: AppTextStyles.displayMedium),
          SizedBox(height: AppSpacing.md),
          Text(_kPrivacyText, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  static const _kPrivacyText = '''
WE RISE ("we", "our", "app") is built by community volunteers. This policy explains what data we collect and how we use it.

DATA WE COLLECT
• Photos you upload (stored in Supabase Storage; never shared with third parties)
• Location captured at report time (not from EXIF; from device GPS only)
• Voice input transcribed locally (not sent to any server)
• Email address for sign-in (Supabase Auth)

DATA WE DO NOT COLLECT
• Your name
• Phone number
• Any identifying information beyond an anonymous handle

PUBLIC DATA
• Issue location, category, and status are public
• Your name and contact details are NEVER shown publicly

RETENTION
• Your data is deleted when you delete your account
• Anonymised complaint data may be retained for civic analysis

CONTACT
To request deletion or for any privacy concern, use the in-app "Delete my account and data" option.

Last updated: November 2026
''';
}
