import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

/// Production Supabase implementation of [ComplaintRepository].
/// Activated when `--dart-define=SUPABASE_URL=...` and `SUPABASE_ANON_KEY=...` are passed.
class SupabaseComplaintRepository implements ComplaintRepository {
  SupabaseComplaintRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'complaints';

  @override
  Future<List<Complaint>> getAll() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Complaint>> getByStatus(ComplaintStatus status) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('status', _statusToDb(status))
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Complaint>> getByReporter(String reporterId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('reporter_id', reporterId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Complaint>> getByOrg(String orgId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('assigned_org_id', orgId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Complaint>> getNearby(LatLng center, double radiusMetres) async {
    // Bounding-box prefilter; exact Haversine applied client-side
    final degDelta = radiusMetres / 111000.0;
    final rows = await _client
        .from(_table)
        .select()
        .gte('lat', center.latitude - degDelta)
        .lte('lat', center.latitude + degDelta)
        .gte('lng', center.longitude - degDelta)
        .lte('lng', center.longitude + degDelta);
    return (rows as List<dynamic>)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Complaint?> getById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Complaint?> getByTrackingId(String trackingId) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('tracking_id', trackingId)
        .maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Complaint> create(Complaint complaint) async {
    final inserted = await _client
        .from(_table)
        .insert({
          'id': complaint.id,
          'tracking_id': complaint.trackingId,
          'category': _categoryToDb(complaint.category),
          'status': _statusToDb(complaint.status),
          'ward_id': complaint.wardId,
          'lat': complaint.location.latitude,
          'lng': complaint.location.longitude,
          'reporter_id': complaint.reporterId,
          'note': complaint.note,
          'priority_score': complaint.priorityScore,
          'escalated': complaint.escalated,
        })
        .select()
        .single();
    return _fromRow(inserted);
  }

  @override
  Future<Complaint> update(Complaint complaint) async {
    final updated = await _client
        .from(_table)
        .update({
          'status': _statusToDb(complaint.status),
          'priority_score': complaint.priorityScore,
          'escalated': complaint.escalated,
          'assigned_org_id': complaint.assignedOrgId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', complaint.id)
        .select()
        .single();
    return _fromRow(updated);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  @override
  Future<Complaint> addSupporter(String complaintId, String userId) async {
    await _client.from('supporters').upsert({
      'complaint_id': complaintId,
      'user_id': userId,
    });
    final updated = await getById(complaintId);
    return updated!;
  }

  @override
  Future<Complaint> addStatusEvent(String complaintId, StatusEvent event) async {
    await _client.from('status_history').insert({
      'complaint_id': complaintId,
      'status': _statusToDb(event.status),
      'actor_role': event.actorRole,
      'note': event.note,
    });
    await _client.from(_table).update({
      'status': _statusToDb(event.status),
      'updated_at': event.at.toIso8601String(),
    }).eq('id', complaintId);
    final updated = await getById(complaintId);
    return updated!;
  }

  @override
  Future<int> nextSequenceNumber() async {
    final res = await _client.rpc<String>('generate_tracking_id');
    final parts = res.split('-');
    return int.parse(parts.last);
  }

  @override
  Stream<List<Complaint>> watchAll() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(_fromRow).toList());
  }

  @override
  Stream<Complaint?> watchById(String id) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : _fromRow(rows.first));
  }

  static Complaint _fromRow(Map<String, dynamic> r) {
    final cat = _categoryFromDb(r['category'] as String);
    return Complaint(
      id: r['id'] as String,
      trackingId: r['tracking_id'] as String,
      category: cat,
      severity: cat.defaultSeverity,
      status: _statusFromDb(r['status'] as String),
      location: LatLng(
        (r['lat'] as num).toDouble(),
        (r['lng'] as num).toDouble(),
      ),
      wardId: r['ward_id'] as String,
      photos: const [],
      createdAt: DateTime.parse(r['created_at'] as String),
      lastStatusChangeAt: DateTime.parse(r['updated_at'] as String),
      reporterId: r['reporter_id'] as String,
      supporterIds: const [],
      riskClass: cat == ComplaintCategory.streetlight
          ? RiskClass.dangerous
          : (cat == ComplaintCategory.pothole ||
                  cat == ComplaintCategory.sewage ||
                  cat == ComplaintCategory.waterlogging)
              ? RiskClass.medium
              : RiskClass.low,
      priorityScore: (r['priority_score'] as num?)?.toDouble() ?? 50.0,
      escalated: (r['escalated'] as bool?) ?? false,
      reopenCount: 0,
      note: r['note'] as String?,
      assignedOrgId: r['assigned_org_id'] as String?,
    );
  }

  static String _statusToDb(ComplaintStatus s) => switch (s) {
        ComplaintStatus.PENDING_REVIEW => 'pending_review',
        ComplaintStatus.VERIFIED => 'verified',
        ComplaintStatus.ASSIGNED => 'assigned',
        ComplaintStatus.WORK_STARTED => 'work_started',
        ComplaintStatus.AWAITING_CONFIRMATION => 'awaiting_confirmation',
        ComplaintStatus.SOLVED => 'problem_solved',
        ComplaintStatus.REJECTED => 'rejected',
        ComplaintStatus.REOPENED => 'escalated',
      };

  static ComplaintStatus _statusFromDb(String s) => switch (s) {
        'pending_review' => ComplaintStatus.PENDING_REVIEW,
        'verified' => ComplaintStatus.VERIFIED,
        'assigned' => ComplaintStatus.ASSIGNED,
        'work_started' => ComplaintStatus.WORK_STARTED,
        'awaiting_confirmation' => ComplaintStatus.AWAITING_CONFIRMATION,
        'problem_solved' => ComplaintStatus.SOLVED,
        'rejected' => ComplaintStatus.REJECTED,
        'escalated' => ComplaintStatus.REOPENED,
        _ => ComplaintStatus.PENDING_REVIEW,
      };

  static String _categoryToDb(ComplaintCategory c) => switch (c) {
        ComplaintCategory.blockedDrain => 'blocked_drain',
        _ => c.name,
      };

  static ComplaintCategory _categoryFromDb(String c) => switch (c) {
        'blocked_drain' => ComplaintCategory.blockedDrain,
        _ => ComplaintCategory.values.byName(c),
      };
}
