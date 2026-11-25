import 'package:equatable/equatable.dart';
import 'enums.dart';

/// Geographic coordinate
class LatLng extends Equatable {
  const LatLng(this.latitude, this.longitude);
  final double latitude;
  final double longitude;

  LatLng copyWith({double? latitude, double? longitude}) =>
      LatLng(latitude ?? this.latitude, longitude ?? this.longitude);

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

/// Ward / geographic area
class Ward extends Equatable {
  const Ward({
    required this.id,
    required this.name,
    required this.nameTa,
    required this.vulnerabilityIndex,
    required this.centroid,
  });

  final String id;
  final String name;
  final String nameTa;

  /// 0.0 (affluent) – 1.0 (most vulnerable), used in priority equity weighting
  final double vulnerabilityIndex;
  final LatLng centroid;

  Ward copyWith({
    String? id,
    String? name,
    String? nameTa,
    double? vulnerabilityIndex,
    LatLng? centroid,
  }) =>
      Ward(
        id: id ?? this.id,
        name: name ?? this.name,
        nameTa: nameTa ?? this.nameTa,
        vulnerabilityIndex: vulnerabilityIndex ?? this.vulnerabilityIndex,
        centroid: centroid ?? this.centroid,
      );

  @override
  List<Object?> get props => [id];
}

/// An uploaded photo attached to a complaint
class ComplaintPhoto extends Equatable {
  const ComplaintPhoto({
    required this.id,
    required this.url,
    required this.source,
    required this.capturedAt,
    this.isGalleryFlagged = false,
    this.exifAge,
  });

  final String id;

  /// Local file path (demo mode) or remote URL (Supabase)
  final String url;
  final PhotoSource source;
  final DateTime capturedAt;

  /// True if gallery photo with EXIF timestamp > 24 h old
  final bool isGalleryFlagged;

  /// Duration between EXIF timestamp and report time (null for camera photos)
  final Duration? exifAge;

  ComplaintPhoto copyWith({
    String? id,
    String? url,
    PhotoSource? source,
    DateTime? capturedAt,
    bool? isGalleryFlagged,
    Duration? exifAge,
  }) =>
      ComplaintPhoto(
        id: id ?? this.id,
        url: url ?? this.url,
        source: source ?? this.source,
        capturedAt: capturedAt ?? this.capturedAt,
        isGalleryFlagged: isGalleryFlagged ?? this.isGalleryFlagged,
        exifAge: exifAge ?? this.exifAge,
      );

  @override
  List<Object?> get props => [id];
}

/// A single entry in the complaint's status history timeline
class StatusEvent extends Equatable {
  const StatusEvent({
    required this.complaintId,
    required this.status,
    required this.at,
    required this.actorRole,
    this.note,
  });

  final String complaintId;
  final ComplaintStatus status;
  final DateTime at;

  /// Role label shown publicly (never personal name)
  final String actorRole;
  final String? note;

  StatusEvent copyWith({
    String? complaintId,
    ComplaintStatus? status,
    DateTime? at,
    String? actorRole,
    String? note,
  }) =>
      StatusEvent(
        complaintId: complaintId ?? this.complaintId,
        status: status ?? this.status,
        at: at ?? this.at,
        actorRole: actorRole ?? this.actorRole,
        note: note ?? this.note,
      );

  @override
  List<Object?> get props => [complaintId, status, at];
}

/// Core complaint entity – never expose directly to public; use PublicComplaintDto
class Complaint extends Equatable {
  const Complaint({
    required this.id,
    required this.trackingId,
    required this.category,
    required this.severity,
    required this.status,
    required this.location,
    required this.wardId,
    required this.photos,
    required this.createdAt,
    required this.lastStatusChangeAt,
    required this.reporterId,
    required this.supporterIds,
    required this.riskClass,
    required this.priorityScore,
    required this.escalated,
    required this.reopenCount,
    this.note,
    this.onBehalfOf,
    this.assignedOrgId,
    this.assignedAuthorityId,
    this.rejectionReason,
    this.rejectionNote,
    this.mergedIntoId,
    this.afterPhotos = const [],
    this.timeline = const [],
  });

