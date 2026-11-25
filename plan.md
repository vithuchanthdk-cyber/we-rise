# WE RISE: Implementation Plan

Status legend: [ ] todo, [~] in progress, [x] done

## 0. Decisions
- Flutter + Dart, Android-first, Riverpod, go_router, feature-first, repository pattern
- Demo mode with seeded local data; Supabase-ready interfaces (free tier, no Firebase)
- OSM via flutter_map (no API key), English + Tamil
- Zero budget: free to build, host, distribute (GitHub Releases, Supabase free tier)

## Change Requests (approved 2026-11-24)

### Change 1: Photo upload — camera AND gallery
- Report flow: "Take photo" (camera) + "Choose from gallery" (Android Photo Picker, no READ_MEDIA_IMAGES)
- Up to 3 photos per report; compress on-device (max 1600 px, JPEG ~80, < 400 KB)
- Strip EXIF personal data; keep only app-recorded location/time
- Gallery photos: location from live GPS; warn + flag moderator if EXIF timestamp > 24 h old
- After-photos (closure): live camera ONLY; 50 m GPS check; no gallery
- Upload progress, retry on failure, offline queue → sync on reconnect
- Widget tests for photo picker flow (mock picker)

### Change 2: Free backend — Supabase instead of Firebase
- Demo mode: no keys required (in-memory/Hive)
- Production mode: Supabase free tier (email/Google sign-in, no phone OTP)
- Postgres + Row Level Security; Supabase Storage for photos
- Real Supabase repositories behind existing abstract interfaces
- SQL migrations in /supabase/migrations; RLS policies:
  - Public reads → anonymous fields only (no names/phones)
  - Only moderators can set VERIFIED/REJECTED
  - Closure rule enforced server-side via Postgres function
- Auto-escalation, tracking-ID generation, priority recalc via pg_cron or Edge Functions
- Keys via --dart-define (SUPABASE_URL, SUPABASE_ANON_KEY); never committed
- docs/supabase_setup.md with step-by-step setup

### Change 3: Free distribution — Milestone 8
See Milestone 8 below.

### Kept from original spec
- In-app "Delete my account and data" in Settings
- Report/abuse and block-user on every complaint
- Privacy Policy and Terms screens in-app + docs/privacy_policy.md
- Skip Play Console / Play Store documents

---

## Milestone 1: Foundation
- [x] flutter create (android, ios), folder structure, lints
- [x] Theme (light/dark), colours, typography (Inter + Noto Sans Tamil), shared components
- [x] Localisation setup (en, ta) and language onboarding
- [x] Router, bottom navigation, role picker (demo)
- [x] Domain models, enums, status state machine + tests

### Sub-tasks
- [x] 1.1  flutter create --platforms=android,ios we_rise; applicationId = com.werise.chennai
- [x] 1.2  Remove counter app; analysis_options.yaml strict lints
- [x] 1.3  pubspec.yaml: flutter_riverpod, riverpod_annotation, go_router, flutter_map, latlong2,
           geolocator, image_picker, speech_to_text, hive_flutter, path_provider,
           flutter_image_compress, supabase_flutter, flutter_localizations, intl, pdf,
           share_plus, permission_handler, cached_network_image, build_runner
- [x] 1.4  Feature-first folder skeleton
- [x] 1.5  AppTheme light+dark
- [x] 1.6  Shared components: WeRiseButton, WeRiseCard, StatusChip, PriorityBadge, OfflineBanner
- [x] 1.7  Localisation files: app_localizations_en.dart + app_localizations_ta.dart
- [x] 1.8  Language-select onboarding screen
- [x] 1.9  AppRouter (go_router shell): bottom nav Map / Report / My Reports / Volunteer / Profile
- [x] 1.10 Role-picker screen (demo): Citizen / Volunteer / Moderator / Partner / Authority
- [x] 1.11 Domain models (immutable, hand-written copyWith):
           User, Complaint, StatusEvent, Task, Confirmation, Organisation, Certificate, Ward
- [x] 1.12 Enums: ComplaintStatus, ComplaintCategory, RiskClass, UserRole, OrgType,
           ConfirmationKind, PhotoSource, RejectionReason, BadgeType
- [x] 1.13 StatusMachine: explicit allowed-transition map; IllegalTransitionException
- [x] 1.14 Unit tests: all legal + illegal state transitions
- [x] 1.15 Permission rationale screens (Location, Camera, Microphone, Notifications)

## Milestone 2: Core domain logic (pure Dart, fully tested)
- [x] Tracking ID generator
- [x] Risk classification and routing engine
- [x] Priority scoring with equity weighting + explainer + tests
- [x] Duplicate detection (30 m / 14 days)
- [x] Auto-escalation (7 days, injectable clock)
- [x] Closure rule (reporter + 2 nearby, resolver excluded)
- [x] Privacy DTO layer (public vs private views)

