// ignore_for_file: constant_identifier_names

enum ComplaintStatus {
  PENDING_REVIEW,
  REJECTED,
  VERIFIED,
  ASSIGNED,
  WORK_STARTED,
  AWAITING_CONFIRMATION,
  SOLVED,
  REOPENED;

  String get displayName {
    switch (this) {
      case PENDING_REVIEW:
        return 'Pending Review';
      case REJECTED:
        return 'Rejected';
      case VERIFIED:
        return 'Verified';
      case ASSIGNED:
        return 'Assigned';
      case WORK_STARTED:
        return 'Work Started';
      case AWAITING_CONFIRMATION:
        return 'Awaiting Confirmation';
      case SOLVED:
        return 'Problem Solved';
      case REOPENED:
        return 'Reopened';
    }
  }

  bool get isTerminal => this == REJECTED || this == SOLVED;
  bool get isPublic => this != PENDING_REVIEW;
}

enum ComplaintCategory {
  pothole,
  garbage,
  sewage,
  waterlogging,
  blockedDrain,
  streetlight,
  other;

  String get displayName {
    switch (this) {
      case pothole:
        return 'Pothole';
      case garbage:
        return 'Garbage';
      case sewage:
        return 'Sewage Leak';
      case waterlogging:
        return 'Waterlogging';
      case blockedDrain:
        return 'Blocked Drain';
      case streetlight:
        return 'Streetlight / Electrical';
      case other:
        return 'Other';
    }
  }

  /// Default severity (1–5) for priority scoring
  int get defaultSeverity {
    switch (this) {
      case sewage:
      case waterlogging:
        return 5;
      case pothole:
      case blockedDrain:
        return 4;
      case streetlight:
        return 4;
      case garbage:
        return 3;
      case other:
        return 2;
    }
  }
}

enum RiskClass {
  low,
  medium,
  dangerous;

  bool get isVolunteerSafe => this == low || this == medium;
}

enum UserRole {
  citizen,
  volunteer,
  moderator,
  partner,
  authority;

  String get displayName {
    switch (this) {
      case citizen:
        return 'Citizen';
      case volunteer:
        return 'Volunteer';
      case moderator:
        return 'Moderator';
      case partner:
        return 'Partner';
      case authority:
        return 'Authority';
    }
  }
}

enum OrgType { ngo, rwa, nss, ncc, authority }

enum ConfirmationKind { reporter, nearby }

enum PhotoSource {
  camera,
  gallery;

  bool get requiresLiveLocation => this == camera;
}

enum RejectionReason {
  fakePhoto,
  personalComplaint,
  notCivicIssue,
  other;

  String get displayName {
    switch (this) {
      case fakePhoto:
        return 'Fake or irrelevant photo';
      case personalComplaint:
        return 'Personal complaint';
      case notCivicIssue:
        return 'Not a civic issue';
      case other:
        return 'Other';
    }
  }
}

enum BadgeType {
  earlyReporter,
  topVolunteer,
  neighbourhoodHero;

  String get displayName {
    switch (this) {
      case earlyReporter:
        return 'Early Reporter';
      case topVolunteer:
        return 'Top Volunteer';
      case neighbourhoodHero:
        return 'Neighbourhood Hero';
    }
  }
}
