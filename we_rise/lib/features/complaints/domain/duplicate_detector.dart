import 'dart:math' as math;
import 'models.dart';
import 'enums.dart';

/// Detects potential duplicate complaints.
/// Duplicate rule: same category, within 30 m, within 14 days, not REJECTED/SOLVED.
class DuplicateDetector {
  static const double kMaxDistanceMetres = 30.0;
  static const int kMaxAgeDays = 14;

  /// Returns all existing complaints that could be duplicates of [incoming].
  static List<Complaint> findCandidates(
    Complaint incoming,
    List<Complaint> existing,
  ) {
    final cutoff = incoming.createdAt.subtract(
      const Duration(days: kMaxAgeDays),
    );

    return existing.where((c) {
      if (c.id == incoming.id) return false;
      if (c.category != incoming.category) return false;
      if (c.status == ComplaintStatus.REJECTED ||
          c.status == ComplaintStatus.SOLVED) {
        return false;
      }
      if (c.createdAt.isBefore(cutoff)) return false;
      final dist = haversineMetres(
        incoming.location.latitude,
        incoming.location.longitude,
        c.location.latitude,
        c.location.longitude,
      );
      return dist <= kMaxDistanceMetres;
    }).toList();
  }

  /// Haversine distance in metres between two coordinates.
  static double haversineMetres(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0; // Earth radius in metres
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dPhi = (lat2 - lat1) * math.pi / 180;
    final dLambda = (lon2 - lon1) * math.pi / 180;

    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }
}
