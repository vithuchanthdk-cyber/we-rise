# Privacy Policy — WE RISE

**Last updated:** November 2026

WE RISE ("we", "our", "app") is a community-built civic issue tracker for Chennai. This policy explains what data we collect, how it is protected, and your rights.

## 1. Data We Collect
- **Photos**: Photos you attach to a report or after-photo closure. EXIF personal metadata (camera serial, personal device tags, original gallery GPS) is stripped on-device before upload.
- **Location**: Live device GPS coordinates captured at the time of reporting or confirming a fix. Gallery photos use live device GPS, never embedded EXIF location.
- **Voice Input**: Transcribed on-device (`speech_to_text` for Tamil and English); raw audio is not uploaded to our servers.
- **Email Address**: Used only for authentication via Supabase Auth (when production mode is enabled; Demo Mode requires no email or account).

## 2. Data We Never Collect or Show Publicly
- We do **not** collect your phone number.
- Your name, email, and `on_behalf_of` contact context are **never** exposed in public views, maps, or `PublicComplaintDto`.
- Public complaint views only show issue category, ward, status, priority score, photos, and actor role (e.g. `citizen`, `moderator`, `volunteer`).

## 3. Storage & Retention
- In **Demo Mode**, all data stays in-memory/local on your device.
- In **Production Mode**, data is stored in Supabase Postgres (with Row Level Security) and Supabase Storage.
- You can permanently delete your account and personal data at any time using **Settings → Delete my account and data**.
