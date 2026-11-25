import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/complaints/domain/models.dart';

void main() {
  group('PublicComplaintDto', () {
    test('strips reporterId, supporterIds, and onBehalfOf (no PII)', () {
      final complaint = Complaint(
        id: 'c-pii-1',
        trackingId: 'WR-CHE-2026-000099',
        category: ComplaintCategory.sewage,
        severity: 5,
        status: ComplaintStatus.VERIFIED,
        location: const LatLng(13.0827, 80.2707),
        wardId: 'tondiarpet',
        photos: [
          ComplaintPhoto(
            id: 'p1',
            url: 'https://example.com/photo.jpg',
            source: PhotoSource.gallery,
            capturedAt: DateTime(2026, 11, 20),
            isGalleryFlagged: true,
          ),
        ],
        createdAt: DateTime(2026, 11, 20),
        lastStatusChangeAt: DateTime(2026, 11, 20),
        reporterId: 'secret-user-id-Ramesh-9840012345',
        supporterIds: const [
          'secret-supporter-Priya-9840099999',
          'secret-supporter-Karthik-9840088888',
        ],
        riskClass: RiskClass.medium,
        priorityScore: 78.5,
        escalated: false,
        reopenCount: 0,
        note: 'Sewage overflow near school gate',
        onBehalfOf: 'Lakshmi +91-9840011111',
        timeline: [
          StatusEvent(
            complaintId: 'c-pii-1',
            status: ComplaintStatus.PENDING_REVIEW,
            at: DateTime(2026, 11, 20),
            actorRole: 'citizen',
          ),
        ],
      );

      final dto = PublicComplaintDto.fromComplaint(complaint);

      // Verify public fields are preserved
      expect(dto.id, equals('c-pii-1'));
      expect(dto.trackingId, equals('WR-CHE-2026-000099'));
      expect(dto.supportCount, equals(2));
      expect(dto.isGalleryFlagged, isTrue);
      expect(dto.timeline.first.actorRole, equals('citizen'));

      // Verify no PII strings appear anywhere in the public DTO representation
      final serialized = [
        dto.id,
        dto.trackingId,
        dto.category.name,
        dto.status.name,
        dto.wardId,
        dto.note ?? '',
        ...dto.photoUrls,
        ...dto.timeline.map((e) => '${e.actorRole} ${e.note ?? ''}'),
      ].join(' ');

      expect(serialized, isNot(contains('Ramesh')));
      expect(serialized, isNot(contains('Priya')));
      expect(serialized, isNot(contains('Karthik')));
      expect(serialized, isNot(contains('Lakshmi')));
      expect(serialized, isNot(contains('98400')));
    });
  });
}
