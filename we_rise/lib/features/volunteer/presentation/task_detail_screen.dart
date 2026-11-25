import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/shared/widgets/status_chip.dart';
import '../../../core/shared/widgets/we_rise_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers.dart';
import '../../complaints/data/providers.dart';
import '../../complaints/domain/duplicate_detector.dart';
import '../../complaints/domain/enums.dart';
import '../../complaints/domain/models.dart';
import '../../complaints/domain/photo_validator.dart';
import '../../complaints/domain/status_machine.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  static const _uuid = Uuid();
  bool _busy = false;
  String? _error;
  Task? _task;
  Complaint? _complaint;
  Organisation? _org;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final task = await ref.read(taskRepositoryProvider).getById(widget.taskId);
    if (task == null) return;
    final comp =
        await ref.read(complaintRepositoryProvider).getById(task.complaintId);
    final org = await ref.read(orgRepositoryProvider).getById(task.partnerOrgId);
    if (mounted) {
      setState(() {
        _task = task;
        _complaint = comp;
        _org = org;
      });
    }
  }

  Future<void> _join() async {
    final task = _task;
    if (task == null) return;
    final userId = ref.read(currentUserProvider)?.id ?? 'u-volunteer-1';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated =
          await ref.read(taskRepositoryProvider).addVolunteer(task.id, userId);
      setState(() => _task = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).taskJoined)),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadAfterPhoto() async {
    final l10n = AppLocalizations.of(context);
    final task = _task;
    final complaint = _complaint;
    if (task == null || complaint == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Live camera ONLY (never gallery)
      final picked = await ref.read(photoServiceProvider).pickFromCamera();
      if (picked == null) return;

      final photoCheck = PhotoValidator.validateAfterPhoto(source: picked.source);
      if (!photoCheck.isValid) {
        setState(() => _error = l10n.afterPhotoCameraOnly);
        return;
      }

      // 50 m GPS check
      final locRes =
          await ref.read(locationServiceProvider).getCurrentLocation();
      final dist = DuplicateDetector.haversineMetres(
        locRes.location.latitude,
        locRes.location.longitude,
        complaint.location.latitude,
        complaint.location.longitude,
      );
      if (dist > 50.0) {
        setState(() => _error = l10n.locationCheckFailed);
        return;
      }

      final afterPhoto = ComplaintPhoto(
        id: _uuid.v4(),
        url: picked.path,
        source: PhotoSource.camera,
        capturedAt: picked.capturedAt,
      );

      final compRepo = ref.read(complaintRepositoryProvider);
      var currentStatus = complaint.status;

      // Walk legal state transitions to AWAITING_CONFIRMATION
      if (currentStatus == ComplaintStatus.VERIFIED) {
        currentStatus =
            StatusMachine.transition(currentStatus, ComplaintStatus.ASSIGNED);
      }
      if (currentStatus == ComplaintStatus.ASSIGNED) {
        currentStatus = StatusMachine.transition(
          currentStatus,
          ComplaintStatus.WORK_STARTED,
        );
      }
      if (currentStatus == ComplaintStatus.WORK_STARTED) {
        currentStatus = StatusMachine.transition(
          currentStatus,
          ComplaintStatus.AWAITING_CONFIRMATION,
        );
      }

      final updatedComp = complaint.copyWith(
        status: currentStatus,
        afterPhotos: [...complaint.afterPhotos, afterPhoto],
        lastStatusChangeAt: DateTime.now(),
        timeline: [
          ...complaint.timeline,
          StatusEvent(
            complaintId: complaint.id,
            status: currentStatus,
            at: DateTime.now(),
            actorRole: 'volunteer',
            note: 'After-photo uploaded within 50 m.',
          ),
        ],
      );
      await compRepo.update(updatedComp);

      final completedTask = task.copyWith(completedAt: DateTime.now());
      await ref.read(taskRepositoryProvider).update(completedTask);

      final userId = ref.read(currentUserProvider)?.id ?? 'u-volunteer-1';
      await ref
          .read(userRepositoryProvider)
          .addHours(userId, task.estimatedHours);

      if (mounted) {
        setState(() {
          _task = completedTask;
          _complaint = updatedComp;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'After-photo uploaded! +${task.estimatedHours} ${l10n.earnedHours}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final task = _task;
    final comp = _complaint;
    final userId = ref.watch(currentUserProvider)?.id ?? 'u-volunteer-1';

    if (task == null || comp == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.availableTasks)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final joined = task.volunteerIds.contains(userId);

    return Scaffold(
      appBar: AppBar(title: Text(comp.trackingId)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(comp.category.displayName, style: AppTextStyles.titleLarge),
              StatusChip(status: comp.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          WeRiseCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ward: ${comp.wardId}', style: AppTextStyles.bodyMedium),
                Text(
                  'Supervising Partner: ${_org?.name ?? task.partnerOrgId}',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  'Estimated hours: ${task.estimatedHours} h',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tools needed: ${task.requirements.join(', ')}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Volunteers joined: ${task.volunteerIds.length}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(25),
                border: Border.all(color: AppColors.error),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          if (!joined)
            FilledButton.icon(
              key: const Key('join_task_btn'),
              onPressed: _busy ? null : _join,
              icon: const Icon(Icons.group_add),
              label: Text(l10n.joinTask),
            )
          else if (!task.isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.afterPhotoCameraOnly,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              key: const Key('after_photo_camera_btn'),
              onPressed: _busy ? null : _uploadAfterPhoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(l10n.uploadAfterPhoto),
            ),
          ] else
            const Chip(
              label: Text('Task completed — awaiting resident confirmation'),
            ),
        ],
      ),
    );
  }
}
