import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/shared/widgets/we_rise_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers.dart';
import '../../complaints/data/providers.dart';
import '../../complaints/data/seed_data.dart';
import '../../complaints/domain/models.dart';
import '../domain/certificate_service.dart';

class CertificateScreen extends ConsumerStatefulWidget {
  const CertificateScreen({super.key});

  @override
  ConsumerState<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends ConsumerState<CertificateScreen> {
  bool _busy = false;
  Certificate? _latestCert;

  Future<void> _download(AppUser user, Organisation org, double hours) async {
    setState(() => _busy = true);
    try {
      final cert = CertificateService.buildCertificate(
        user: user,
        org: org,
        hours: hours,
      );
      await ref.read(certificateRepositoryProvider).create(cert);
      final file = await CertificateService.generatePdf(
        certificate: cert,
        org: org,
      );
      if (mounted) {
        setState(() => _latestCert = cert);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'WE RISE Volunteer Certificate (${cert.verificationCode})',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider) ?? SeedData.users[1];
    final taskRepo = ref.watch(taskRepositoryProvider);
    final org = SeedData.organisations.first;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.certificate)),
      body: FutureBuilder<List<Task>>(
        future: taskRepo.getAll(),
        builder: (context, snap) {
          final taskHours = snap.hasData
              ? CertificateService.calculateTotalHours(snap.data!, user.id)
              : 0.0;
          final totalHours = user.volunteerHours + taskHours;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              WeRiseCard(
                margin: EdgeInsets.zero,
                highlighted: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.anonymousHandle,
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalHours.toStringAsFixed(1)} ${l10n.earnedHours}',
                      style: AppTextStyles.displayMedium
                          .copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supervising partner: ${org.name}',
                      style: AppTextStyles.bodySmall,
                    ),
                    if (_latestCert != null) ...[
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          'Code: ${_latestCert!.verificationCode}',
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      key: const Key('download_cert_btn'),
                      onPressed: _busy
                          ? null
                          : () => _download(user, org, totalHours),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(l10n.downloadCertificate),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Secondary Badges', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (user.badges.isEmpty)
                const Text('Complete tasks to earn community badges.')
              else
                Wrap(
                  spacing: 8,
                  children: user.badges
                      .map(
                        (b) => Chip(
                          avatar: const Icon(Icons.workspace_premium, size: 18),
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
