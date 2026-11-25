import 'models.dart';
import 'enums.dart';
import 'duplicate_detector.dart';

enum ClosureResultKind { allowed, denied }

class ClosureResult {
  const ClosureResult({
    required this.kind,
    required this.reason,
  });

  final ClosureResultKind kind;
  final String reason;

  bool get isAllowed => kind == ClosureResultKind.allowed;

  static const ClosureResult allowed = ClosureResult(
    kind: ClosureResultKind.allowed,
    reason: 'All closure conditions met.',
  );
}

/// Validates whether a complaint can be closed.
/// Rules:
///   1. The original reporter must have confirmed.
///   2. Two distinct nearby users (≤ 300 m) must have confirmed.
///   3. The resolver must not be among the confirmers.
///   4. All confirming users must be distinct.
class ClosureRuleValidator {
  static const double kNearbyMetres = 300.0;
  static const int kRequiredNearbyConfirmations = 2;

  static ClosureResult canClose({
    required Complaint complaint,
    required List<Confirmation> confirmations,
    required String resolverId,
  }) {
    final approved = confirmations.where((c) => c.approved).toList();

    // Rule 3: resolver must not be among confirmers
    final resolverConfirmed = approved.any((c) => c.userId == resolverId);
    if (resolverConfirmed) {
      return const ClosureResult(
        kind: ClosureResultKind.denied,
        reason: 'The resolver cannot confirm their own fix.',
      );
    }

    // Rule 1: original reporter must have confirmed
    final reporterConfirmed = approved.any(
      (c) => c.kind == ConfirmationKind.reporter,
    );
    if (!reporterConfirmed) {
      return const ClosureResult(
        kind: ClosureResultKind.denied,
        reason: 'The original reporter has not confirmed the fix.',
      );
    }

    // Rule 2: two distinct nearby users
    final nearbyConfirmations = approved
        .where((c) => c.kind == ConfirmationKind.nearby)
        .where(
          (c) =>
              DuplicateDetector.haversineMetres(
                c.userLocation.latitude,
                c.userLocation.longitude,
                complaint.location.latitude,
                complaint.location.longitude,
              ) <=
              kNearbyMetres,
        )
        .toList();

    // Rule 4: distinct users
    final distinctNearbyUserIds =
        nearbyConfirmations.map((c) => c.userId).toSet();
    if (distinctNearbyUserIds.length < kRequiredNearbyConfirmations) {
      return ClosureResult(
        kind: ClosureResultKind.denied,
        reason:
            'Need $kRequiredNearbyConfirmations distinct nearby users to confirm. '
            'Got ${distinctNearbyUserIds.length}.',
      );
    }

    return ClosureResult.allowed;
  }
}
