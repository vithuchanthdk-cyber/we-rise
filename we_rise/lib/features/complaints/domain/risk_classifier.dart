import 'enums.dart';

/// Classifies a complaint's risk level from its category.
/// This is enforced in the domain layer — not just the UI.
class RiskClassifier {
  static const Map<ComplaintCategory, RiskClass> _riskMap = {
    ComplaintCategory.garbage: RiskClass.low,
    ComplaintCategory.blockedDrain: RiskClass.low,
    ComplaintCategory.pothole: RiskClass.medium,
    ComplaintCategory.waterlogging: RiskClass.medium,
    ComplaintCategory.sewage: RiskClass.medium,
    ComplaintCategory.streetlight: RiskClass.dangerous, // electrical hazard
    ComplaintCategory.other: RiskClass.low,
  };

  static RiskClass classify(ComplaintCategory category) =>
      _riskMap[category] ?? RiskClass.low;

  static bool isVolunteerSafe(ComplaintCategory category) =>
      classify(category).isVolunteerSafe;

  static bool isDangerous(ComplaintCategory category) =>
      classify(category) == RiskClass.dangerous;
}
