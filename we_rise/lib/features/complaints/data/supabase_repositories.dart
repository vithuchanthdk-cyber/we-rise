import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import '../domain/routing_engine.dart';

class SupabaseUserRepository implements UserRepository {
  SupabaseUserRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<AppUser?> getById(String id) async {
    final row =
        await _client.from('app_users').select().eq('id', id).maybeSingle();
    return row == null ? null : SupabaseAuthRepository.userFromRow(row);
  }

  @override
  Future<AppUser?> getByHandle(String anonymousHandle) async {
    final row = await _client
        .from('app_users')
        .select()
        .eq('anonymous_handle', anonymousHandle)
        .maybeSingle();
    return row == null ? null : SupabaseAuthRepository.userFromRow(row);
  }

  @override
  Future<List<AppUser>> getAll() async {
    final rows = await _client.from('app_users').select();
    return (rows as List<dynamic>)
        .map((r) => SupabaseAuthRepository.userFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AppUser> create(AppUser user) async {
    final row = await _client
        .from('app_users')
        .insert({
          'id': user.id,
          'anonymous_handle': user.anonymousHandle,
          'role': user.role.name,
          'ward_id': user.wardId,
          'organisation_id': user.orgId,
          'volunteer_hours': user.volunteerHours,
        })
        .select()
        .single();
    return SupabaseAuthRepository.userFromRow(row);
  }

  @override
  Future<AppUser> update(AppUser user) async {
    final row = await _client
        .from('app_users')
        .update({
          'role': user.role.name,
          'ward_id': user.wardId,
          'organisation_id': user.orgId,
          'volunteer_hours': user.volunteerHours,
        })
        .eq('id', user.id)
        .select()
        .single();
    return SupabaseAuthRepository.userFromRow(row);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('app_users').delete().eq('id', id);
  }

  @override
  Future<void> addHours(String userId, double hours) async {
    final user = await getById(userId);
    if (user != null) {
      await _client
          .from('app_users')
          .update({'volunteer_hours': user.volunteerHours + hours})
          .eq('id', userId);
    }
  }

  @override
  Stream<AppUser?> watchById(String id) {
    return _client
        .from('app_users')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty
            ? null
            : SupabaseAuthRepository.userFromRow(rows.first));
  }
}

class SupabaseOrgRepository implements OrgRepository {
  SupabaseOrgRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Organisation>> getAll() async {
    final rows = await _client.from('organisations').select();
    return (rows as List<dynamic>)
        .map((r) => orgFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Organisation?> getById(String id) async {
    final row = await _client
        .from('organisations')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : orgFromRow(row);
  }

  @override
  Future<List<Organisation>> getByType(OrgType type) async {
    final rows = await _client
        .from('organisations')
        .select()
        .eq('type', type.name);
    return (rows as List<dynamic>)
        .map((r) => orgFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Organisation> update(Organisation org) async {
    final row = await _client
        .from('organisations')
        .update({
          'name': org.name,
          'ward_ids': org.wardIds,
        })
        .eq('id', org.id)
        .select()
        .single();
    return orgFromRow(row);
  }

  @override
  Stream<Organisation?> watchById(String id) {
    return _client
        .from('organisations')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : orgFromRow(rows.first));
  }

  static Organisation orgFromRow(Map<String, dynamic> r) => Organisation(
        id: r['id'] as String,
        type: OrgType.values.byName(r['type'] as String),
        name: r['name'] as String,
        wardIds: (r['ward_ids'] as List<dynamic>? ?? const []).cast<String>(),
      );
}

class SupabaseTaskRepository implements TaskRepository {
  SupabaseTaskRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Task>> getAll() async {
    final rows = await _client.from('tasks').select();
    return (rows as List<dynamic>)
        .map((r) => taskFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Task>> getByOrg(String orgId) async {
    final rows =
        await _client.from('tasks').select().eq('supervising_org_id', orgId);
    return (rows as List<dynamic>)
        .map((r) => taskFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Task>> getForComplaint(String complaintId) async {
    final rows =
        await _client.from('tasks').select().eq('complaint_id', complaintId);
    return (rows as List<dynamic>)
        .map((r) => taskFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Task>> getVolunteerSafe() async {
    final rows =
        await _client.from('tasks').select().eq('volunteer_safe', true);
    return (rows as List<dynamic>)
        .map((r) => taskFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Task?> getById(String id) async {
    final row = await _client.from('tasks').select().eq('id', id).maybeSingle();
    return row == null ? null : taskFromRow(row);
  }

  @override
  Future<Task> create(Task task) async {
    final comp = await _client
        .from('complaints')
        .select('category')
        .eq('id', task.complaintId)
        .maybeSingle();
    if (comp != null && comp['category'] == 'streetlight') {
      RoutingEngine.assertVolunteerNeverAssignedToDangerous(
        RiskClass.dangerous,
        true,
      );
    }
    final row = await _client
        .from('tasks')
        .insert({
          'id': task.id,
          'complaint_id': task.complaintId,
          'supervising_org_id': task.partnerOrgId,
          'volunteer_safe': true,
          'volunteer_ids': task.volunteerIds,
          'required_skills': task.requirements,
        })
        .select()
        .single();
    return taskFromRow(row);
  }

  @override
  Future<Task> update(Task task) async {
    final row = await _client
        .from('tasks')
        .update({
          'volunteer_ids': task.volunteerIds,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', task.id)
        .select()
        .single();
    return taskFromRow(row);
  }

  @override
  Future<Task> addVolunteer(String taskId, String volunteerId) async {
    final existing = await getById(taskId);
    if (existing == null) throw StateError('Task $taskId not found');
    final ids = existing.volunteerIds.contains(volunteerId)
        ? existing.volunteerIds
        : [...existing.volunteerIds, volunteerId];
    return update(existing.copyWith(volunteerIds: ids));
  }

  @override
  Stream<List<Task>> watchForOrg(String orgId) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('supervising_org_id', orgId)
        .map((rows) => rows.map(taskFromRow).toList());
  }

  static Task taskFromRow(Map<String, dynamic> r) => Task(
        id: r['id'] as String,
        complaintId: r['complaint_id'] as String,
        partnerOrgId: r['supervising_org_id'] as String,
        requirements:
            (r['required_skills'] as List<dynamic>? ?? const []).cast<String>(),
        createdAt: DateTime.parse(r['created_at'] as String),
        volunteerIds:
            (r['volunteer_ids'] as List<dynamic>? ?? const []).cast<String>(),
      );
}

class SupabaseConfirmationRepository implements ConfirmationRepository {
  SupabaseConfirmationRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Confirmation>> getForComplaint(String complaintId) async {
    final rows = await _client
        .from('confirmations')
        .select()
        .eq('complaint_id', complaintId);
    return (rows as List<dynamic>)
        .map((r) => confirmationFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Confirmation?> getById(String id) async {
    final row = await _client
        .from('confirmations')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : confirmationFromRow(row);
  }

  @override
  Future<Confirmation> create(Confirmation c) async {
    final row = await _client
        .from('confirmations')
        .insert({
          'id': c.id,
          'complaint_id': c.complaintId,
          'user_id': c.userId,
          'kind': c.approved ? 'confirmed' : 'rejected',
          'lat': c.userLocation.latitude,
          'lng': c.userLocation.longitude,
          'note': c.reason,
        })
        .select()
        .single();
    return confirmationFromRow(row);
  }

  @override
  Future<bool> hasUserConfirmed(String complaintId, String userId) async {
    final row = await _client
        .from('confirmations')
        .select('id')
        .eq('complaint_id', complaintId)
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  static Confirmation confirmationFromRow(Map<String, dynamic> r) =>
      Confirmation(
        id: r['id'] as String,
        complaintId: r['complaint_id'] as String,
        userId: r['user_id'] as String,
        kind: ConfirmationKind.nearby,
        approved: (r['kind'] as String) == 'confirmed',
        at: DateTime.parse(r['created_at'] as String),
        userLocation: LatLng(
          (r['lat'] as num).toDouble(),
          (r['lng'] as num).toDouble(),
        ),
        reason: r['note'] as String?,
      );
}

class SupabaseCertificateRepository implements CertificateRepository {
  SupabaseCertificateRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Certificate>> getForUser(String userId) async {
    final rows =
        await _client.from('certificates').select().eq('user_id', userId);
    return (rows as List<dynamic>)
        .map((r) => certFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Certificate?> getById(String id) async {
    final row =
        await _client.from('certificates').select().eq('id', id).maybeSingle();
    return row == null ? null : certFromRow(row);
  }

  @override
  Future<Certificate?> getByCode(String verificationCode) async {
    final row = await _client
        .from('certificates')
        .select()
        .eq('verification_code', verificationCode)
        .maybeSingle();
    return row == null ? null : certFromRow(row);
  }

  @override
  Future<Certificate> create(Certificate cert) async {
    final row = await _client
        .from('certificates')
        .insert({
          'id': cert.id,
          'user_id': cert.userId,
          'anonymous_handle': cert.anonymousHandle,
          'org_id': cert.orgId,
          'hours': cert.hours,
          'verification_code': cert.verificationCode,
        })
        .select()
        .single();
    return certFromRow(row);
  }

  static Certificate certFromRow(Map<String, dynamic> r) => Certificate(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        anonymousHandle: r['anonymous_handle'] as String,
        orgId: r['org_id'] as String,
        hours: (r['hours'] as num).toDouble(),
        issuedAt: DateTime.parse(r['issued_at'] as String),
        verificationCode: r['verification_code'] as String,
      );
}
