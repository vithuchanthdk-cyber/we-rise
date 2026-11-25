import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).termsOfService)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          Text('Terms of Service', style: AppTextStyles.displayMedium),
          SizedBox(height: AppSpacing.md),
          Text(_kTermsText, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  static const _kTermsText = '''
By using WE RISE you agree to these terms.

USE
• WE RISE is for reporting genuine civic issues in Chennai
• False reports or abuse will result in account suspension
• You may not use the app for personal disputes

CONTENT
• Photos and descriptions must relate to real civic issues
• You retain ownership of your content
• You grant WE RISE a licence to display your content on the public map

VOLUNTEER SAFETY
• Volunteers must NOT work on electrical or dangerous issues
• Always follow partner organisation instructions
• WE RISE is not liable for volunteer injuries

LIMITATION OF LIABILITY
WE RISE is a community tool. We are not responsible for the actions of third parties (authorities, volunteers, organisations).

CHANGES
We may update these terms. Continued use constitutes acceptance.

Last updated: November 2026
''';
}
