import 'enums.dart';

class RoutingResult {
  const RoutingResult({
    required this.assignedTo,
    required this.isAuthority,
    required this.volunteersAllowed,
    this.orgType,
  });

  /// ID or label of the entity to route to
  final String assignedTo;
  final bool isAuthority;
  final bool volunteersAllowed;
  final OrgType? orgType;
}

/// Deterministic, unit-tested routing engine.
/// DANGEROUS complaints ALWAYS go to authority; volunteers are NEVER assigned.
class RoutingEngine {
  /// Route a complaint based on its category and risk class.
  static RoutingResult route(ComplaintCategory category, RiskClass risk) {
    switch (risk) {
      case RiskClass.dangerous:
        // HARD RULE: electrical faults, open manholes, live wires → authority only.
        // This is enforced here in the domain layer, not just the UI.
        return const RoutingResult(
          assignedTo: 'authority',
          isAuthority: true,
          volunteersAllowed: false,
          orgType: OrgType.authority,
        );

      case RiskClass.medium:
        // Infrastructure issues → authority
        if (category == ComplaintCategory.pothole ||
            category == ComplaintCategory.sewage ||
            category == ComplaintCategory.waterlogging) {
          return const RoutingResult(
            assignedTo: 'authority',
            isAuthority: true,
            volunteersAllowed: false,
            orgType: OrgType.authority,
          );
        }
        // Other medium-risk → partner (with supervision)
        return const RoutingResult(
          assignedTo: 'partner',
          isAuthority: false,
          volunteersAllowed: true,
          orgType: OrgType.ngo,
        );

      case RiskClass.low:
        // Garbage in parks, blocked drains, small cleanups → partner org
        return const RoutingResult(
          assignedTo: 'partner',
          isAuthority: false,
          volunteersAllowed: true,
          orgType: OrgType.ngo,
        );
    }
  }

  /// Throws [StateError] if volunteers are assigned to a dangerous complaint.
  /// Call this from the data layer before persisting any task assignment.
  static void assertVolunteerNeverAssignedToDangerous(
    RiskClass risk,
    bool assigningVolunteer,
  ) {
    if (risk == RiskClass.dangerous && assigningVolunteer) {
      throw StateError(
        'SAFETY VIOLATION: Volunteers must never be assigned to DANGEROUS complaints.',
      );
    }
  }
}
