import '../domain/enums.dart';
import '../domain/models.dart';

/// Realistic Chennai seed data for demo mode.
/// 40 complaints across various wards, categories, and statuses.
abstract final class SeedData {
  // ── Seed wards ───────────────────────────────────────────────────────────
  static final List<Ward> wards = [
    const Ward(
      id: 'tondiarpet',
      name: 'Tondiarpet',
      nameTa: 'தண்டையார்பேட்டை',
      vulnerabilityIndex: 0.90,
      centroid: LatLng(13.1234, 80.2988),
    ),
    const Ward(
      id: 'perungudi',
      name: 'Perungudi',
      nameTa: 'பெருங்குடி',
      vulnerabilityIndex: 0.75,
      centroid: LatLng(12.9566, 80.2452),
    ),
    const Ward(
      id: 'kodambakkam',
      name: 'Kodambakkam',
      nameTa: 'கோடம்பாக்கம்',
      vulnerabilityIndex: 0.70,
      centroid: LatLng(13.0530, 80.2214),
    ),
    const Ward(
      id: 'velachery',
      name: 'Velachery',
      nameTa: 'வேளச்சேரி',
      vulnerabilityIndex: 0.55,
      centroid: LatLng(12.9815, 80.2180),
    ),
    const Ward(
      id: 'sholinganallur',
      name: 'Sholinganallur',
      nameTa: 'சோழிங்கநல்லூர்',
      vulnerabilityIndex: 0.45,
      centroid: LatLng(12.9010, 80.2278),
    ),
    const Ward(
      id: 't_nagar',
      name: 'T. Nagar',
      nameTa: 'தி. நகர்',
      vulnerabilityIndex: 0.35,
      centroid: LatLng(13.0418, 80.2341),
    ),
    const Ward(
      id: 'adyar',
      name: 'Adyar',
      nameTa: 'அடையாறு',
      vulnerabilityIndex: 0.30,
      centroid: LatLng(13.0012, 80.2565),
    ),
    const Ward(
      id: 'anna_nagar',
      name: 'Anna Nagar',
      nameTa: 'அண்ணா நகர்',
      vulnerabilityIndex: 0.25,
      centroid: LatLng(13.0850, 80.2101),
    ),
  ];

  // ── Seed users ───────────────────────────────────────────────────────────
  static final List<AppUser> users = [
    const AppUser(
      id: 'u-citizen-1',
      anonymousHandle: 'Citizen#4821',
      role: UserRole.citizen,
      wardId: 'tondiarpet',
      languagePref: 'en',
    ),
    const AppUser(
      id: 'u-volunteer-1',
      anonymousHandle: 'Volunteer#7193',
      role: UserRole.volunteer,
      wardId: 'perungudi',
      languagePref: 'en',
      volunteerHours: 24.5,
      badges: [BadgeType.earlyReporter, BadgeType.topVolunteer],
    ),
    const AppUser(
      id: 'u-moderator-1',
      anonymousHandle: 'Mod#2244',
      role: UserRole.moderator,
      wardId: 'kodambakkam',
      languagePref: 'en',
    ),
    const AppUser(
      id: 'u-partner-1',
      anonymousHandle: 'Partner#5500',
      role: UserRole.partner,
      wardId: 'velachery',
      languagePref: 'en',
      orgId: 'org-ngo-1',
    ),
    const AppUser(
      id: 'u-authority-1',
      anonymousHandle: 'Authority#9900',
      role: UserRole.authority,
      wardId: 'anna_nagar',
      languagePref: 'en',
      orgId: 'org-gcc-1',
    ),
    const AppUser(
      id: 'u-citizen-2',
      anonymousHandle: 'Citizen#3310',
      role: UserRole.citizen,
      wardId: 'velachery',
      languagePref: 'ta',
    ),
    const AppUser(
      id: 'u-citizen-3',
      anonymousHandle: 'Citizen#6677',
      role: UserRole.citizen,
      wardId: 'kodambakkam',
      languagePref: 'en',
    ),
  ];

