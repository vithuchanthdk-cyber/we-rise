import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/complaints/domain/status_machine.dart';

void main() {
  group('StatusMachine', () {
    test('valid transition: PENDING_REVIEW -> VERIFIED', () {
      expect(
        () => StatusMachine.transition(
          ComplaintStatus.PENDING_REVIEW,
          ComplaintStatus.VERIFIED,
        ),
        returnsNormally,
      );
    });

    test('valid transition: VERIFIED -> ASSIGNED', () {
      expect(
        () => StatusMachine.transition(
          ComplaintStatus.VERIFIED,
          ComplaintStatus.ASSIGNED,
        ),
        returnsNormally,
      );
    });

    test('valid transition: ASSIGNED -> WORK_STARTED', () {
      expect(
        () => StatusMachine.transition(
          ComplaintStatus.ASSIGNED,
          ComplaintStatus.WORK_STARTED,
        ),
        returnsNormally,
      );
    });

    test('valid transition: WORK_STARTED -> AWAITING_CONFIRMATION', () {
      expect(
        () => StatusMachine.transition(
          ComplaintStatus.WORK_STARTED,
          ComplaintStatus.AWAITING_CONFIRMATION,
        ),
        returnsNormally,
      );
    });

    test('valid transition: AWAITING_CONFIRMATION -> SOLVED', () {
      expect(
        () => StatusMachine.transition(
          ComplaintStatus.AWAITING_CONFIRMATION,
          ComplaintStatus.SOLVED,
        ),
        returnsNormally,
      );
    });

    test('invalid: skip PENDING_REVIEW -> WORK_STARTED throws', () {
      expect(
        () => StatusMachine.transition(
          ComplaintStatus.PENDING_REVIEW,
          ComplaintStatus.WORK_STARTED,
        ),
        throwsA(isA<IllegalTransitionException>()),
      );
    });

    test('invalid: SOLVED -> ASSIGNED throws', () {
      expect(
        () => StatusMachine.transition(
          ComplaintStatus.SOLVED,
          ComplaintStatus.ASSIGNED,
        ),
        throwsA(isA<IllegalTransitionException>()),
      );
    });

    test('rejection allowed from PENDING_REVIEW', () {
      expect(
        () => StatusMachine.transition(
          ComplaintStatus.PENDING_REVIEW,
          ComplaintStatus.REJECTED,
        ),
        returnsNormally,
      );
    });

    test('reopen allowed from AWAITING_CONFIRMATION', () {
      expect(
        () => StatusMachine.transition(
          ComplaintStatus.AWAITING_CONFIRMATION,
          ComplaintStatus.REOPENED,
        ),
        returnsNormally,
      );
    });
  });
}
