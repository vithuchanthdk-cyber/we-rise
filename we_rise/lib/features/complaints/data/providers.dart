import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'hive_offline_queue_repository.dart';
import 'in_memory_repositories.dart';
import 'location_service.dart';
import 'photo_service.dart';
import 'supabase_complaint_repository.dart';
import 'supabase_photo_service.dart';
import 'supabase_repositories.dart';
import 'sync_service.dart';
import 'voice_service.dart';

const String kSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String kSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// True when running in Demo Mode (no Supabase keys provided).
final useMockProvider = Provider<bool>((ref) {
  return kSupabaseUrl.isEmpty || kSupabaseAnonKey.isEmpty;
});

// ── Repository providers ─────────────────────────────────────────────────────

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  final useMock = ref.watch(useMockProvider);
  if (useMock) {
    return InMemoryComplaintRepository();
  }
  return SupabaseComplaintRepository(Supabase.instance.client);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (ref.watch(useMockProvider)) return InMemoryUserRepository();
  return SupabaseUserRepository(Supabase.instance.client);
});

final orgRepositoryProvider = Provider<OrgRepository>((ref) {
  if (ref.watch(useMockProvider)) return InMemoryOrgRepository();
  return SupabaseOrgRepository(Supabase.instance.client);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  if (ref.watch(useMockProvider)) {
    return InMemoryTaskRepository(
      complaintRepo: ref.watch(complaintRepositoryProvider),
    );
  }
  return SupabaseTaskRepository(Supabase.instance.client);
});

final confirmationRepositoryProvider = Provider<ConfirmationRepository>((ref) {
  if (ref.watch(useMockProvider)) return InMemoryConfirmationRepository();
  return SupabaseConfirmationRepository(Supabase.instance.client);
});

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  if (ref.watch(useMockProvider)) return InMemoryCertificateRepository();
  return SupabaseCertificateRepository(Supabase.instance.client);
});

final supabasePhotoServiceProvider = Provider<SupabasePhotoService?>((ref) {
  if (ref.watch(useMockProvider)) return null;
  return SupabasePhotoService(Supabase.instance.client);
});

final offlineQueueRepositoryProvider = Provider<OfflineQueueRepository>((ref) {
  final useMock = ref.watch(useMockProvider);
  if (useMock) {
    return InMemoryOfflineQueueRepository();
  }
  return HiveOfflineQueueRepository();
});

// ── Device / Feature services ────────────────────────────────────────────────

final photoServiceProvider = Provider<PhotoService>((ref) {
  return DevicePhotoService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return DeviceLocationService();
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return DeviceVoiceService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    queueRepository: ref.watch(offlineQueueRepositoryProvider),
    complaintRepository: ref.watch(complaintRepositoryProvider),
  );
});

// ── Safety / Moderation state (local block & abuse tracking) ─────────────────

final blockedUsersProvider = StateProvider<Set<String>>((ref) => const {});
final reportedAbuseIdsProvider = StateProvider<Set<String>>((ref) => const {});

// ── Data stream providers ────────────────────────────────────────────────────

final allComplaintsProvider = StreamProvider<List<Complaint>>((ref) {
  return ref.watch(complaintRepositoryProvider).watchAll();
});

/// Public-safe complaints (excludes PENDING_REVIEW, REJECTED, and blocked reporters).
final publicComplaintsProvider = Provider<AsyncValue<List<PublicComplaintDto>>>((ref) {
  final blocked = ref.watch(blockedUsersProvider);
  return ref.watch(allComplaintsProvider).whenData(
        (list) => list
            .where((c) =>
                c.status.isPublic &&
                c.status != ComplaintStatus.REJECTED &&
                !blocked.contains(c.reporterId))
            .map(PublicComplaintDto.fromComplaint)
            .toList(),
      );
});

final offlineQueueSizeProvider = StreamProvider<int>((ref) {
  return ref.watch(offlineQueueRepositoryProvider).watchQueueSize();
});
