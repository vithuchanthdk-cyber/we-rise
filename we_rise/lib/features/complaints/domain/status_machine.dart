import 'enums.dart';

class IllegalTransitionException implements Exception {
  const IllegalTransitionException(this.from, this.to);
  final ComplaintStatus from;
  final ComplaintStatus to;

  @override
  String toString() =>
      'IllegalTransitionException: Cannot transition from ${from.name} to ${to.name}';
}

/// Explicit state machine for complaint status transitions.
/// Only this class may change complaint status — all other code calls [transition].
class StatusMachine {
  static const Map<ComplaintStatus, List<ComplaintStatus>> _allowed = {
    ComplaintStatus.PENDING_REVIEW: [
      ComplaintStatus.VERIFIED,
      ComplaintStatus.REJECTED,
    ],
    ComplaintStatus.REJECTED: [], // terminal
    ComplaintStatus.VERIFIED: [
      ComplaintStatus.ASSIGNED,
      ComplaintStatus.REJECTED,
    ],
    ComplaintStatus.ASSIGNED: [
      ComplaintStatus.WORK_STARTED,
      ComplaintStatus.VERIFIED, // un-assign
    ],
    ComplaintStatus.WORK_STARTED: [
      ComplaintStatus.AWAITING_CONFIRMATION,
    ],
    ComplaintStatus.AWAITING_CONFIRMATION: [
      ComplaintStatus.SOLVED,
      ComplaintStatus.REOPENED, // confirmations rejected
    ],
    ComplaintStatus.SOLVED: [], // terminal
    ComplaintStatus.REOPENED: [
      ComplaintStatus.VERIFIED,
      ComplaintStatus.PENDING_REVIEW,
    ],
  };

  /// Returns the new status or throws [IllegalTransitionException].
  static ComplaintStatus transition(
    ComplaintStatus from,
    ComplaintStatus to,
  ) {
    final allowed = _allowed[from] ?? [];
    if (!allowed.contains(to)) {
      throw IllegalTransitionException(from, to);
    }
    return to;
  }

  /// True if the transition is legal.
  static bool canTransition(ComplaintStatus from, ComplaintStatus to) {
    final allowed = _allowed[from] ?? [];
    return allowed.contains(to);
  }

  /// All statuses reachable from [from].
  static List<ComplaintStatus> allowedTransitions(ComplaintStatus from) =>
      List.unmodifiable(_allowed[from] ?? []);
}
