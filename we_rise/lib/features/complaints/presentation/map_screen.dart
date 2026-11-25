import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/shared/widgets/priority_badge.dart';
import '../../../core/shared/widgets/status_chip.dart';
import '../../../core/theme/app_theme.dart';
import '../data/providers.dart';
import '../data/seed_data.dart';
import '../domain/enums.dart';
import '../domain/models.dart';

class MapFilter {
  const MapFilter({
    this.category,
    this.status,
    this.wardId,
    this.showHeatmap = false,
  });

  final ComplaintCategory? category;
  final ComplaintStatus? status;
  final String? wardId;
  final bool showHeatmap;

  bool get hasActiveFilters =>
      category != null || status != null || wardId != null;

  MapFilter copyWith({
    ComplaintCategory? Function()? category,
    ComplaintStatus? Function()? status,
    String? Function()? wardId,
    bool? showHeatmap,
  }) =>
      MapFilter(
        category: category != null ? category() : this.category,
        status: status != null ? status() : this.status,
        wardId: wardId != null ? wardId() : this.wardId,
        showHeatmap: showHeatmap ?? this.showHeatmap,
      );
}

final mapFilterProvider = StateProvider<MapFilter>((ref) => const MapFilter());

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 11.5;

  static const _chennaiCenter = ll.LatLng(13.0674, 80.2376);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(mapFilterProvider);
    final publicAsync = ref.watch(publicComplaintsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: 'Heatmap',
            icon: Icon(
              filter.showHeatmap ? Icons.layers : Icons.layers_outlined,
              color: filter.showHeatmap ? AppColors.error : null,
            ),
            onPressed: () {
              ref.read(mapFilterProvider.notifier).state =
                  filter.copyWith(showHeatmap: !filter.showHeatmap);
            },
          ),
          IconButton(
            tooltip: 'Filter',
            icon: Badge(
              isLabelVisible: filter.hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _openFilterSheet(context, filter),
          ),
        ],
      ),
      body: publicAsync.when(
        data: (allPublic) {
          final filtered = _applyFilter(allPublic, filter)
            ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
          return _buildMapAndSheet(context, filtered, filter);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/report'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(l10n.reportTab),
      ),
    );
  }

  List<PublicComplaintDto> _applyFilter(
    List<PublicComplaintDto> list,
    MapFilter f,
  ) {
    return list.where((c) {
      if (f.category != null && c.category != f.category) return false;
      if (f.status != null && c.status != f.status) return false;
      if (f.wardId != null && c.wardId != f.wardId) return false;
      return true;
    }).toList();
  }

  Widget _buildMapAndSheet(
    BuildContext context,
    List<PublicComplaintDto> complaints,
    MapFilter filter,
  ) {
    final clusters = _clusterComplaints(complaints, _currentZoom);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _chennaiCenter,
            initialZoom: _currentZoom,
            minZoom: 10,
            maxZoom: 18,
            onPositionChanged: (pos, _) {
              if ((pos.zoom - _currentZoom).abs() >= 0.5) {
                setState(() => _currentZoom = pos.zoom);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.werise.chennai',
            ),
            if (filter.showHeatmap)
              CircleLayer(
                circles: complaints.map((c) {
                  final color = c.priorityScore >= 70
                      ? AppColors.priorityHigh
                      : c.priorityScore >= 40
                          ? AppColors.priorityMedium
                          : AppColors.priorityLow;
                  return CircleMarker(
                    point: ll.LatLng(c.location.latitude, c.location.longitude),
                    radius: 24 + (c.priorityScore / 100) * 18,
                    color: color.withAlpha(75),
                    borderColor: color.withAlpha(140),
                    borderStrokeWidth: 1,
                  );
                }).toList(),
              ),
            MarkerLayer(
              markers: clusters.map((cluster) {
                if (cluster.items.length == 1) {
                  final c = cluster.items.first;
                  return Marker(
                    point: ll.LatLng(c.location.latitude, c.location.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => context.push('/complaint/${c.id}'),
                      child: _PinMarker(complaint: c),
                    ),
                  );
                }
                return Marker(
                  point: cluster.center,
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _mapController.move(
                      cluster.center,
                      (_currentZoom + 2).clamp(10, 18),
                    ),
                    child: _ClusterMarker(
                      count: cluster.items.length,
                      hasEscalated: cluster.items.any((c) => c.escalated),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        if (filter.hasActiveFilters)
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (filter.category != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(filter.category!.displayName),
                        onDeleted: () => ref
                            .read(mapFilterProvider.notifier)
                            .state = filter.copyWith(category: () => null),
                      ),
                    ),
                  if (filter.status != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(filter.status!.displayName),
                        onDeleted: () => ref
                            .read(mapFilterProvider.notifier)
                            .state = filter.copyWith(status: () => null),
                      ),
                    ),
                  if (filter.wardId != null)
                    Chip(
                      label: Text(_wardName(filter.wardId!)),
                      onDeleted: () => ref
                          .read(mapFilterProvider.notifier)
                          .state = filter.copyWith(wardId: () => null),
                    ),
                ],
              ),
            ),
          ),
        DraggableScrollableSheet(
          initialChildSize: 0.28,
          minChildSize: 0.12,
          maxChildSize: 0.72,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ListView.builder(
              controller: scrollController,
              itemCount: complaints.isEmpty ? 2 : complaints.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${complaints.length} public issues',
                              style: AppTextStyles.titleMedium,
                            ),
                            Text(
                              'Sorted by priority',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                if (complaints.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: Text('No issues match your filters.')),
                  );
                }
                final c = complaints[index - 1];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.escalated
                        ? AppColors.statusEscalated
                        : AppColors.primary.withAlpha(25),
                    child: Icon(
                      _categoryIcon(c.category),
                      color: c.escalated ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${c.category.displayName} · ${_wardName(c.wardId)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (c.escalated)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.statusEscalated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ESCALATED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text(c.trackingId, style: AppTextStyles.caption),
                      const SizedBox(width: 8),
                      PriorityBadge(score: c.priorityScore),
                    ],
                  ),
                  trailing: StatusChip(status: c.status, small: true),
                  onTap: () => context.push('/complaint/${c.id}'),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _openFilterSheet(BuildContext context, MapFilter current) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (ctx, sheetRef, _) {
          final f = sheetRef.watch(mapFilterProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filter issues', style: AppTextStyles.titleLarge),
                        TextButton(
                          onPressed: () {
                            sheetRef.read(mapFilterProvider.notifier).state =
                                MapFilter(showHeatmap: f.showHeatmap);
                          },
                          child: const Text('Clear all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('Category', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 6,
                      children: ComplaintCategory.values.map((cat) {
                        final selected = f.category == cat;
                        return FilterChip(
                          label: Text(cat.displayName),
                          selected: selected,
                          onSelected: (v) {
                            sheetRef.read(mapFilterProvider.notifier).state =
                                f.copyWith(category: () => v ? cat : null);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Status', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 6,
                      children: ComplaintStatus.values
                          .where((s) => s.isPublic && s != ComplaintStatus.REJECTED)
                          .map((st) {
                        final selected = f.status == st;
                        return FilterChip(
                          label: Text(st.displayName),
                          selected: selected,
                          onSelected: (v) {
                            sheetRef.read(mapFilterProvider.notifier).state =
                                f.copyWith(status: () => v ? st : null);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Ward', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 6,
                      children: SeedData.wards.map((w) {
                        final selected = f.wardId == w.id;
                        return FilterChip(
                          label: Text(w.name),
                          selected: selected,
                          onSelected: (v) {
                            sheetRef.read(mapFilterProvider.notifier).state =
                                f.copyWith(wardId: () => v ? w.id : null);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _wardName(String wardId) {
    for (final w in SeedData.wards) {
      if (w.id == wardId) return w.name;
    }
    return wardId;
  }

  static IconData _categoryIcon(ComplaintCategory cat) => switch (cat) {
        ComplaintCategory.pothole => Icons.warning_amber,
        ComplaintCategory.garbage => Icons.delete_outline,
        ComplaintCategory.sewage => Icons.water_damage,
        ComplaintCategory.waterlogging => Icons.flood,
        ComplaintCategory.blockedDrain => Icons.plumbing,
        ComplaintCategory.streetlight => Icons.electric_bolt,
        ComplaintCategory.other => Icons.report_problem,
      };

  static List<_MarkerCluster> _clusterComplaints(
    List<PublicComplaintDto> items,
    double zoom,
  ) {
    if (zoom >= 14.0) {
      return items
          .map(
            (c) => _MarkerCluster(
              center: ll.LatLng(c.location.latitude, c.location.longitude),
              items: [c],
            ),
          )
          .toList();
    }
    final gridSize = zoom < 11.5 ? 0.035 : 0.015;
    final buckets = <String, List<PublicComplaintDto>>{};
    for (final c in items) {
      final gx = (c.location.latitude / gridSize).floor();
      final gy = (c.location.longitude / gridSize).floor();
      buckets.putIfAbsent('$gx:$gy', () => []).add(c);
    }
    return buckets.values.map((group) {
      final avgLat =
          group.map((c) => c.location.latitude).reduce((a, b) => a + b) /
              group.length;
      final avgLng =
          group.map((c) => c.location.longitude).reduce((a, b) => a + b) /
              group.length;
      return _MarkerCluster(center: ll.LatLng(avgLat, avgLng), items: group);
    }).toList();
  }
}

class _MarkerCluster {
  const _MarkerCluster({required this.center, required this.items});
  final ll.LatLng center;
  final List<PublicComplaintDto> items;
}

class _ClusterMarker extends StatelessWidget {
  const _ClusterMarker({required this.count, required this.hasEscalated});
  final int count;
  final bool hasEscalated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: hasEscalated ? AppColors.statusEscalated : AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker({required this.complaint});
  final PublicComplaintDto complaint;

  @override
  Widget build(BuildContext context) {
    final bg = complaint.escalated
        ? AppColors.statusEscalated
        : complaint.status == ComplaintStatus.SOLVED
            ? AppColors.statusResolved
            : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(
        _MapScreenState._categoryIcon(complaint.category),
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
