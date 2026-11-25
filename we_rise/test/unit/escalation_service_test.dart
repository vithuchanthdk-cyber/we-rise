import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/complaints/domain/escalation_service.dart';
import 'package:we_rise/features/complaints/domain/models.dart';
import 'package:we_rise/features/complaints/domain/priority_calculator.dart';

class _FakeClock implements Clock {
  _FakeClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}

Complaint _make({
  required ComplaintStatus status,
  required DateTime lastStatusChangeAt,
  bool escalated = false,
}) =>
    Complaint(
      id: 'test',
      trackingId: 'WR-CHE-2026-000001',
      category: ComplaintCategory.garbage,
      severity: 3,
      status: status,
      location: const LatLng(13.0, 80.0),
      wardId: 'tondiarpet',
      photos: const [],
      createdAt: lastStatusChangeAt.subtract(const Duration(days: 10)),
      lastStatusChangeAt: lastStatusChangeAt,
      reporterId: 'u1',
      supporterIds: const [],
      riskClass: RiskClass.low,
      priorityScore: 50,
      escalated: escalated,
      reopenCount: 0,
    );

void main() {
  final base = DateTime(2026, 11, 20);

  group('EscalationService', () {
    test('escalates when no status change for 7 days', () {
      final clock = _FakeClock(base);
      final service = EscalationService(clock: clock);
      final complaint = _make(
        status: ComplaintStatus.VERIFIED,
        lastStatusChangeAt: base.subtract(const Duration(days: 7)),
      );
      expect(service.shouldEscalate(complaint), isTrue);
    });

    test('does not escalate if updated within 7 days', () {
      final clock = _FakeClock(base);
      final service = EscalationService(clock: clock);
      final complaint = _make(
        status: ComplaintStatus.VERIFIED,
        lastStatusChangeAt: base.subtract(const Duration(days: 6)),
      );
      expect(service.shouldEscalate(complaint), isFalse);
    });

    test('terminal statuses are exempt from escalation', () {
      final clock = _FakeClock(base);
      final service = EscalationService(clock: clock);
      for (final s in [ComplaintStatus.SOLVED, ComplaintStatus.REJECTED]) {
        final c = _make(
          status: s,
          lastStatusChangeAt: base.subtract(const Duration(days: 30)),
        );
        expect(service.shouldEscalate(c), isFalse, reason: '$s should be exempt');
      }
    });

    test('escalated complaint does not escalate again', () {
      final clock = _FakeClock(base);
      final service = EscalationService(clock: clock);
      final c = _make(
        status: ComplaintStatus.VERIFIED,
        lastStatusChangeAt: base.subtract(const Duration(days: 10)),
        escalated: true,
      );
      expect(service.shouldEscalate(c), isFalse);
    });
  });
}
