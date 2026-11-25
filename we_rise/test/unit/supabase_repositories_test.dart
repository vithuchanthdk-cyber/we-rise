import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:we_rise/features/auth/data/supabase_auth_repository.dart';
import 'package:we_rise/features/complaints/data/in_memory_repositories.dart';
import 'package:we_rise/features/complaints/data/providers.dart';
import 'package:we_rise/features/complaints/data/supabase_photo_service.dart';
import 'package:we_rise/features/complaints/data/supabase_repositories.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';

class _FakeStorageFileApi extends Fake implements StorageFileApi {
  int attempts = 0;
  bool failFirstAttempt = false;

  @override
  Future<String> upload(
    String path,
    File file, {
    FileOptions? fileOptions,
    int? retryAttempts,
    StorageRetryController? retryController,
  }) async {
    attempts++;
    if (failFirstAttempt && attempts == 1) {
      throw const StorageException('Transient network error');
    }
    return path;
  }

  @override
  String getPublicUrl(
    String path, {
    DownloadBehavior? download,
    TransformOptions? transform,
  }) {
    return 'https://demo.supabase.co/storage/v1/object/public/complaint-photos/$path';
  }
}

class _FakeStorageClient extends Fake implements SupabaseStorageClient {
  _FakeStorageClient(this.fileApi);
  final _FakeStorageFileApi fileApi;

  @override
  StorageFileApi from(String id) => fileApi;
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient(this._storage);
  final _FakeStorageClient _storage;

  @override
  SupabaseStorageClient get storage => _storage;
}

void main() {
  group('Demo Mode default & Supabase row mappers', () {
    test('useMockProvider defaults to true with zero keys', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(useMockProvider), isTrue);
      expect(
        container.read(complaintRepositoryProvider),
        isA<InMemoryComplaintRepository>(),
      );
    });

    test('row-to-model mappers parse Supabase rows accurately', () {
      final user = SupabaseAuthRepository.userFromRow({
        'id': 'u1',
        'anonymous_handle': 'Citizen#1001',
        'role': 'volunteer',
        'ward_id': 'tondiarpet',
        'organisation_id': 'org-1',
        'volunteer_hours': 12.5,
      });
      expect(user.role, equals(UserRole.volunteer));
      expect(user.volunteerHours, equals(12.5));

      final org = SupabaseOrgRepository.orgFromRow({
        'id': 'org-1',
        'type': 'ngo',
        'name': 'Chennai Green Force',
        'ward_ids': ['tondiarpet', 'adyar'],
      });
      expect(org.type, equals(OrgType.ngo));
      expect(org.wardIds.length, equals(2));

      final task = SupabaseTaskRepository.taskFromRow({
        'id': 't1',
        'complaint_id': 'c1',
        'supervising_org_id': 'org-1',
        'required_skills': ['gloves'],
        'created_at': '2026-11-25T10:00:00.000Z',
        'volunteer_ids': ['u1'],
      });
      expect(task.partnerOrgId, equals('org-1'));
      expect(task.volunteerIds, contains('u1'));

      final conf = SupabaseConfirmationRepository.confirmationFromRow({
        'id': 'conf-1',
        'complaint_id': 'c1',
        'user_id': 'u1',
        'kind': 'confirmed',
        'lat': 13.08,
        'lng': 80.27,
        'created_at': '2026-11-25T10:00:00.000Z',
      });
      expect(conf.approved, isTrue);

      final cert = SupabaseCertificateRepository.certFromRow({
        'id': 'cert-1',
        'user_id': 'u1',
        'anonymous_handle': 'Citizen#1001',
        'org_id': 'org-1',
        'hours': 10.0,
        'issued_at': '2026-11-25T10:00:00.000Z',
        'verification_code': 'WR123456',
      });
      expect(cert.verificationCode, equals('WR123456'));
    });

    test('SupabasePhotoService retries transient upload failures and reports progress',
        () async {
      final fileApi = _FakeStorageFileApi()..failFirstAttempt = true;
      final client = _FakeSupabaseClient(_FakeStorageClient(fileApi));
      final service = SupabasePhotoService(client);
      final progresses = <double>[];

      final url = await service.uploadPhoto(
        file: File('dummy.jpg'),
        complaintId: 'c1',
        photoId: 'p1',
        onProgress: progresses.add,
      );

      expect(fileApi.attempts, equals(2));
      expect(progresses.last, equals(1.0));
      expect(url, contains('c1/p1.jpg'));
    });
  });
}