  final String id;
  final String trackingId;
  final ComplaintCategory category;

  /// Severity 1 (cosmetic) – 5 (dangerous)
  final int severity;
  final ComplaintStatus status;
  final LatLng location;
  final String wardId;
  final List<ComplaintPhoto> photos;
  final DateTime createdAt;
  final DateTime lastStatusChangeAt;

  // Private fields — never in PublicComplaintDto
  final String reporterId;
  final List<String> supporterIds;

  final RiskClass riskClass;
  final double priorityScore;
  final bool escalated;
  final int reopenCount;
  final String? note;
  final String? onBehalfOf; // anonymous handle of real reporter
  final String? assignedOrgId;
  final String? assignedAuthorityId;
  final RejectionReason? rejectionReason;
  final String? rejectionNote;
  final String? mergedIntoId;
  final List<ComplaintPhoto> afterPhotos;
  final List<StatusEvent> timeline;

  int get supportCount => supporterIds.length;

  bool get isVolunteerTask => riskClass.isVolunteerSafe && assignedOrgId != null;

  Complaint copyWith({
    String? id,
    String? trackingId,
    ComplaintCategory? category,
    int? severity,
    ComplaintStatus? status,
    LatLng? location,
    String? wardId,
    List<ComplaintPhoto>? photos,
    DateTime? createdAt,
    DateTime? lastStatusChangeAt,
    String? reporterId,
    List<String>? supporterIds,
    RiskClass? riskClass,
    double? priorityScore,
    bool? escalated,
    int? reopenCount,
    String? note,
    String? onBehalfOf,
    String? assignedOrgId,
    String? assignedAuthorityId,
    RejectionReason? rejectionReason,
    String? rejectionNote,
    String? mergedIntoId,
    List<ComplaintPhoto>? afterPhotos,
    List<StatusEvent>? timeline,
  }) =>
      Complaint(
        id: id ?? this.id,
        trackingId: trackingId ?? this.trackingId,
        category: category ?? this.category,
        severity: severity ?? this.severity,
        status: status ?? this.status,
        location: location ?? this.location,
        wardId: wardId ?? this.wardId,
        photos: photos ?? this.photos,
        createdAt: createdAt ?? this.createdAt,
        lastStatusChangeAt: lastStatusChangeAt ?? this.lastStatusChangeAt,
        reporterId: reporterId ?? this.reporterId,
        supporterIds: supporterIds ?? this.supporterIds,
        riskClass: riskClass ?? this.riskClass,
        priorityScore: priorityScore ?? this.priorityScore,
        escalated: escalated ?? this.escalated,
        reopenCount: reopenCount ?? this.reopenCount,
        note: note ?? this.note,
        onBehalfOf: onBehalfOf ?? this.onBehalfOf,
        assignedOrgId: assignedOrgId ?? this.assignedOrgId,
        assignedAuthorityId: assignedAuthorityId ?? this.assignedAuthorityId,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        rejectionNote: rejectionNote ?? this.rejectionNote,
        mergedIntoId: mergedIntoId ?? this.mergedIntoId,
        afterPhotos: afterPhotos ?? this.afterPhotos,
        timeline: timeline ?? this.timeline,
      );

  @override
  List<Object?> get props => [id];
}

/// Safe public view of a complaint — no PII
class PublicComplaintDto extends Equatable {
  const PublicComplaintDto({
    required this.id,
    required this.trackingId,
    required this.category,
    required this.severity,
    required this.status,
    required this.location,
    required this.wardId,
    required this.photoUrls,
    required this.createdAt,
    required this.lastStatusChangeAt,
    required this.supportCount,
    required this.riskClass,
    required this.priorityScore,
    required this.escalated,
    required this.reopenCount,
    required this.timeline,
    this.note,
    this.afterPhotoUrls = const [],
    this.isGalleryFlagged = false,
  });

  final String id;
  final String trackingId;
  final ComplaintCategory category;
  final int severity;
  final ComplaintStatus status;
  final LatLng location;
  final String wardId;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime lastStatusChangeAt;
  final int supportCount;
  final RiskClass riskClass;
  final double priorityScore;
  final bool escalated;
  final int reopenCount;
  final List<StatusEvent> timeline;
  final String? note;
  final List<String> afterPhotoUrls;
  final bool isGalleryFlagged;

