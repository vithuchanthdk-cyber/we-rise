import 'models.dart';
import 'priority_calculator.dart' show Clock, SystemClock;

/// Auto-escalation: complaints with no status change for ≥ 7 days become escalated.
/// The [Clock] is injectable for unit testing.
class EscalationService {
  const EscalationService({Clock? clock})
      : _clock = clock ?? const SystemClock();

  static const int kEscalationDays = 7;

  final Clock _clock;

  /// Returns updated list with escalation applied where needed.
  List<Complaint> checkAndEscalate(List<Complaint> complaints) {
    return complaints.map((c) => _maybeEscalate(c)).toList();
  }

  Complaint _maybeEscalate(Complaint c) {
    if (c.status.isTerminal) return c;
    if (c.escalated) return c; // already escalated

    final daysSinceChange =
        _clock.now().difference(c.lastStatusChangeAt).inDays;
    if (daysSinceChange >= kEscalationDays) {
      return c.copyWith(escalated: true);
    }
    return c;
  }

  /// True if a single complaint should be escalated.
  bool shouldEscalate(Complaint complaint) {
    if (complaint.status.isTerminal) return false;
    if (complaint.escalated) return false;
    final days = _clock.now().difference(complaint.lastStatusChangeAt).inDays;
    return days >= kEscalationDays;
  }
}
