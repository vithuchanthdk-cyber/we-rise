import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/shared/widgets/priority_badge.dart';
import '../../../core/shared/widgets/status_chip.dart';
import '../../../core/theme/app_theme.dart';
import '../../complaints/data/providers.dart';
import '../../complaints/domain/enums.dart';
import '../../complaints/domain/models.dart';
import '../../complaints/domain/status_machine.dart';

class AuthorityScreen extends ConsumerStatefulWidget {
  const AuthorityScreen({super.key});

  @override
  ConsumerState<AuthorityScreen> createState() => _AuthorityScreenState();
}

class _AuthorityScreenState extends ConsumerState<AuthorityScreen> {
  bool _showHeatmap = false;

  Future<void> _startWork(Complaint c) async {
    final repo = ref.read(complaintRepositoryProvider);
    final next = StatusMachine.transition(c.status, ComplaintStatus.WORK_STARTED);
    await repo.addStatusEvent(
      c.id,
      StatusEvent(
        complaintId: c.id,
        status: next,
        at: DateTime.now(),
        actorRole: 'authority',
        note: 'Field crew dispatched.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final complaintsAsync = ref.watch(allComplaintsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.roleAuthority),
        actions: [
          IconButton(
            tooltip: 'Pattern Heatmap',
            icon: Icon(
              _showHeatmap ? Icons.list_alt : Icons.map_outlined,
            ),
            onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
          ),
        ],
      ),
      body: complaintsAsync.when(
        data: (all) {
          final infra = all
              .where((c) =>
                  c.status != ComplaintStatus.PENDING_REVIEW &&
                  c.status != ComplaintStatus.REJECTED &&
                  (c.riskClass == RiskClass.dangerous ||
                      c.category == ComplaintCategory.pothole ||
                      c.category == ComplaintCategory.sewage ||
                      c.category == ComplaintCategory.waterlogging))
              .toList()
            ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

          if (_showHeatmap) {
            return FlutterMap(
              options: const MapOptions(
                initialCenter: ll.LatLng(13.0674, 80.2376),
                initialZoom: 11.5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.werise.chennai',
                ),
                CircleLayer(
                  circles: infra.map((c) {
                    final color = c.riskClass == RiskClass.dangerous
                        ? AppColors.error
                        : AppColors.warning;
                    return CircleMarker(
                      point:
                          ll.LatLng(c.location.latitude, c.location.longitude),
                      radius: 28,
                      color: color.withAlpha(85),
                      borderColor: color,
                      borderStrokeWidth: 1.5,
                    );
                  }).toList(),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: infra.length,
            itemBuilder: (context, i) {
              final c = infra[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.riskClass == RiskClass.dangerous
                        ? AppColors.error
                        : AppColors.primary,
                    child: Icon(
                      c.riskClass == RiskClass.dangerous
                          ? Icons.electric_bolt
                          : Icons.engineering,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  title: Text('${c.category.displayName} · ${c.wardId}'),
                  subtitle: Row(
                    children: [
                      Text(c.trackingId, style: AppTextStyles.caption),
                      const SizedBox(width: 8),
                      PriorityBadge(score: c.priorityScore),
                    ],
                  ),
                  trailing: c.status == ComplaintStatus.ASSIGNED
                      ? FilledButton(
                          onPressed: () => _startWork(c),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 34),
                          ),
                          child: const Text('Start'),
                        )
                      : StatusChip(status: c.status, small: true),
                  onTap: () => context.push('/complaint/${c.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
