import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../complaints/data/providers.dart';
import '../../complaints/domain/models.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final taskRepo = ref.watch(taskRepositoryProvider);
    final orgRepo = ref.watch(orgRepositoryProvider);
    final compRepo = ref.watch(complaintRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.availableTasks)),
      body: FutureBuilder<(List<Task>, List<Organisation>, List<Complaint>)>(
        future: Future.wait([
          taskRepo.getVolunteerSafe(),
          orgRepo.getAll(),
          compRepo.getAll(),
        ]).then((r) => (
              r[0] as List<Task>,
              r[1] as List<Organisation>,
              r[2] as List<Complaint>,
            )),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (tasks, orgs, complaints) = snap.data!;
          final openTasks = tasks.where((t) => !t.isCompleted).toList();
          if (openTasks.isEmpty) {
            return const Center(child: Text('No volunteer tasks available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: openTasks.length,
            itemBuilder: (context, i) {
              final t = openTasks[i];
              final comp =
                  complaints.where((c) => c.id == t.complaintId).firstOrNull;
              final org =
                  orgs.where((o) => o.id == t.partnerOrgId).firstOrNull;

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.volunteer_activism,
                        color: Colors.white, size: 20),
                  ),
                  title: Text(
                    '${comp?.category.displayName ?? 'Task'} · ${comp?.wardId ?? ''}',
                  ),
                  subtitle: Text(
                    'Supervisor: ${org?.name ?? t.partnerOrgId} · '
                    '${t.volunteerIds.length} joined · ${t.estimatedHours}h',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/task/${t.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
