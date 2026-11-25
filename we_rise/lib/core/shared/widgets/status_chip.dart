import 'package:flutter/material.dart';
import '../../../features/complaints/domain/enums.dart';
import '../../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.small = false});

  final ComplaintStatus status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(status);
    final size = small ? 11.0 : 12.0;
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: size,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }

  static (String, Color) _resolve(ComplaintStatus s) => switch (s) {
        ComplaintStatus.PENDING_REVIEW => ('Pending', AppColors.statusPending),
        ComplaintStatus.VERIFIED => ('Verified', AppColors.statusVerified),
        ComplaintStatus.ASSIGNED => ('Assigned', AppColors.statusAssigned),
        ComplaintStatus.WORK_STARTED =>
          ('In progress', AppColors.statusWorkStarted),
        ComplaintStatus.AWAITING_CONFIRMATION =>
          ('Awaiting confirm', AppColors.statusWorkStarted),
        ComplaintStatus.SOLVED => ('Solved ✓', AppColors.statusResolved),
        ComplaintStatus.REJECTED => ('Rejected', AppColors.statusRejected),
        ComplaintStatus.REOPENED => ('Reopened', AppColors.statusEscalated),
      };
}
