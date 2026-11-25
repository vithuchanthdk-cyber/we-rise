import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/features/complaints/domain/closure_rule_validator.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/complaints/domain/models.dart';

Confirmation _conf({
  required String userId,
  required ConfirmationKind kind,
  required LatLng location,
  required String complaintId,
  bool approved = true,
}) =>
    Confirmation(
      id: 'conf-$userId',
      complaintId: complaintId,
      userId: userId,
      kind: kind,
      approved: approved,
      at: DateTime(2026, 11, 20),
      userLocation: location,
    );

Complaint _makeComplaint(String id, LatLng origin, String reporterId) =>
    Complaint(
      id: id,
      trackingId: 'WR-CHE-2026-000001',
      category: ComplaintCategory.garbage,
      severity: 3,
      status: ComplaintStatus.AWAITING_CONFIRMATION,
      location: origin,
      wardId: 'adyar',
      photos: const [],
      createdAt: DateTime(2026, 11, 1),
      lastStatusChangeAt: DateTime(2026, 11, 20),
      reporterId: reporterId,
      supporterIds: const [],
      riskClass: RiskClass.low,
      priorityScore: 50,
      escalated: false,
      reopenCount: 0,
    );

void main() {
  const origin = LatLng(13.0, 80.0);
  const nearby = LatLng(13.0010, 80.0010); // ~160 m — within 300 m
  const farAway = LatLng(13.0040, 80.0040); // ~630 m — outside 300 m
  const resolverUserId = 'u-resolver';
  const reporterUserId = 'u-reporter';

  group('ClosureRuleValidator', () {
    test('valid closure: reporter confirmed + 2 distinct nearby non-resolvers', () {
      final complaint = _makeComplaint('c1', origin, reporterUserId);
      final confirmations = [
        _conf(
          userId: reporterUserId,
          kind: ConfirmationKind.reporter,
          location: nearby,
          complaintId: 'c1',
        ),
        _conf(
          userId: 'u-nearby-1',
          kind: ConfirmationKind.nearby,
          location: nearby,
          complaintId: 'c1',
        ),
        _conf(
          userId: 'u-nearby-2',
          kind: ConfirmationKind.nearby,
          location: nearby,
          complaintId: 'c1',
        ),
      ];
      final result = ClosureRuleValidator.canClose(
        complaint: complaint,
        confirmations: confirmations,
        resolverId: resolverUserId,
      );
      expect(result.isAllowed, isTrue);
    });

    test('fails if reporter has not confirmed', () {
      final complaint = _makeComplaint('c2', origin, reporterUserId);
      final confirmations = [
        _conf(
          userId: 'u-nearby-1',
          kind: ConfirmationKind.nearby,
          location: nearby,
          complaintId: 'c2',
        ),
        _conf(
          userId: 'u-nearby-2',
          kind: ConfirmationKind.nearby,
          location: nearby,
          complaintId: 'c2',
        ),
      ];
      final result = ClosureRuleValidator.canClose(
        complaint: complaint,
        confirmations: confirmations,
        resolverId: resolverUserId,
      );
      expect(result.isAllowed, isFalse);
      expect(result.reason, contains('reporter'));
    });

    test('fails if resolver is among confirmers', () {
      final complaint = _makeComplaint('c3', origin, reporterUserId);
      final confirmations = [
        _conf(
          userId: reporterUserId,
          kind: ConfirmationKind.reporter,
          location: nearby,
          complaintId: 'c3',
        ),
        _conf(
          userId: resolverUserId,
          kind: ConfirmationKind.nearby,
          location: nearby,
          complaintId: 'c3',
        ),
        _conf(
          userId: 'u-nearby-1',
          kind: ConfirmationKind.nearby,
          location: nearby,
          complaintId: 'c3',
        ),
      ];
      final result = ClosureRuleValidator.canClose(
        complaint: complaint,
        confirmations: confirmations,
        resolverId: resolverUserId,
      );
      expect(result.isAllowed, isFalse);
      expect(result.reason, contains('resolver'));
    });

    test('fails if fewer than 2 distinct nearby users (outside 300m)', () {
      final complaint = _makeComplaint('c4', origin, reporterUserId);
      final confirmations = [
        _conf(
          userId: reporterUserId,
          kind: ConfirmationKind.reporter,
          location: nearby,
          complaintId: 'c4',
        ),
        _conf(
          userId: 'u-far',
          kind: ConfirmationKind.nearby,
          location: farAway,
          complaintId: 'c4',
        ),
        _conf(
          userId: 'u-far-2',
          kind: ConfirmationKind.nearby,
          location: farAway,
          complaintId: 'c4',
        ),
      ];
      final result = ClosureRuleValidator.canClose(
        complaint: complaint,
        confirmations: confirmations,
        resolverId: resolverUserId,
      );
      expect(result.isAllowed, isFalse);
      expect(result.reason, contains('nearby'));
    });
  });
}
