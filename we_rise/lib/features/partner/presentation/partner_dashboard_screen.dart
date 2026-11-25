import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/shared/widgets/we_rise_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers.dart';
import '../../complaints/data/providers.dart';
import '../../complaints/domain/models.dart';

class PartnerDashboardScreen extends ConsumerStatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  ConsumerState<PartnerDashboardScreen> createState() =>
      _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState
    extends ConsumerState<PartnerDashboardScreen> {
  bool _exporting = false;

  Future<void> _exportMonthlyPdf(
    Organisation org,
    List<Task> tasks,
  ) async {
    setState(() => _exporting = true);
    try {
      final doc = pw.Document();
      final totalHours =
          tasks.fold<double>(0, (sum, t) => sum + t.estimatedHours);
      final completed = tasks.where((t) => t.isCompleted).length;

      doc.addPage(
        pw.Page(
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'WE RISE — Monthly Partner Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Organisation: ${org.name} (${org.type.name.toUpperCase()})'),
              pw.Text('Wards: ${org.wardIds.join(', ')}'),
              pw.Text('Generated: ${DateTime.now().toIso8601String().split('T').first}'),
              pw.Divider(),
              pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Total supervised tasks: ${tasks.length}'),
              pw.Text('Completed tasks: $completed'),
              pw.Text('Total volunteer hours: ${totalHours.toStringAsFixed(1)} h'),
              pw.Text('Avg resolution days: ${org.avgResolutionDays} d'),
              pw.SizedBox(height: 16),
              pw.Text('Task Breakdown', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...tasks.map(
                (t) => pw.Bullet(
                  text:
                      'Task ${t.id} · Complaint ${t.complaintId} · '
                      '${t.volunteerIds.length} volunteer(s) · '
                      '${t.isCompleted ? 'Completed' : 'Active'}',
                ),
              ),
            ],
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}${Platform.pathSeparator}werise_partner_report.pdf',
      );
      await file.writeAsBytes(await doc.save());

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: '${org.name} Monthly Report',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _assignVolunteer(Task task) async {
    await ref
        .read(taskRepositoryProvider)
        .addVolunteer(task.id, 'u-volunteer-1');
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Volunteer#7193 assigned to task.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orgId = ref.watch(currentUserProvider)?.orgId ?? 'org-ngo-1';
    final orgRepo = ref.watch(orgRepositoryProvider);
    final taskRepo = ref.watch(taskRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rolePartner)),
      body: FutureBuilder<(Organisation?, List<Task>)>(
        future: Future.wait([
          orgRepo.getById(orgId),
          taskRepo.getAll(),
        ]).then((r) => (r[0] as Organisation?, r[1] as List<Task>)),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final org = snap.data!.$1;
          final tasks = snap.data!.$2;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (org != null)
                WeRiseCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(org.name, style: AppTextStyles.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        '${org.resolvedCount} resolved · '
                        '${org.activeVolunteerCount} volunteers · '
                        'Avg ${org.avgResolutionDays} days',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const Key('export_pdf_btn'),
                        onPressed: _exporting
                            ? null
                            : () => _exportMonthlyPdf(org, tasks),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export Monthly Report (PDF)'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Supervised Tasks (${tasks.length})',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...tasks.map(
                (t) => Card(
                  child: ListTile(
                    title: Text('Task ${t.id} · Complaint ${t.complaintId}'),
                    subtitle: Text(
                      '${t.volunteerIds.length} volunteer(s) · '
                      '${t.isCompleted ? 'Completed' : 'Open'}',
                    ),
                    trailing: t.volunteerIds.contains('u-volunteer-1')
                        ? const Chip(label: Text('Assigned'))
                        : TextButton(
                            onPressed: () => _assignVolunteer(t),
                            child: const Text('Assign'),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
