import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

/// Hive-backed persistent offline queue for draft reports.
/// Survives app restarts on low-end Android devices.
class HiveOfflineQueueRepository implements OfflineQueueRepository {
  static const String boxName = 'we_rise_offline_queue';

  final _controller = StreamController<int>.broadcast();

  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<String>(boxName);
    }
    return Hive.openBox<String>(boxName);
  }

  @override
  Future<List<DraftReport>> getPendingDrafts() async {
    final box = await _openBox();
    return box.values
        .map((raw) => _fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> enqueueDraft(DraftReport draft) async {
    final box = await _openBox();
    await box.put(draft.id, jsonEncode(_toJson(draft)));
    _controller.add(box.length);
  }

  @override
  Future<void> removeDraft(String id) async {
    final box = await _openBox();
    await box.delete(id);
    _controller.add(box.length);
  }

  @override
  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
    _controller.add(0);
  }

  @override
  Stream<int> watchQueueSize() => _controller.stream;

  Map<String, dynamic> _toJson(DraftReport d) => {
        'id': d.id,
        'category': d.category.name,
        'severity': d.severity,
        'location': {'lat': d.location.latitude, 'lng': d.location.longitude},
        'wardId': d.wardId,
        'photoPaths': d.photoPaths,
        'photoSources': d.photoSources.map((s) => s.name).toList(),
        'createdAt': d.createdAt.toIso8601String(),
        'reporterId': d.reporterId,
        'note': d.note,
        'onBehalfOf': d.onBehalfOf,
        'voiceNotePath': d.voiceNotePath,
      };

  DraftReport _fromJson(Map<String, dynamic> m) {
    final loc = m['location'] as Map<String, dynamic>;
    return DraftReport(
      id: m['id'] as String,
      category: ComplaintCategory.values.byName(m['category'] as String),
      severity: (m['severity'] as num).toInt(),
      location: LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      ),
      wardId: m['wardId'] as String,
      photoPaths: (m['photoPaths'] as List<dynamic>).cast<String>(),
      photoSources: (m['photoSources'] as List<dynamic>)
          .map((s) => PhotoSource.values.byName(s as String))
          .toList(),
      createdAt: DateTime.parse(m['createdAt'] as String),
      reporterId: m['reporterId'] as String,
      note: m['note'] as String?,
      onBehalfOf: m['onBehalfOf'] as String?,
      voiceNotePath: m['voiceNotePath'] as String?,
    );
  }
}
