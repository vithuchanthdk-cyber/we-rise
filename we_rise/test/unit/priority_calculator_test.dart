import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/complaints/domain/models.dart';
import 'package:we_rise/features/complaints/domain/priority_calculator.dart';

class _FakeClock implements Clock {
  _FakeClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}

Complaint _makeComplaint({
  required ComplaintCategory category,
  required String wardId,
  required int supportCount,
  required int daysOld,
  int? severity,
  DateTime? refDate,
}) {
  final base = refDate ?? DateTime(2026, 11, 20);
  final created = base.subtract(Duration(days: daysOld));
  return Complaint(
    id: 'test',
    trackingId: 'WR-CHE-2026-000001',
    category: category,
    severity: severity ?? category.defaultSeverity,
    status: ComplaintStatus.VERIFIED,
    location: const LatLng(13.0, 80.2),
    wardId: wardId,
    photos: const [],
    createdAt: created,
    lastStatusChangeAt: created,
    reporterId: 'u1',
    supporterIds: List.generate(supportCount, (i) => 'u$i'),
    riskClass: RiskClass.low,
    priorityScore: 0,
    escalated: false,
    reopenCount: 0,
  );
}

void main() {
  final refDate = DateTime(2026, 11, 20);
  final clock = _FakeClock(refDate);
  final calc = PriorityCalculator(clock: clock);

  group('PriorityCalculator', () {
    test('score is in [0, 100]', () {
      final complaint = _makeComplaint(
        category: ComplaintCategory.garbage,
        wardId: 'adyar',
        supportCount: 0,
        daysOld: 1,
        refDate: refDate,
      );
      final result = calc.score(complaint, recurrenceCount: 0);
      expect(result.total, inInclusiveRange(0.0, 100.0));
    });

    // KEY TEST: sewage leak in low-income ward with 3 supports must outrank
    // minor garbage in affluent ward with 300 supports.
    test('sewage in low-income ward outranks garbage in affluent ward', () {
      final sewage = _makeComplaint(
        category: ComplaintCategory.sewage,
        wardId: 'tondiarpet', // vulnerability 0.90
        supportCount: 3,
        daysOld: 10,
        refDate: refDate,
      );
      final garbage = _makeComplaint(
        category: ComplaintCategory.garbage,
        wardId: 'anna_nagar', // vulnerability 0.25
        supportCount: 300,
        daysOld: 1,
        refDate: refDate,
      );
      final sewageResult = calc.score(sewage, recurrenceCount: 1);
      final garbageResult = calc.score(garbage, recurrenceCount: 0);
      expect(
        sewageResult.total,
        greaterThan(garbageResult.total),
        reason:
            'Sewage in Tondiarpet (vuln=0.90, 3 supports) must outrank '
            'garbage in Anna Nagar (vuln=0.25, 300 supports). '
            'sewage=${sewageResult.total.toStringAsFixed(2)}, '
            'garbage=${garbageResult.total.toStringAsFixed(2)}',
      );
    });

    test('demand is capped: 50 supports == 500 supports (demandCapped)', () {
      final base = _makeComplaint(
        category: ComplaintCategory.garbage,
        wardId: 'adyar',
        supportCount: 50,
        daysOld: 5,
        refDate: refDate,
      );
      final inflated = _makeComplaint(
        category: ComplaintCategory.garbage,
        wardId: 'adyar',
        supportCount: 500,
        daysOld: 5,
        refDate: refDate,
      );
      final r1 = calc.score(base, recurrenceCount: 0);
      final r2 = calc.score(inflated, recurrenceCount: 0);
      expect((r1.total - r2.total).abs(), lessThan(0.5));
    });

    test('ageFactor grows with days (up to 30)', () {
      final young = _makeComplaint(
        category: ComplaintCategory.garbage,
        wardId: 'adyar',
        supportCount: 0,
        daysOld: 1,
        refDate: refDate,
      );
      final old = _makeComplaint(
        category: ComplaintCategory.garbage,
        wardId: 'adyar',
        supportCount: 0,
        daysOld: 30,
        refDate: refDate,
      );
      final r1 = calc.score(young, recurrenceCount: 0);
      final r2 = calc.score(old, recurrenceCount: 0);
      expect(r2.total, greaterThan(r1.total));
    });

    test('components sum approximates total / 100', () {
      final c = _makeComplaint(
        category: ComplaintCategory.pothole,
        wardId: 'velachery',
        supportCount: 5,
        daysOld: 7,
        refDate: refDate,
      );
      final r = calc.score(c, recurrenceCount: 2);
      final sum = r.components.fold<double>(
        0.0,
        (acc, comp) => acc + comp.contribution,
      );
      expect(r.total, closeTo(sum * 100, 0.01));
    });
  });
}
