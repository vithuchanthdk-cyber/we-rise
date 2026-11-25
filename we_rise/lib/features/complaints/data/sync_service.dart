import 'package:uuid/uuid.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/priority_calculator.dart';
import '../domain/repositories.dart';
import '../domain/risk_classifier.dart';
import '../domain/tracking_id_service.dart';

/// Drains queued offline [DraftReport]s into [ComplaintRepository] when online.
class SyncService {
  SyncService({
    required this.queueRepository,
    required this.complaintRepository,
    PriorityCalculator? priorityCalculator,
  }) : _priorityCalculator = priorityCalculator ?? const PriorityCalculator();

  final OfflineQueueRepository queueRepository;
  final ComplaintRepository complaintRepository;
  final PriorityCalculator _priorityCalculator;
  static const _uuid = Uuid();

  Future<int> syncPending() async {
    final drafts = await queueRepository.getPendingDrafts();
    var synced = 0;

    for (final draft in drafts) {
      final seq = await complaintRepository.nextSequenceNumber();
      final trackingId = TrackingIdService.generate(
        sequence: seq,
        year: draft.createdAt.year,
      );
      final risk = RiskClassifier.classify(draft.category);
      final photos = <ComplaintPhoto>[];
      for (var i = 0; i < draft.photoPaths.length; i++) {
        final src = i < draft.photoSources.length
            ? draft.photoSources[i]
            : PhotoSource.camera;
        photos.add(
          ComplaintPhoto(
            id: _uuid.v4(),
            url: draft.photoPaths[i],
            source: src,
            capturedAt: draft.createdAt,
          ),
        );
      }

      final id = _uuid.v4();
      final base = Complaint(
        id: id,
        trackingId: trackingId,
        category: draft.category,
        severity: draft.severity,
        status: ComplaintStatus.PENDING_REVIEW,
        location: draft.location,
        wardId: draft.wardId,
        photos: photos,
        createdAt: draft.createdAt,
        lastStatusChangeAt: draft.createdAt,
        reporterId: draft.reporterId,
        supporterIds: const [],
        riskClass: risk,
        priorityScore: 0,
        escalated: false,
        reopenCount: 0,
        note: draft.note,
        onBehalfOf: draft.onBehalfOf,
        timeline: [
          StatusEvent(
            complaintId: id,
            status: ComplaintStatus.PENDING_REVIEW,
            at: draft.createdAt,
            actorRole: 'citizen',
          ),
        ],
      );

      final scored = base.copyWith(
        priorityScore:
            _priorityCalculator.score(base, recurrenceCount: 0).total,
      );

      await complaintRepository.create(scored);
      await queueRepository.removeDraft(draft.id);
      synced++;
    }

    return synced;
  }
}
