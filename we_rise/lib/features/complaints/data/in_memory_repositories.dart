import 'dart:async';
import 'dart:math';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import '../domain/routing_engine.dart';
import 'seed_data.dart';

// ── In-memory complaint repository ──────────────────────────────────────────
class InMemoryComplaintRepository implements ComplaintRepository {
  InMemoryComplaintRepository() {
    _complaints = {for (final c in SeedData.complaints()) c.id: c};
  }

  late final Map<String, Complaint> _complaints;
  int _seq = 40;
  final _controller = StreamController<List<Complaint>>.broadcast();

  void _notify() => _controller.add(_complaints.values.toList());

  @override
  Future<List<Complaint>> getAll() async => _complaints.values.toList();

  @override
  Future<List<Complaint>> getByStatus(ComplaintStatus status) async =>
      _complaints.values.where((c) => c.status == status).toList();

  @override
  Future<List<Complaint>> getByReporter(String reporterId) async =>
      _complaints.values.where((c) => c.reporterId == reporterId).toList();

  @override
  Future<List<Complaint>> getByOrg(String orgId) async =>
      _complaints.values.where((c) => c.assignedOrgId == orgId).toList();

  @override
  Future<List<Complaint>> getNearby(LatLng center, double radiusMetres) async =>
      _complaints.values
          .where((c) => _haversine(center, c.location) <= radiusMetres)
          .toList();

  @override
  Future<Complaint?> getById(String id) async => _complaints[id];

  @override
  Future<Complaint?> getByTrackingId(String trackingId) async =>
      _complaints.values.where((c) => c.trackingId == trackingId).firstOrNull;

  @override
  Future<Complaint> create(Complaint complaint) async {
    _complaints[complaint.id] = complaint;
    _notify();
    return complaint;
  }

  @override
  Future<Complaint> update(Complaint complaint) async {
    _complaints[complaint.id] = complaint;
    _notify();
    return complaint;
  }

  @override
  Future<void> delete(String id) async {
    _complaints.remove(id);
    _notify();
  }

  @override
  Future<Complaint> addSupporter(String complaintId, String userId) async {
    final c = _complaints[complaintId]!;
    if (!c.supporterIds.contains(userId)) {
      final updated = c.copyWith(
        supporterIds: [...c.supporterIds, userId],
      );
      _complaints[complaintId] = updated;
      _notify();
      return updated;
    }
    return c;
  }

  @override
  Future<Complaint> addStatusEvent(String complaintId, StatusEvent event) async {
    final c = _complaints[complaintId]!;
    final updated = c.copyWith(
      status: event.status,
      timeline: [...c.timeline, event],
      lastStatusChangeAt: event.at,
    );
    _complaints[complaintId] = updated;
    _notify();
    return updated;
  }

  @override
  Future<int> nextSequenceNumber() async => ++_seq;

  @override
  Stream<List<Complaint>> watchAll() async* {
    yield _complaints.values.toList();
    yield* _controller.stream;
  }

  @override
  Stream<Complaint?> watchById(String id) async* {
    yield _complaints[id];
    yield* _controller.stream.map((_) => _complaints[id]);
  }

  static double _haversine(LatLng a, LatLng b) {
    const r = 6371000.0;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final x = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(x), sqrt(1 - x));
  }
}

// ── In-memory user repository ────────────────────────────────────────────────
class InMemoryUserRepository implements UserRepository {
  final Map<String, AppUser> _users = {
    for (final u in SeedData.users) u.id: u,
  };
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Future<AppUser?> getById(String id) async => _users[id];

  @override
  Future<AppUser?> getByHandle(String handle) async =>
      _users.values.where((u) => u.anonymousHandle == handle).firstOrNull;

  @override
  Future<List<AppUser>> getAll() async => _users.values.toList();

  @override
  Future<AppUser> create(AppUser user) async {
    _users[user.id] = user;
    return user;
  }

  @override
  Future<AppUser> update(AppUser user) async {
    _users[user.id] = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> delete(String id) async => _users.remove(id);

  @override
  Future<void> addHours(String userId, double hours) async {
    final u = _users[userId];
    if (u != null) {
      _users[userId] = u.copyWith(volunteerHours: u.volunteerHours + hours);
    }
  }

  @override
  Stream<AppUser?> watchById(String id) =>
      _controller.stream.where((u) => u?.id == id);
}

// ── In-memory org repository ─────────────────────────────────────────────────
class InMemoryOrgRepository implements OrgRepository {
  final Map<String, Organisation> _orgs = {
    for (final o in SeedData.organisations) o.id: o,
  };
  final _controller = StreamController<Organisation?>.broadcast();

  @override
  Future<List<Organisation>> getAll() async => _orgs.values.toList();

  @override
  Future<Organisation?> getById(String id) async => _orgs[id];

  @override
  Future<List<Organisation>> getByType(OrgType type) async =>
      _orgs.values.where((o) => o.type == type).toList();

  @override
  Future<Organisation> update(Organisation org) async {
    _orgs[org.id] = org;
    return org;
  }

  @override
  Stream<Organisation?> watchById(String id) =>
      _controller.stream.where((o) => o?.id == id);
}

// ── In-memory confirmation repository ───────────────────────────────────────
class InMemoryConfirmationRepository implements ConfirmationRepository {
  final Map<String, Confirmation> _confs = {};