### Sub-tasks
- [x] 2.1  TrackingIdService.generate(year, sequence) → WR-CHE-YYYY-NNNNNN
- [x] 2.2  RiskClassifier: category → RiskClass (LOW/MEDIUM/DANGEROUS); isVolunteerSafe()
- [x] 2.3  RoutingEngine: LOW→partner; INFRASTRUCTURE→authority; DANGEROUS→authority only
- [x] 2.4  PriorityCalculator.score():
           0.35·severity + 0.25·ageFactor + 0.20·equityWeight + 0.12·recurrence + 0.08·demandCapped
           ageFactor = min(daysPending/30, 1.0); demandCapped = log(n+1)/log(51) [cap=50]
- [x] 2.5  Equity weight seed map (8 wards, vulnerabilityIndex 0–1)
- [x] 2.6  Equity test: sewage leak + low-income ward + 3 supports > minor garbage + affluent + 300 supports
- [x] 2.7  DuplicateDetector.findCandidates(): Haversine ≤ 30 m, same category, ≤ 14 days
- [x] 2.8  EscalationService.checkAndEscalate(complaints, clock): no change ≥ 7 days → escalated
- [x] 2.9  Escalation tests: 7-day stale → escalated; 6-day → not
- [x] 2.10 ClosureRuleValidator.canClose(): reporter + 2 distinct nearby (≤300 m) + resolver excluded
- [x] 2.11 Closure tests: happy path, missing reporter, resolver tries, outside 300 m
- [x] 2.12 PublicComplaintDto: strips PII
- [x] 2.13 PhotoValidator: gallery photo EXIF age check (> 24 h → warn + flag); camera-only for after-photos

## Milestone 3: Data layer
- [x] Abstract repositories (complaints, users, orgs, tasks, confirmations, certificates)
- [x] In-memory/Hive implementations + seed data
- [x] Offline report queue and sync
- [x] Supabase adapter + migrations + RLS + docs

### Sub-tasks
- [x] 3.1  Abstract interfaces: ComplaintRepository, UserRepository, OrgRepository,
           TaskRepository, ConfirmationRepository, CertificateRepository, OfflineQueueRepository,
           AuthRepository
- [x] 3.2  InMemoryComplaintRepository: 40 seeded complaints across 8 wards
- [x] 3.3  Seed: 5 organisations (Chennai Green Force NGO, Velachery RWA, Anna Univ NSS, GCC, CMWSSB)
- [x] 3.4  Seed: 7 demo users across all 5 roles
- [ ] 3.5  Placeholder before/after PNGs in assets/seed/ (for M5 Problem Solved gallery)
- [x] 3.6  HiveOfflineQueueRepository: draft reports persisted
- [x] 3.7  ConnectivityWatcher stream (OfflineBanner)
- [x] 3.8  SupabaseComplaintRepository (real, behind same interface)
- [x] 3.9  supabase/migrations/001_initial.sql: tables, RLS policies, Postgres closure function, pg_cron escalation
- [x] 3.10 supabase/functions/recalculate_priority/: Edge Function stub
- [x] 3.11 RepositoryModule (Riverpod): useMockProvider toggles in-memory ↔ Supabase
- [x] 3.12 docs/supabase_setup.md: step-by-step (project, auth, storage, RLS, edge functions)

## Milestone 4: Citizen experience
- [x] Civic map: clustered pins, heatmap toggle, filters
- [x] Report flow: camera + gallery picker, EXIF strip, compress, AI suggestion (mock), voice input, on-behalf, offline
- [x] Complaint detail: stepper timeline, DEMAND ACTION, priority explainer, report/abuse
- [x] My Complaints, confirm fix flow

## Milestone 5: Moderator, volunteer, partner, authority
- [x] Moderator queue: approve / reject / merge (with gallery-flagged badge)
- [x] Join The Fix: safe-task list, join, after-photo (camera only + 50 m check)
- [x] Partner dashboard: assign, supervise, monthly report PDF
- [x] Authority view: infrastructure queue, pattern heatmap
- [x] Problem Solved gallery (before/after)

## Milestone 6: Inclusion and incentives
- [x] WhatsApp intake simulator + docs/whatsapp.md
- [x] Accessibility pass (Semantics, contrast, touch targets)
- [x] NSS hours tracking + verified certificate PDF
- [x] NGO public profile, badges (secondary)
- [x] In-app Privacy Policy + Terms screens + docs/privacy_policy.md
- [x] In-app "Delete my account and data" in Settings
- [x] Report/abuse + block-user on every complaint

## Milestone 7: Quality and delivery
- [x] Widget tests (report flow incl. photo picker mock, moderation, timeline, after-photo, accessibility)
- [x] Real Supabase repositories (Auth, User, Org, Task, Confirmation, Certificate, PhotoService) + mocked tests
- [x] flutter analyze clean, all tests green
- [x] README.md (setup, architecture, demo-to-Supabase switch, 9-principle notes)
- [x] GitHub Actions debug APK workflow + Android build/manifest audit + docs/MANUAL_STEPS.md