  static AppUser userForRole(UserRole role) =>
      users.firstWhere((u) => u.role == role, orElse: () => users.first);

  // ── Seed organisations ───────────────────────────────────────────────────
  static final List<Organisation> organisations = [
    const Organisation(
      id: 'org-ngo-1',
      name: 'Chennai Green Force',
      type: OrgType.ngo,
      wardIds: ['tondiarpet', 'perungudi'],
      resolvedCount: 18,
      activeVolunteerCount: 42,
      avgResolutionDays: 4.2,
    ),
    const Organisation(
      id: 'org-rwa-1',
      name: 'Velachery Residents Association',
      type: OrgType.rwa,
      wardIds: ['velachery'],
      resolvedCount: 11,
      activeVolunteerCount: 19,
      avgResolutionDays: 5.0,
    ),
    const Organisation(
      id: 'org-nss-1',
      name: 'Anna University NSS',
      type: OrgType.nss,
      wardIds: ['kodambakkam', 'adyar'],
      resolvedCount: 25,
      activeVolunteerCount: 80,
      avgResolutionDays: 3.5,
    ),
    const Organisation(
      id: 'org-gcc-1',
      name: 'Greater Chennai Corporation',
      type: OrgType.authority,
      wardIds: [
        'tondiarpet',
        'perungudi',
        'kodambakkam',
        'velachery',
        'sholinganallur',
        't_nagar',
        'adyar',
        'anna_nagar',
      ],
      resolvedCount: 120,
      avgResolutionDays: 8.5,
    ),
    const Organisation(
      id: 'org-cmwssb-1',
      name: 'CMWSSB (Metro Water)',
      type: OrgType.authority,
      wardIds: [
        'tondiarpet',
        'perungudi',
        'kodambakkam',
        'velachery',
        'sholinganallur',
        't_nagar',
        'adyar',
        'anna_nagar',
      ],
      resolvedCount: 64,
      avgResolutionDays: 6.8,
    ),
  ];