  @override
  Future<List<Confirmation>> getForComplaint(String complaintId) async =>
      _confs.values.where((c) => c.complaintId == complaintId).toList();

  @override
  Future<Confirmation?> getById(String id) async => _confs[id];

  @override
  Future<Confirmation> create(Confirmation c) async {
    _confs[c.id] = c;
    return c;
  }

  @override
  Future<bool> hasUserConfirmed(String complaintId, String userId) async =>
      _confs.values
          .any((c) => c.complaintId == complaintId && c.userId == userId);
}

// ── In-memory certificate repository ────────────────────────────────────────
class InMemoryCertificateRepository implements CertificateRepository {
  final Map<String, Certificate> _certs = {};

  @override
  Future<List<Certificate>> getForUser(String userId) async =>
      _certs.values.where((c) => c.userId == userId).toList();

  @override
  Future<Certificate?> getById(String id) async => _certs[id];

  @override
  Future<Certificate?> getByCode(String code) async =>
      _certs.values.where((c) => c.verificationCode == code).firstOrNull;

  @override
  Future<Certificate> create(Certificate cert) async {
    _certs[cert.id] = cert;
    return cert;
  }
}

// ── In-memory offline queue ──────────────────────────────────────────────────
class InMemoryOfflineQueueRepository implements OfflineQueueRepository {
  final Map<String, DraftReport> _queue = {};
  final _controller = StreamController<int>.broadcast();

  @override
  Future<List<DraftReport>> getPendingDrafts() async => _queue.values.toList();

  @override
  Future<void> enqueueDraft(DraftReport draft) async {
    _queue[draft.id] = draft;
    _controller.add(_queue.length);
  }

  @override
  Future<void> removeDraft(String id) async {
    _queue.remove(id);
    _controller.add(_queue.length);
  }

  @override
  Future<void> clearAll() async {
    _queue.clear();
    _controller.add(0);
  }

  @override
  Stream<int> watchQueueSize() async* {
    yield _queue.length;
    yield* _controller.stream;
  }
}

// ── In-memory auth repository ────────────────────────────────────────────────
class InMemoryAuthRepository implements AuthRepository {
  AppUser? _current;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Future<AppUser?> getCurrentUser() async => _current;

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final user = SeedData.users.first;
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signUpWithEmail(String email, String password) async {
    return signInWithEmail(email, password);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Stream<AppUser?> watchCurrentUser() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> setDemoUser(AppUser user) async {
    _current = user;
    _controller.add(user);
  }
}

// ── In-memory task repository ────────────────────────────────────────────────
class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository({ComplaintRepository? complaintRepo})
      : _complaintRepo = complaintRepo {
    _tasks = {for (final t in SeedData.tasks()) t.id: t};
  }

  final ComplaintRepository? _complaintRepo;
  late final Map<String, Task> _tasks;
  final _controller = StreamController<List<Task>>.broadcast();

  void _notify() => _controller.add(_tasks.values.toList());

  @override
  Future<List<Task>> getAll() async => _tasks.values.toList();

  @override
  Future<List<Task>> getByOrg(String orgId) async =>
      _tasks.values.where((t) => t.partnerOrgId == orgId).toList();

  @override
  Future<List<Task>> getForComplaint(String complaintId) async =>
      _tasks.values.where((t) => t.complaintId == complaintId).toList();

  @override
  Future<List<Task>> getVolunteerSafe() async {
    if (_complaintRepo == null) return _tasks.values.toList();
    final safe = <Task>[];
    for (final t in _tasks.values) {
      final c = await _complaintRepo.getById(t.complaintId);
      if (c != null && c.riskClass.isVolunteerSafe) {
        safe.add(t);
      }
    }
    return safe;
  }

  @override
  Future<Task?> getById(String id) async => _tasks[id];

  @override
  Future<Task> create(Task task) async {
    if (_complaintRepo != null) {
      final c = await _complaintRepo.getById(task.complaintId);
      if (c != null) {
        RoutingEngine.assertVolunteerNeverAssignedToDangerous(
          c.riskClass,
          true,
        );
      }
    }
    _tasks[task.id] = task;
    _notify();
    return task;
  }

  @override
  Future<Task> update(Task task) async {
    _tasks[task.id] = task;
    _notify();
    return task;
  }

  @override
  Future<Task> addVolunteer(String taskId, String volunteerId) async {
    final t = _tasks[taskId]!;
    if (_complaintRepo != null) {
      final c = await _complaintRepo.getById(t.complaintId);
      if (c != null) {
        RoutingEngine.assertVolunteerNeverAssignedToDangerous(
          c.riskClass,
          true,
        );
      }
    }
    if (!t.volunteerIds.contains(volunteerId)) {
      final updated = t.copyWith(
        volunteerIds: [...t.volunteerIds, volunteerId],
      );
      _tasks[taskId] = updated;
      _notify();
      return updated;
    }
    return t;
  }

  @override
  Stream<List<Task>> watchForOrg(String orgId) async* {
    yield _tasks.values.where((t) => t.partnerOrgId == orgId).toList();
    yield* _controller.stream
        .map((list) => list.where((t) => t.partnerOrgId == orgId).toList());
  }
}
