import 'enums.dart';
import 'models.dart';

// ============================================================
// Abstract repository interfaces
// All production implementations (Supabase) live behind these.
// ============================================================

/// Abstract complaint repository \u2014 swap in-memory \u2194 Supabase via RepositoryModule.
abstract interface class ComplaintRepository {
  Future<List<Complaint>> getAll();
  Future<List<Complaint>> getByStatus(ComplaintStatus status);
  Future<List<Complaint>> getByReporter(String reporterId);
  Future<List<Complaint>> getByOrg(String orgId);
  Future<List<Complaint>> getNearby(LatLng center, double radiusMetres);
  Future<Complaint?> getById(String id);
  Future<Complaint?> getByTrackingId(String trackingId);
  Future<Complaint> create(Complaint complaint);
  Future<Complaint> update(Complaint complaint);
  Future<void> delete(String id);
  Future<Complaint> addSupporter(String complaintId, String userId);
  Future<Complaint> addStatusEvent(String complaintId, StatusEvent event);
  Future<int> nextSequenceNumber();
  Stream<List<Complaint>> watchAll();
  Stream<Complaint?> watchById(String id);
}

abstract interface class UserRepository {
  Future<AppUser?> getById(String id);
  Future<AppUser?> getByHandle(String anonymousHandle);
  Future<List<AppUser>> getAll();
  Future<AppUser> create(AppUser user);
  Future<AppUser> update(AppUser user);
  Future<void> delete(String id);
  Future<void> addHours(String userId, double hours);
  Stream<AppUser?> watchById(String id);
}

abstract interface class OrgRepository {
  Future<List<Organisation>> getAll();
  Future<Organisation?> getById(String id);
  Future<List<Organisation>> getByType(OrgType type);
  Future<Organisation> update(Organisation org);
  Stream<Organisation?> watchById(String id);
}

abstract interface class TaskRepository {
  Future<List<Task>> getAll();
  Future<List<Task>> getByOrg(String orgId);
  Future<List<Task>> getForComplaint(String complaintId);
  Future<List<Task>> getVolunteerSafe();
  Future<Task?> getById(String id);
  Future<Task> create(Task task);
  Future<Task> update(Task task);
  Future<Task> addVolunteer(String taskId, String volunteerId);
  Stream<List<Task>> watchForOrg(String orgId);
}

abstract interface class ConfirmationRepository {
  Future<List<Confirmation>> getForComplaint(String complaintId);
  Future<Confirmation?> getById(String id);
  Future<Confirmation> create(Confirmation confirmation);
  Future<bool> hasUserConfirmed(String complaintId, String userId);
}

abstract interface class CertificateRepository {
  Future<List<Certificate>> getForUser(String userId);
  Future<Certificate?> getById(String id);
  Future<Certificate?> getByCode(String verificationCode);
  Future<Certificate> create(Certificate certificate);
}

abstract interface class OfflineQueueRepository {
  Future<List<DraftReport>> getPendingDrafts();
  Future<void> enqueueDraft(DraftReport draft);
  Future<void> removeDraft(String id);
  Future<void> clearAll();
  Stream<int> watchQueueSize();
}

abstract interface class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signUpWithEmail(String email, String password);
  Future<void> signOut();
  Future<void> deleteAccount();
  Stream<AppUser?> watchCurrentUser();

  /// Demo mode: set the active user directly without auth
  Future<void> setDemoUser(AppUser user);
}