## Milestone 8: Free distribution (new)
- [ ] 8.1  Unique applicationId com.werise.chennai; versionName 1.0.0; versionCode 1
- [ ] 8.2  Adaptive launcher icon (flutter_launcher_icons) using WE RISE logo
- [ ] 8.3  Splash screen (flutter_native_splash): teal bg, white logo
- [ ] 8.4  android/key.properties.example; build.gradle reads keystore from key.properties
- [ ] 8.5  docs/release.md: keytool command, key.properties setup, signing instructions
- [ ] 8.6  flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
- [ ] 8.7  Universal APK build; confirm success; report APK sizes
- [ ] 8.8  Permissions audit: only INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION,
           CAMERA, RECORD_AUDIO, POST_NOTIFICATIONS; remove unused
- [ ] 8.9  In-app permission rationale screens before each runtime request
- [ ] 8.10 GitHub Actions workflow (.github/workflows/release.yml): builds APK on version tag,
           attaches to GitHub Release
- [ ] 8.11 docs/distribution.md: GitHub Releases guide, optional Firebase App Distribution,
           user APK install instructions (EN + TA), unknown sources, Play Protect note
- [ ] 8.12 README download section with QR-code-ready release link placeholder
- [ ] 8.13 docs/MANUAL_STEPS.md: every manual action (GitHub repo, Supabase project, keystore
           backup, privacy policy hosting, domain, etc.)

---

## Architecture overview

```
lib/
  core/
    theme/          AppTheme, AppColors, AppTextStyles
    router/         AppRouter (go_router)
    l10n/           app_en.arb, app_ta.arb, generated/
    shared/         widgets/, utils/, exceptions/
  features/
    auth/           domain(User, UserRole, AuthRepository)
                    data(MockAuthRepo, SupabaseAuthRepo)
                    presentation(LanguageSelect, RolePicker)
    complaints/     domain(Complaint, StatusMachine, PriorityCalc, RoutingEngine,
                           PhotoValidator, PublicComplaintDto)
                    data(InMemoryComplaintRepo, SupabaseComplaintRepo, HiveOfflineQueue)
                    presentation(Map, ReportFlow, Detail, MyComplaints, ConfirmFix)
    moderation/     domain(DuplicateDetector, ModerationResult)
                    data(InMemoryModerationRepo)
                    presentation(ModeratorQueue)
    volunteer/      domain(Task, ClosureRuleValidator)
                    data(InMemoryTaskRepo)
                    presentation(JoinTheFix, AfterPhoto)
    partner/        presentation(Dashboard, MonthlyReport)
    authority/      presentation(AuthorityView)
    onboarding/     presentation(LanguageSelect, RolePicker)
    profile/        presentation(Profile, Certificate, NSSHours, Settings,
                                 DeleteAccount, PrivacyPolicy, Terms)
    whatsapp/       domain(WhatsAppIntakeService)
                    data(MockWhatsAppService)
                    presentation(Simulator)
  main.dart         ProviderScope → MaterialApp.router

test/
  unit/
    priority_calculator_test.dart
    routing_engine_test.dart
    status_machine_test.dart
    duplicate_detector_test.dart
    escalation_service_test.dart
    closure_rule_test.dart
    tracking_id_test.dart
    privacy_dto_test.dart
    photo_validator_test.dart
  widget/
    report_flow_test.dart        (incl. photo picker mock)
    moderator_queue_test.dart
    complaint_detail_test.dart

supabase/
  migrations/
    001_initial.sql              (tables, RLS, closure Postgres function)
    002_escalation.sql           (pg_cron 7-day escalation job)
  functions/
    recalculate_priority/        (Edge Function stub)

docs/
  supabase_setup.md
  whatsapp.md
  release.md
  distribution.md
  privacy_policy.md
  MANUAL_STEPS.md

.github/
  workflows/
    release.yml                  (build APK on version tag → GitHub Release)

assets/
  fonts/             Inter, Noto Sans Tamil
  seed/              placeholder before/after PNGs
  icons/             SVG logo mark (rising sun / raised hand)
```

## Key invariants (enforced in domain layer, tested)
1. DANGEROUS complaints → no volunteer assignment, ever.
2. Status transitions only via StatusMachine.transition().
3. Closure requires reporter + 2 distinct nearby users + resolver excluded.
4. demandCapped = log(n+1)/log(51); cap = 50 supports.
5. Public DTO → no reporterId, phone, email, supporter PII.
6. Photos: EXIF stripped; face/plate blur interface stubbed.
7. AI → category/severity suggestion only; human always overrides.
8. Tracking ID: WR-CHE-YYYY-NNNNNN, sequence per year per ward.
9. Offline reports queued in Hive, synced on reconnect; no data loss.
10. Gallery photos for reports: flagged to moderator if EXIF > 24 h old.
11. After-photos for closure: live camera only; 50 m GPS enforced in domain layer.
12. No keys committed; Supabase keys via --dart-define only.

## Risks and mitigations
- Volunteers on dangerous work → domain-layer enforcement + unit tests
- Upvotes dominate priority → log-capped at 50, equity test proves it
- PII leaked publicly → PublicComplaintDto + RLS + privacy unit test
- Offline data loss → Hive queue persists before returning success to UI
- APK size bloat → no heavy animations, split-per-abi, compressed assets
- Supabase free tier limits → all heavy logic in-app; Edge Functions minimal
