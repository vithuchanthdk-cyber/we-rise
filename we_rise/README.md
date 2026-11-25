# WE RISE — Uniting Every Voice to Transform Every Community

A native Android/iOS Flutter civic accountability app for Chennai that turns local civic complaints into trackable, verified solutions.

---

## Architecture
- **Stack**: Flutter + Dart, Riverpod, `go_router`, `flutter_map` (OpenStreetMap), `hive_flutter`, Supabase (optional production backend).
- **Pattern**: Feature-first folders (`lib/features/<feature>/{domain,data,presentation}`) with abstract repository interfaces so Demo Mode (in-memory/Hive) and Production Mode (Supabase) share the exact same UI and domain logic.
- **Languages**: English + Tamil (`en`, `ta`), including Tamil/English voice input (`ta_IN` / `en_IN`).

## Running in Demo Mode (Default — Zero Keys)
```bash
cd we_rise
flutter pub get
flutter run
```
No API keys or backend setup required. Switch between Citizen, Volunteer, Moderator, Partner, and Authority roles anytime from **Profile → Switch Demo Role**.

## Switching to Supabase (Production Free Tier)
Follow [docs/supabase_setup.md](docs/supabase_setup.md), then pass keys at build/run time:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Building Without Android Studio
See [docs/MANUAL_STEPS.md](docs/MANUAL_STEPS.md) to build the APK via GitHub Actions and install it on your phone ([docs/RUN_ON_PHONE.md](docs/RUN_ON_PHONE.md)).

## Key Principles Built Into the Domain Layer
1. **Privacy by default**: `PublicComplaintDto` strips `reporterId`, `supporterIds`, and `onBehalfOf`; public views never show names or phone numbers.
2. **Safety**: `RoutingEngine` enforces that `DANGEROUS` issues (e.g., streetlight/electrical) go to authorities only — volunteers can never be assigned.
3. **No single-person closure**: `ClosureRuleValidator` requires the original reporter + 2 distinct nearby residents (≤ 300 m), excluding the resolver.
4. **Fair prioritisation**: Equity-weighted priority formula ensures severe issues in vulnerable wards outrank minor issues with inflated upvotes.
5. **7-day auto-escalation**: Stale open issues auto-escalate and gain prominence on the public map.