  // ── Seed complaints (40 items) ───────────────────────────────────────────
  static List<Complaint> complaints() {
    final now = DateTime(2026, 11, 20);
    final c = <Complaint>[];

    Complaint make({
      required String id,
      required int seq,
      required ComplaintCategory category,
      required ComplaintStatus status,
      required String wardId,
      required LatLng location,
      required String reporterId,
      required DateTime createdAt,
      int supportCount = 0,
      bool escalated = false,
      int? severity,
      String? assignedOrgId,
      String? assignedAuthorityId,
    }) {
      final risk = category == ComplaintCategory.streetlight
          ? RiskClass.dangerous
          : (category == ComplaintCategory.pothole ||
                  category == ComplaintCategory.sewage ||
                  category == ComplaintCategory.waterlogging)
              ? RiskClass.medium
              : RiskClass.low;

      return Complaint(
        id: id,
        trackingId: 'WR-CHE-2026-${seq.toString().padLeft(6, '0')}',
        category: category,
        severity: severity ?? category.defaultSeverity,
        status: status,
        location: location,
        wardId: wardId,
        photos: [
          ComplaintPhoto(
            id: 'photo-$id',
            url: 'https://picsum.photos/seed/$id/400/300',
            source: PhotoSource.camera,
            capturedAt: createdAt,
          ),
        ],
        createdAt: createdAt,
        lastStatusChangeAt: createdAt.add(const Duration(days: 1)),
        reporterId: reporterId,
        supporterIds: List.generate(supportCount, (i) => 'u-supporter-$id-$i'),
        riskClass: risk,
        priorityScore: 55.0 + (seq % 35),
        escalated: escalated,
        reopenCount: 0,
        note: _noteFor(category),
        assignedOrgId: assignedOrgId,
        assignedAuthorityId: assignedAuthorityId,
        timeline: [
          StatusEvent(
            complaintId: id,
            status: ComplaintStatus.PENDING_REVIEW,
            at: createdAt,
            actorRole: 'citizen',
          ),
          if (status != ComplaintStatus.PENDING_REVIEW)
            StatusEvent(
              complaintId: id,
              status: ComplaintStatus.VERIFIED,
              at: createdAt.add(const Duration(hours: 4)),
              actorRole: 'moderator',
            ),
        ],
      );
    }

    c.add(make(
      id: 'c001',
      seq: 1,
      category: ComplaintCategory.sewage,
      status: ComplaintStatus.VERIFIED,
      wardId: 'tondiarpet',
      location: const LatLng(13.1234, 80.2988),
      reporterId: 'u-citizen-1',
      createdAt: now.subtract(const Duration(days: 10)),
      supportCount: 3,
      severity: 5,
    ));
    c.add(make(
      id: 'c002',
      seq: 2,
      category: ComplaintCategory.pothole,
      status: ComplaintStatus.ASSIGNED,
      wardId: 'tondiarpet',
      location: const LatLng(13.1240, 80.2990),
      reporterId: 'u-citizen-1',
      createdAt: now.subtract(const Duration(days: 8)),
      supportCount: 12,
      assignedAuthorityId: 'org-gcc-1',
    ));
    c.add(make(
      id: 'c003',
      seq: 3,
      category: ComplaintCategory.garbage,
      status: ComplaintStatus.PENDING_REVIEW,
      wardId: 'tondiarpet',
      location: const LatLng(13.1250, 80.3000),
      reporterId: 'u-citizen-2',
      createdAt: now.subtract(const Duration(days: 1)),
    ));
    c.add(make(
      id: 'c004',
      seq: 4,
      category: ComplaintCategory.streetlight,
      status: ComplaintStatus.VERIFIED,
      wardId: 'tondiarpet',
      location: const LatLng(13.1260, 80.2970),
      reporterId: 'u-citizen-1',
      createdAt: now.subtract(const Duration(days: 15)),
      escalated: true,
    ));
    c.add(make(
      id: 'c005',
      seq: 5,
      category: ComplaintCategory.waterlogging,
      status: ComplaintStatus.WORK_STARTED,
      wardId: 'tondiarpet',
      location: const LatLng(13.1270, 80.2980),
      reporterId: 'u-citizen-2',
      createdAt: now.subtract(const Duration(days: 20)),
      supportCount: 8,
      assignedAuthorityId: 'org-gcc-1',
    ));
    c.add(make(
      id: 'c006',
      seq: 6,
      category: ComplaintCategory.blockedDrain,
      status: ComplaintStatus.VERIFIED,
      wardId: 'perungudi',
      location: const LatLng(12.9566, 80.2452),
      reporterId: 'u-citizen-2',
      createdAt: now.subtract(const Duration(days: 5)),
      supportCount: 5,
    ));
    c.add(make(
      id: 'c007',
      seq: 7,
      category: ComplaintCategory.garbage,
      status: ComplaintStatus.SOLVED,
      wardId: 'perungudi',
      location: const LatLng(12.9570, 80.2460),
      reporterId: 'u-citizen-3',
      createdAt: now.subtract(const Duration(days: 30)),
      supportCount: 20,
      assignedOrgId: 'org-ngo-1',
    ));
    c.add(make(
      id: 'c008',
      seq: 8,
      category: ComplaintCategory.pothole,
      status: ComplaintStatus.ASSIGNED,
      wardId: 'perungudi',
      location: const LatLng(12.9580, 80.2470),
      reporterId: 'u-citizen-1',
      createdAt: now.subtract(const Duration(days: 12)),
      supportCount: 7,
      assignedAuthorityId: 'org-gcc-1',
    ));
    c.add(make(
      id: 'c009',
      seq: 9,
      category: ComplaintCategory.sewage,
      status: ComplaintStatus.PENDING_REVIEW,
      wardId: 'kodambakkam',
      location: const LatLng(13.0530, 80.2214),
      reporterId: 'u-citizen-3',
      createdAt: now.subtract(const Duration(days: 2)),
    ));
    c.add(make(
      id: 'c010',
      seq: 10,
      category: ComplaintCategory.streetlight,
      status: ComplaintStatus.REJECTED,
      wardId: 'kodambakkam',
      location: const LatLng(13.0540, 80.2220),
      reporterId: 'u-citizen-2',
      createdAt: now.subtract(const Duration(days: 6)),
    ));
    c.add(make(
      id: 'c011',
      seq: 11,
      category: ComplaintCategory.garbage,
      status: ComplaintStatus.WORK_STARTED,
      wardId: 'kodambakkam',
      location: const LatLng(13.0550, 80.2230),
      reporterId: 'u-citizen-1',
      createdAt: now.subtract(const Duration(days: 9)),
      supportCount: 15,
      assignedOrgId: 'org-nss-1',
    ));
    c.add(make(
      id: 'c012',
      seq: 12,
      category: ComplaintCategory.waterlogging,
      status: ComplaintStatus.VERIFIED,
      wardId: 'velachery',
      location: const LatLng(12.9815, 80.2180),
      reporterId: 'u-citizen-2',
      createdAt: now.subtract(const Duration(days: 4)),
      supportCount: 25,
    ));
    c.add(make(
      id: 'c013',
      seq: 13,
      category: ComplaintCategory.pothole,
      status: ComplaintStatus.AWAITING_CONFIRMATION,
      wardId: 'velachery',
      location: const LatLng(12.9820, 80.2190),
      reporterId: 'u-citizen-1',
      createdAt: now.subtract(const Duration(days: 25)),
      supportCount: 10,
    ));
    c.add(make(
      id: 'c014',
      seq: 14,
      category: ComplaintCategory.blockedDrain,
      status: ComplaintStatus.SOLVED,
      wardId: 'velachery',
      location: const LatLng(12.9830, 80.2200),
      reporterId: 'u-citizen-3',
      createdAt: now.subtract(const Duration(days: 45)),
      supportCount: 18,
      assignedOrgId: 'org-rwa-1',
    ));
    c.add(make(
      id: 'c015',
      seq: 15,
      category: ComplaintCategory.garbage,
      status: ComplaintStatus.PENDING_REVIEW,
      wardId: 'sholinganallur',
      location: const LatLng(12.9010, 80.2278),
      reporterId: 'u-citizen-2',
      createdAt: now.subtract(const Duration(days: 1)),
    ));
    c.add(make(
      id: 'c016',
      seq: 16,
      category: ComplaintCategory.pothole,
      status: ComplaintStatus.ASSIGNED,
      wardId: 'sholinganallur',
      location: const LatLng(12.9020, 80.2290),
      reporterId: 'u-citizen-1',
      createdAt: now.subtract(const Duration(days: 7)),
      supportCount: 6,
      assignedAuthorityId: 'org-gcc-1',
    ));
    c.add(make(
      id: 'c017',
      seq: 17,
      category: ComplaintCategory.streetlight,
      status: ComplaintStatus.VERIFIED,
      wardId: 't_nagar',
      location: const LatLng(13.0418, 80.2341),
      reporterId: 'u-citizen-3',
      createdAt: now.subtract(const Duration(days: 3)),
    ));
    c.add(make(
      id: 'c018',
      seq: 18,
      category: ComplaintCategory.garbage,
      status: ComplaintStatus.SOLVED,
      wardId: 't_nagar',
      location: const LatLng(13.0430, 80.2350),
      reporterId: 'u-citizen-2',
      createdAt: now.subtract(const Duration(days: 60)),
      supportCount: 300,
    ));
    c.add(make(
      id: 'c019',
      seq: 19,
      category: ComplaintCategory.sewage,
      status: ComplaintStatus.WORK_STARTED,
      wardId: 'adyar',
      location: const LatLng(13.0012, 80.2565),
      reporterId: 'u-citizen-1',
      createdAt: now.subtract(const Duration(days: 11)),
      supportCount: 4,
      assignedAuthorityId: 'org-cmwssb-1',
    ));
    c.add(make(
      id: 'c020',
      seq: 20,
      category: ComplaintCategory.blockedDrain,
      status: ComplaintStatus.PENDING_REVIEW,
      wardId: 'adyar',
      location: const LatLng(13.0020, 80.2575),
      reporterId: 'u-citizen-3',
      createdAt: now.subtract(const Duration(days: 2)),
    ));
    c.add(make(
      id: 'c021',
      seq: 21,
      category: ComplaintCategory.pothole,
      status: ComplaintStatus.ASSIGNED,
      wardId: 'anna_nagar',
      location: const LatLng(13.0850, 80.2101),
      reporterId: 'u-citizen-2',
      createdAt: now.subtract(const Duration(days: 6)),
      supportCount: 9,
      assignedAuthorityId: 'org-gcc-1',
    ));
    c.add(make(
      id: 'c022',
      seq: 22,
      category: ComplaintCategory.garbage,
      status: ComplaintStatus.VERIFIED,
      wardId: 'anna_nagar',
      location: const LatLng(13.0860, 80.2110),
      reporterId: 'u-citizen-1',
      createdAt: now.subtract(const Duration(days: 4)),
      supportCount: 2,
    ));

    final extras = [
      ('c023', 23, ComplaintCategory.waterlogging, ComplaintStatus.VERIFIED, 'tondiarpet', 13.1280, 80.3010, 6),
      ('c024', 24, ComplaintCategory.garbage, ComplaintStatus.PENDING_REVIEW, 'perungudi', 12.9590, 80.2480, 0),
      ('c025', 25, ComplaintCategory.pothole, ComplaintStatus.WORK_STARTED, 'kodambakkam', 13.0560, 80.2240, 11),
      ('c026', 26, ComplaintCategory.blockedDrain, ComplaintStatus.ASSIGNED, 'velachery', 12.9840, 80.2210, 3),
      ('c027', 27, ComplaintCategory.sewage, ComplaintStatus.PENDING_REVIEW, 'sholinganallur', 12.9030, 80.2300, 0),
      ('c028', 28, ComplaintCategory.streetlight, ComplaintStatus.VERIFIED, 'tondiarpet', 13.1290, 80.3020, 14),
      ('c029', 29, ComplaintCategory.garbage, ComplaintStatus.ASSIGNED, 't_nagar', 13.0440, 80.2360, 7),
      ('c030', 30, ComplaintCategory.pothole, ComplaintStatus.VERIFIED, 'adyar', 13.0030, 80.2585, 5),
      ('c031', 31, ComplaintCategory.waterlogging, ComplaintStatus.WORK_STARTED, 'anna_nagar', 13.0870, 80.2120, 8),
      ('c032', 32, ComplaintCategory.garbage, ComplaintStatus.SOLVED, 'perungudi', 12.9600, 80.2490, 22),
      ('c033', 33, ComplaintCategory.sewage, ComplaintStatus.VERIFIED, 'kodambakkam', 13.0570, 80.2250, 1),
      ('c034', 34, ComplaintCategory.pothole, ComplaintStatus.PENDING_REVIEW, 'velachery', 12.9850, 80.2220, 0),
      ('c035', 35, ComplaintCategory.blockedDrain, ComplaintStatus.ASSIGNED, 'tondiarpet', 13.1300, 80.3030, 9),
      ('c036', 36, ComplaintCategory.streetlight, ComplaintStatus.WORK_STARTED, 'sholinganallur', 12.9040, 80.2310, 2),
      ('c037', 37, ComplaintCategory.garbage, ComplaintStatus.VERIFIED, 'adyar', 13.0040, 80.2595, 4),
      ('c038', 38, ComplaintCategory.pothole, ComplaintStatus.ASSIGNED, 'anna_nagar', 13.0880, 80.2130, 6),
      ('c039', 39, ComplaintCategory.sewage, ComplaintStatus.PENDING_REVIEW, 't_nagar', 13.0450, 80.2370, 0),
      ('c040', 40, ComplaintCategory.waterlogging, ComplaintStatus.VERIFIED, 'perungudi', 12.9610, 80.2500, 3),
    ];

    for (final (id, seq, cat, st, ward, lat, lng, sup) in extras) {
      c.add(make(
        id: id,
        seq: seq,
        category: cat,
        status: st,
        wardId: ward,
        location: LatLng(lat, lng),
        reporterId: 'u-citizen-1',
        createdAt: now.subtract(Duration(days: seq % 20 + 1)),
        supportCount: sup,
        escalated: id == 'c028',
        assignedOrgId: (st == ComplaintStatus.ASSIGNED || st == ComplaintStatus.WORK_STARTED) &&
                (cat == ComplaintCategory.garbage || cat == ComplaintCategory.blockedDrain)
            ? 'org-ngo-1'
            : null,
        assignedAuthorityId: (st == ComplaintStatus.ASSIGNED || st == ComplaintStatus.WORK_STARTED) &&
                !(cat == ComplaintCategory.garbage || cat == ComplaintCategory.blockedDrain)
            ? 'org-gcc-1'
            : null,
      ));
    }

    return c;
  }

