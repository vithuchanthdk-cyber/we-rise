import 'dart:math' as math;

import 'models.dart';

/// Ward vulnerability index seed data.
/// Higher = more vulnerable (under-represented, low-income).
const Map<String, double> kWardVulnerabilityIndex = {
  'tondiarpet': 0.90,
  'perungudi': 0.75,
  'kodambakkam': 0.70,
  'velachery': 0.55,
  'adyar': 0.30,
  't_nagar': 0.35,
  'anna_nagar': 0.25,
  'sholinganallur': 0.45,
};

/// Scoring weights (must sum to 1.0).
const double kWeightSeverity = 0.35;
const double kWeightAgeFactor = 0.25;
const double kWeightEquity = 0.20;
const double kWeightRecurrence = 0.12;
const double kWeightDemand = 0.08;

/// Hard cap on support count — log-scaled so upvotes can NEVER dominate.
const int kDemandCap = 50;

/// Explainer entry for the priority breakdown shown in the UI.
class PriorityComponent {
  const PriorityComponent({
    required this.label,
    required this.score,
    required this.weight,
    required this.explanation,
  });

  final String label;

  /// Normalised sub-score (0–1)
  final double score;
  final double weight;
  final String explanation;

  /// Weighted contribution to the total
  double get contribution => score * weight;
}

class PriorityResult {
  const PriorityResult({required this.total, required this.components});
  final double total; // 0–100
  final List<PriorityComponent> components;
}

/// Clock abstraction for testability.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

/// Calculates the priority score (0–100) for a complaint.
/// Formula:
///   score = 100 * (0.35·severity + 0.25·ageFactor + 0.20·equityWeight
///                  + 0.12·recurrence + 0.08·demandCapped)
///
/// All sub-scores are normalised to 0–1 before weighting.
class PriorityCalculator {
  const PriorityCalculator({Clock? clock})
      : _clock = clock ?? const SystemClock();

  final Clock _clock;

  PriorityResult score(
    Complaint complaint, {
    required int recurrenceCount,
  }) {
    final severity = _severityScore(complaint.severity);
    final age = _ageFactorScore(complaint.createdAt);
    final equity = _equityScore(complaint.wardId);
    final recurrence = _recurrenceScore(recurrenceCount);
    final demand = _demandScore(complaint.supportCount);

    final total = 100 *
        (severity * kWeightSeverity +
            age * kWeightAgeFactor +
            equity * kWeightEquity +
            recurrence * kWeightRecurrence +
            demand * kWeightDemand);

    return PriorityResult(
      total: total.clamp(0, 100),
      components: [
        PriorityComponent(
          label: 'Severity',
          score: severity,
          weight: kWeightSeverity,
          explanation: _severityExplanation(complaint.severity),
        ),
        PriorityComponent(
          label: 'Time Pending',
          score: age,
          weight: kWeightAgeFactor,
          explanation: _ageExplanation(complaint.createdAt),
        ),
        PriorityComponent(
          label: 'Area Vulnerability',
          score: equity,
          weight: kWeightEquity,
          explanation: _equityExplanation(complaint.wardId, equity),
        ),
        PriorityComponent(
          label: 'Recurring Problem',
          score: recurrence,
          weight: kWeightRecurrence,
          explanation:
              recurrenceCount > 0
                  ? 'Reported $recurrenceCount time(s) previously in this area.'
                  : 'First occurrence in this area.',
        ),
        PriorityComponent(
          label: 'Community Demand',
          score: demand,
          weight: kWeightDemand,
          explanation: _demandExplanation(complaint.supportCount),
        ),
      ],
    );
  }

  // --- Sub-score calculators ---

  double _severityScore(int severity) => ((severity - 1) / 4).clamp(0.0, 1.0);

  double _ageFactorScore(DateTime createdAt) {
    final days = _clock.now().difference(createdAt).inDays;
    return (days / 30).clamp(0.0, 1.0);
  }

  double _equityScore(String wardId) =>
      kWardVulnerabilityIndex[wardId] ?? 0.5;

  double _recurrenceScore(int count) =>
      (count / 10).clamp(0.0, 1.0); // cap at 10

  double _demandScore(int supports) {
    if (supports <= 0) return 0;
    final capped = math.min(supports, kDemandCap);
    return (math.log(capped + 1) / math.log(kDemandCap + 1)).clamp(0.0, 1.0);
  }

  // --- Explanation strings ---

  String _severityExplanation(int severity) {
    switch (severity) {
      case 5:
        return 'Extreme risk — immediate health or safety hazard.';
      case 4:
        return 'High severity — major inconvenience or infrastructure damage.';
      case 3:
        return 'Moderate severity — affects daily life.';
      case 2:
        return 'Low severity — minor nuisance.';
      default:
        return 'Cosmetic issue — minimal impact.';
    }
  }

  String _ageExplanation(DateTime createdAt) {
    final days = _clock.now().difference(createdAt).inDays;
    if (days >= 30) return 'Pending for 30+ days — maximum age weight applied.';
    if (days >= 7) return 'Pending for $days days — escalation risk.';
    return 'Reported $days day(s) ago.';
  }

  String _equityExplanation(String wardId, double index) {
    if (index >= 0.7) {
      return 'High-vulnerability ward — under-reporting areas are not penalised.';
    }
    if (index >= 0.4) return 'Moderate-vulnerability ward.';
    return 'Lower-vulnerability ward.';
  }

  String _demandExplanation(int supports) {
    if (supports >= kDemandCap) {
      return '$supports supporters — demand capped to prevent vote-gaming.';
    }
    return '$supports supporter(s) — log-scaled to avoid upvote dominance.';
  }
}
