# Supabase Free-Tier Setup Guide (WE RISE)

WE RISE runs in **Demo Mode** out of the box with zero API keys. When you are ready to connect a live backend on Supabase's free tier, follow these steps.

## 1. Create a Supabase Project
1. Go to [https://supabase.com](https://supabase.com) and sign in with GitHub.
2. Click **New Project**, choose the **Mumbai (`ap-south-1`)** region (lowest latency for Chennai), and set a strong database password.
3. Wait ~2 minutes for provisioning.

## 2. Run Database Migrations
1. Install the Supabase CLI: `npm install -g supabase` (or via Scoop/Homebrew).
2. Link your project:
   ```bash
   cd we_rise
   supabase login
   supabase link --project-ref <YOUR_PROJECT_REF>
   ```
3. Push the SQL schema, RLS policies, closure rule function, `pg_cron` escalation job, certificates table, and Storage bucket policies:
   ```bash
   supabase db push
   ```
   This applies `supabase/migrations/001_initial.sql` and `supabase/migrations/002_certificates_and_storage.sql`.

## 3. Configure Storage Bucket (Photos)
1. In the Supabase Dashboard, open **Storage → New bucket**.
2. Create a bucket named `complaint-photos` (Public read enabled, or Private with signed URLs).
3. Add a policy allowing authenticated users to upload to `complaint-photos/*` and anyone to read photos for non-rejected complaints.

## 4. Enable Auth Providers
1. Open **Authentication → Providers**.
2. **Email** is enabled by default.
3. Optionally enable **Google** OAuth (free) by adding your Google Cloud OAuth Client ID and Secret.
4. Do **NOT** enable Phone OTP (costs money).

## 5. Deploy Edge Function (Optional)
```bash
supabase functions deploy recalculate_priority
```

## 6. Run the App with Supabase Keys
Never commit keys to Git. Pass them at build/run time via `--dart-define`:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<YOUR_PROJECT_REF>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<YOUR_ANON_KEY>
```