  // ── Seed volunteer tasks (all volunteer-safe, supervised by partner org) ──
  static List<Task> tasks() {
    final now = DateTime(2026, 11, 20);
    return [
      Task(
        id: 't001',
        complaintId: 'c006', // blockedDrain in Perungudi (low risk)
        partnerOrgId: 'org-ngo-1',
        requirements: const ['gloves', 'spade', 'trash bags'],
        createdAt: now.subtract(const Duration(days: 4)),
        volunteerIds: const ['u-volunteer-1'],
        supervisorId: 'u-partner-1',
        estimatedHours: 2.5,
      ),
      Task(
        id: 't002',
        complaintId: 'c011', // garbage in Kodambakkam (low risk)
        partnerOrgId: 'org-nss-1',
        requirements: const ['gloves', 'broom', 'bags'],
        createdAt: now.subtract(const Duration(days: 3)),
        supervisorId: 'u-partner-1',
        estimatedHours: 2.0,
      ),
      Task(
        id: 't003',
        complaintId: 'c022', // garbage in Anna Nagar (low risk)
        partnerOrgId: 'org-ngo-1',
        requirements: const ['gloves', 'trash bags'],
        createdAt: now.subtract(const Duration(days: 2)),
        supervisorId: 'u-partner-1',
        estimatedHours: 1.5,
      ),
      Task(
        id: 't004',
        complaintId: 'c026', // blockedDrain in Velachery (low risk)
        partnerOrgId: 'org-rwa-1',
        requirements: const ['gloves', 'rake'],
        createdAt: now.subtract(const Duration(days: 1)),
        supervisorId: 'u-partner-1',
        estimatedHours: 2.0,
      ),
      Task(
        id: 't005',
        complaintId: 'c037', // garbage in Adyar (low risk)
        partnerOrgId: 'org-nss-1',
        requirements: const ['gloves', 'bags'],
        createdAt: now.subtract(const Duration(days: 1)),
        supervisorId: 'u-partner-1',
        estimatedHours: 2.0,
      ),
    ];
  }

  static String _noteFor(ComplaintCategory cat) => switch (cat) {
    ComplaintCategory.pothole => 'Large pothole causing accidents',
    ComplaintCategory.garbage => 'Uncollected garbage for over a week',
    ComplaintCategory.sewage => 'Sewage overflow on main road',
    ComplaintCategory.waterlogging => 'Road flooded after rain, knee-deep',
    ComplaintCategory.blockedDrain => 'Drain blocked with debris',
    ComplaintCategory.streetlight => 'Streetlight out for 3 days',
    ComplaintCategory.other => 'Civic issue reported',
  };
}