  /// Factory: strips all PII from a full Complaint
  factory PublicComplaintDto.fromComplaint(Complaint c) => PublicComplaintDto(
        id: c.id,
        trackingId: c.trackingId,
        category: c.category,
        severity: c.severity,
        status: c.status,
        location: c.location,
        wardId: c.wardId,
        photoUrls: c.photos.map((p) => p.url).toList(),
        createdAt: c.createdAt,
        lastStatusChangeAt: c.lastStatusChangeAt,
        supportCount: c.supportCount,
        riskClass: c.riskClass,
        priorityScore: c.priorityScore,
        escalated: c.escalated,
        reopenCount: c.reopenCount,
        timeline: c.timeline,
        note: c.note,
        afterPhotoUrls: c.afterPhotos.map((p) => p.url).toList(),
        isGalleryFlagged: c.photos.any((p) => p.isGalleryFlagged),
      );

  @override
  List<Object?> get props => [id];
}

/// App user — private, never serialised to public API
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.anonymousHandle,
    required this.role,
    required this.wardId,
    required this.languagePref,
    this.orgId,
    this.email,
    this.volunteerHours = 0.0,
    this.badges = const [],
    this.reportCount = 0,
    this.location,
  });

  final String id;
  final String anonymousHandle;
  final UserRole role;
  final String wardId;
  final String languagePref; // 'en' or 'ta'
  final String? orgId;

  // Private — never in public DTOs
  final String? email;
  final double volunteerHours;
  final List<BadgeType> badges;
  final int reportCount;
  final LatLng? location;

  AppUser copyWith({
    String? id,
    String? anonymousHandle,
    UserRole? role,
    String? wardId,
    String? languagePref,
    String? orgId,
    String? email,
    double? volunteerHours,
    List<BadgeType>? badges,
    int? reportCount,
    LatLng? location,
  }) =>
      AppUser(
        id: id ?? this.id,
        anonymousHandle: anonymousHandle ?? this.anonymousHandle,
        role: role ?? this.role,
        wardId: wardId ?? this.wardId,
        languagePref: languagePref ?? this.languagePref,
        orgId: orgId ?? this.orgId,
        email: email ?? this.email,
        volunteerHours: volunteerHours ?? this.volunteerHours,
        badges: badges ?? this.badges,
        reportCount: reportCount ?? this.reportCount,
        location: location ?? this.location,
      );

  @override
  List<Object?> get props => [id];
}

/// Organisation (NGO, RWA, NSS, NCC, Authority)
class Organisation extends Equatable {
  const Organisation({
    required this.id,
    required this.type,
    required this.name,
    required this.wardIds,
    this.resolvedCount = 0,
    this.activeVolunteerCount = 0,
    this.avgResolutionDays = 0.0,
  });

  final String id;
  final OrgType type;
  final String name;
  final List<String> wardIds;
  final int resolvedCount;
  final int activeVolunteerCount;
  final double avgResolutionDays;

  Organisation copyWith({
    String? id,
    OrgType? type,
    String? name,
    List<String>? wardIds,
    int? resolvedCount,
    int? activeVolunteerCount,
    double? avgResolutionDays,
  }) =>
      Organisation(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        wardIds: wardIds ?? this.wardIds,
        resolvedCount: resolvedCount ?? this.resolvedCount,
        activeVolunteerCount: activeVolunteerCount ?? this.activeVolunteerCount,
        avgResolutionDays: avgResolutionDays ?? this.avgResolutionDays,
      );

  @override
  List<Object?> get props => [id];
}

/// Volunteer task (derived from a complaint)
class Task extends Equatable {
  const Task({
    required this.id,
    required this.complaintId,
    required this.partnerOrgId,
    required this.requirements,
    required this.createdAt,
    this.volunteerIds = const [],
    this.supervisorId,
    this.completedAt,
    this.estimatedHours = 2.0,
  });

