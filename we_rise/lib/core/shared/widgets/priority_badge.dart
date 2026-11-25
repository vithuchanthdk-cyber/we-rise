import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.score});

  final double score; // 0-100

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? AppColors.priorityHigh
        : score >= 40
            ? AppColors.priorityMedium
            : AppColors.priorityLow;
    final label = score >= 70 ? 'HIGH' : score >= 40 ? 'MED' : 'LOW';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: const BorderRadius.all(AppRadius.sm),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$label ${score.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
