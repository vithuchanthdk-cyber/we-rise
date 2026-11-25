import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/complaints/domain/risk_classifier.dart';
import 'package:we_rise/features/complaints/domain/routing_engine.dart';

void main() {
  group('RoutingEngine — dangerous categories', () {
    test('streetlight routes to authority only, volunteers never allowed', () {
      final risk = RiskClassifier.classify(ComplaintCategory.streetlight);
      final result = RoutingEngine.route(ComplaintCategory.streetlight, risk);
      expect(result.isAuthority, isTrue);
      expect(
        result.volunteersAllowed,
        isFalse,
        reason: 'Electrical faults are dangerous; volunteers must never be assigned',
      );
    });

    test('assertVolunteerNeverAssignedToDangerous throws StateError', () {
      expect(
        () => RoutingEngine.assertVolunteerNeverAssignedToDangerous(
          RiskClass.dangerous,
          true,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('RoutingEngine — infrastructure', () {
    test('pothole routes to authority', () {
      final risk = RiskClassifier.classify(ComplaintCategory.pothole);
      final result = RoutingEngine.route(ComplaintCategory.pothole, risk);
      expect(result.isAuthority, isTrue);
    });

    test('sewage routes to authority', () {
      final risk = RiskClassifier.classify(ComplaintCategory.sewage);
      final result = RoutingEngine.route(ComplaintCategory.sewage, risk);
      expect(result.isAuthority, isTrue);
    });

    test('waterlogging routes to authority', () {
      final risk = RiskClassifier.classify(ComplaintCategory.waterlogging);
      final result = RoutingEngine.route(ComplaintCategory.waterlogging, risk);
      expect(result.isAuthority, isTrue);
    });
  });

  group('RoutingEngine — partner/volunteer eligible', () {
    test('garbage allows volunteers with partner org', () {
      final risk = RiskClassifier.classify(ComplaintCategory.garbage);
      final result = RoutingEngine.route(ComplaintCategory.garbage, risk);
      expect(result.volunteersAllowed, isTrue);
      expect(result.isAuthority, isFalse);
    });

    test('blockedDrain allows volunteers', () {
      final risk = RiskClassifier.classify(ComplaintCategory.blockedDrain);
      final result = RoutingEngine.route(ComplaintCategory.blockedDrain, risk);
      expect(result.volunteersAllowed, isTrue);
    });
  });

  group('RiskClassifier', () {
    test('streetlight is dangerous', () {
      expect(
        RiskClassifier.classify(ComplaintCategory.streetlight),
        RiskClass.dangerous,
      );
    });

    test('pothole is medium', () {
      expect(
        RiskClassifier.classify(ComplaintCategory.pothole),
        RiskClass.medium,
      );
    });

    test('garbage is low', () {
      expect(
        RiskClassifier.classify(ComplaintCategory.garbage),
        RiskClass.low,
      );
    });
  });
}