  final String id;
  final String complaintId;
  final String partnerOrgId;
  final List<String> requirements; // e.g. ['gloves', 'bags']
  final DateTime createdAt;
  final List<String> volunteerIds;
  final String? supervisorId;
  final DateTime? completedAt;
  final double estimatedHours;

  bool get isCompleted => completedAt != null;

  Task copyWith({
    String? id,
    String? complaintId,
    String? partnerOrgId,
    List<String>? requirements,
    DateTime? createdAt,
    List<String>? volunteerIds,
    String? supervisorId,
    DateTime? completedAt,
    double? estimatedHours,
  }) =>
      Task(
        id: id ?? this.id,
        complaintId: complaintId ?? this.complaintId,
        partnerOrgId: partnerOrgId ?? this.partnerOrgId,
        requirements: requirements ?? this.requirements,
        createdAt: createdAt ?? this.createdAt,
        volunteerIds: volunteerIds ?? this.volunteerIds,
        supervisorId: supervisorId ?? this.supervisorId,
        completedAt: completedAt ?? this.completedAt,
        estimatedHours: estimatedHours ?? this.estimatedHours,
      );

  @override
  List<Object?> get props => [id];
}

/// Closure confirmation from a user
class Confirmation extends Equatable {
  const Confirmation({
    required this.id,
    required this.complaintId,
    required this.userId,
    required this.kind,
    required this.approved,
    required this.at,
    required this.userLocation,
    this.reason,
  });

  final String id;
  final String complaintId;
  final String userId;
  final ConfirmationKind kind;
  final bool approved;
  final DateTime at;
  final LatLng userLocation;
  final String? reason; // reason for rejection

  Confirmation copyWith({
    String? id,
    String? complaintId,
    String? userId,
    ConfirmationKind? kind,
    bool? approved,
    DateTime? at,
    LatLng? userLocation,
    String? reason,
  }) =>
      Confirmation(
        id: id ?? this.id,
        complaintId: complaintId ?? this.complaintId,
        userId: userId ?? this.userId,
        kind: kind ?? this.kind,
        approved: approved ?? this.approved,
        at: at ?? this.at,
        userLocation: userLocation ?? this.userLocation,
        reason: reason ?? this.reason,
      );

  @override
  List<Object?> get props => [id];
}

/// NSS volunteer certificate
class Certificate extends Equatable {
  const Certificate({
    required this.id,
    required this.userId,
    required this.anonymousHandle,
    required this.orgId,
    required this.hours,
    required this.issuedAt,
    required this.verificationCode,
    this.pdfPath,
  });

  final String id;
  final String userId;
  final String anonymousHandle;
  final String orgId;
  final double hours;
  final DateTime issuedAt;

  /// Unique 8-char alphanumeric code for external verification
  final String verificationCode;
  final String? pdfPath;

  Certificate copyWith({
    String? id,
    String? userId,
    String? anonymousHandle,
    String? orgId,
    double? hours,
    DateTime? issuedAt,
    String? verificationCode,
    String? pdfPath,
  }) =>
      Certificate(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        anonymousHandle: anonymousHandle ?? this.anonymousHandle,
        orgId: orgId ?? this.orgId,
        hours: hours ?? this.hours,
        issuedAt: issuedAt ?? this.issuedAt,
        verificationCode: verificationCode ?? this.verificationCode,
        pdfPath: pdfPath ?? this.pdfPath,
      );

  @override
  List<Object?> get props => [id];
}

/// Offline queued draft report
class DraftReport extends Equatable {
  const DraftReport({
    required this.id,
    required this.category,
    required this.severity,
    required this.location,
    required this.wardId,
    required this.photoPaths,
    required this.createdAt,
    required this.reporterId,
    this.note,
    this.onBehalfOf,
    this.photoSources = const [],
    this.voiceNotePath,
  });

  final String id;
  final ComplaintCategory category;
  final int severity;
  final LatLng location;
  final String wardId;
  final List<String> photoPaths;
  final DateTime createdAt;
  final String reporterId;
  final String? note;
  final String? onBehalfOf;
  final List<PhotoSource> photoSources;
  final String? voiceNotePath;

  @override
  List<Object?> get props => [id];
}
