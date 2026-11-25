import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/features/complaints/domain/duplicate_detector.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/complaints/domain/models.dart';

Complaint _make({
  required String id,
  required ComplaintCategory cat,
  required ComplaintStatus status,
  required LatLng location,
  required DateTime createdAt,
}) =>
    Complaint(
      id: id,
      trackingId: 'WR-CHE-2026-$id',
      category: cat,
      severity: cat.defaultSeverity,
      status: status,
      location: location,
      wardId: 'tondiarpet',
      photos: const [],
      createdAt: createdAt,
      lastStatusChangeAt: createdAt,
      reporterId: 'u1',
      supporterIds: const [],
      riskClass: RiskClass.low,
      priorityScore: 50,
      escalated: false,
      reopenCount: 0,
    );

void main() {
  final base = DateTime(2026, 11, 20);

  group('DuplicateDetector', () {
    final existing = _make(
      id: 'c001',
      cat: ComplaintCategory.pothole,
      status: ComplaintStatus.VERIFIED,
      location: const LatLng(13.0000, 80.0000),
      createdAt: base.subtract(const Duration(days: 5)),
    );

    test('detects duplicate: same category, within 30m, within 14 days', () {
      final candidate = _make(
        id: 'c002',
        cat: ComplaintCategory.pothole,
        status: ComplaintStatus.PENDING_REVIEW,
        location: const LatLng(13.00010, 80.00010), // ~15 m away
        createdAt: base,
      );
      final results = DuplicateDetector.findCandidates(candidate, [existing]);
      expect(results, isNotEmpty);
      expect(results.first.id, equals('c001'));
    });

    test('no duplicate if distance > 30m', () {
      final candidate = _make(
        id: 'c003',
        cat: ComplaintCategory.pothole,
        status: ComplaintStatus.PENDING_REVIEW,
        location: const LatLng(13.0004, 80.0004), // ~60 m away
        createdAt: base,
      );
      final results = DuplicateDetector.findCandidates(candidate, [existing]);
      expect(results, isEmpty);
    });

    test('no duplicate if different category', () {
      final candidate = _make(
        id: 'c004',
        cat: ComplaintCategory.garbage,
        status: ComplaintStatus.PENDING_REVIEW,
        location: const LatLng(13.00010, 80.00010),
        createdAt: base,
      );
      final results = DuplicateDetector.findCandidates(candidate, [existing]);
      expect(results, isEmpty);
    });

    test('no duplicate if more than 14 days old', () {
      final old = _make(
        id: 'c005',
        cat: ComplaintCategory.pothole,
        status: ComplaintStatus.VERIFIED,
        location: const LatLng(13.0000, 80.0000),
        createdAt: base.subtract(const Duration(days: 15)),
      );
      final candidate = _make(
        id: 'c006',
        cat: ComplaintCategory.pothole,
        status: ComplaintStatus.PENDING_REVIEW,
        location: const LatLng(13.00010, 80.00010),
        createdAt: base,
      );
      final results = DuplicateDetector.findCandidates(candidate, [old]);
      expect(results, isEmpty);
    });

    test('no duplicate if existing is rejected/solved', () {
      final solved = _make(
        id: 'c007',
        cat: ComplaintCategory.pothole,
        status: ComplaintStatus.SOLVED,
        location: const LatLng(13.00010, 80.00010),
        createdAt: base.subtract(const Duration(days: 3)),
      );
      final candidate = _make(
        id: 'c008',
        cat: ComplaintCategory.pothole,
        status: ComplaintStatus.PENDING_REVIEW,
        location: const LatLng(13.00010, 80.00010),
        createdAt: base,
      );
      final results = DuplicateDetector.findCandidates(candidate, [solved]);
      expect(results, isEmpty);
    });
  });
}
