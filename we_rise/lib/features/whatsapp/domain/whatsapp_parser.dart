import 'package:uuid/uuid.dart';
import '../../complaints/data/ai_category_service.dart';
import '../../complaints/data/seed_data.dart';
import '../../complaints/domain/enums.dart';
import '../../complaints/domain/models.dart';
import '../../complaints/domain/priority_calculator.dart';
import '../../complaints/domain/risk_classifier.dart';
import '../../complaints/domain/tracking_id_service.dart';

/// Parses incoming WhatsApp text messages (English or Tamil) into a
/// [Complaint] starting in [ComplaintStatus.PENDING_REVIEW].
/// Zero external network calls in demo mode.
class WhatsAppParser {
  static const _uuid = Uuid();

  static Complaint parseToComplaint({
    required String message,
    required String senderToken,
    required int sequenceNumber,
    DateTime? now,
  }) {
    final ts = now ?? DateTime.now();
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('WhatsApp message cannot be empty.');
    }

    final category = MockAiCategoryService.suggest(note: trimmed);
    final ward = _detectWard(trimmed);
    final risk = RiskClassifier.classify(category);
    final id = _uuid.v4();
    final trackingId = TrackingIdService.generate(
      sequence: sequenceNumber,
      year: ts.year,
    );

    final base = Complaint(
      id: id,
      trackingId: trackingId,
      category: category,
      severity: category.defaultSeverity,
      status: ComplaintStatus.PENDING_REVIEW,
      location: ward.centroid,
      wardId: ward.id,
      photos: const [],
      createdAt: ts,
      lastStatusChangeAt: ts,
      reporterId: 'wa-$senderToken',
      supporterIds: const [],
      riskClass: risk,
      priorityScore: 0,
      escalated: false,
      reopenCount: 0,
      note: '[WhatsApp] $trimmed',
      onBehalfOf: 'WhatsApp intake ($senderToken)',
      timeline: [
        StatusEvent(
          complaintId: id,
          status: ComplaintStatus.PENDING_REVIEW,
          at: ts,
          actorRole: 'whatsapp_intake',
          note: 'Received via WhatsApp intake.',
        ),
      ],
    );

    final score =
        const PriorityCalculator().score(base, recurrenceCount: 0).total;
    return base.copyWith(priorityScore: score);
  }

  static Ward _detectWard(String text) {
    final lower = text.toLowerCase();
    for (final w in SeedData.wards) {
      if (lower.contains(w.name.toLowerCase()) ||
          lower.contains(w.id.toLowerCase()) ||
          text.contains(w.nameTa)) {
        return w;
      }
    }
    return SeedData.wards.first; // Default to Tondiarpet if unspecified
  }
}
