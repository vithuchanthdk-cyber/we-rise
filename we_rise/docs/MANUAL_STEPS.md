# Manual Steps for WE RISE (Beginner Guide)

Because this project has **zero budget** and no local Android SDK is required, you can build and download the Android APK for free using **GitHub Actions**.

---

## 1. Create a Free GitHub Account & Empty Repository
1. Go to [https://github.com/signup](https://github.com/signup) and create a free account.
2. Click **+** (top-right) → **New repository**.
3. Name it `we-rise`, keep it **Public** (free unlimited GitHub Actions minutes) or **Private** (2,000 free minutes/month).
4. **Do NOT** check "Add a README file" or ".gitignore" — leave it completely empty.
5. Copy the repository URL shown (e.g., `https://github.com/YOUR_USERNAME/we-rise.git`).

---

## 2. Push This Project to GitHub
Open PowerShell in `c:\Users\ADMIN\Desktop\we raise` and run these exact commands:

```powershell
cd "c:\Users\ADMIN\Desktop\we raise"
git init
git branch -M main
git add .
git commit -m "Initial commit: WE RISE app"
git remote add origin https://github.com/YOUR_USERNAME/we-rise.git
git push -u origin main
```

*(If Git asks you to sign in, follow the browser sign-in prompt.)*

---

## 3. Run the Build & Download the APK from GitHub Actions
1. Open your repository on GitHub and click the **Actions** tab at the top.
2. Every push to `main` automatically starts **Build Debug APK** (you can also click **Build Debug APK → Run workflow** manually anytime).
3. Wait ~3–5 minutes for the green checkmark.
4. Click the completed workflow run → scroll down to **Artifacts** → click **we-rise-debug-apk** to download the ZIP file.
5. Unzip it to get `app-debug.apk`.
6. Copy `app-debug.apk` to your Android phone and tap it to install (see [RUN_ON_PHONE.md](RUN_ON_PHONE.md) if Android asks to allow unknown sources).

---

## 4. Optional: Build Locally with Android Studio
If you want to build or run on an emulator directly from your Windows PC:
1. Install **Android Studio** from [https://developer.android.com/studio](https://developer.android.com/studio).
2. Open Android Studio once so it downloads the **Android SDK** and **Android SDK Platform-Tools**.
3. Accept Android licenses in PowerShell:
   ```powershell
   flutter doctor --android-licenses
   ```
4. Then run `flutter build apk --debug` or `flutter run` inside `we_rise\`.

---

## 5. Changing `applicationId` (Before Production Release)
The placeholder package ID is `com.werise.chennai` in `we_rise/android/app/build.gradle`. Change it there if you publish under your own domain.

---

## 6. Other Manual Steps (When Moving Beyond Demo Mode)
- **Supabase project**: Follow [supabase_setup.md](supabase_setup.md) to create a free Mumbai-region project, run `supabase db push`, and pass `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_ANON_KEY=...`.
- **Release keystore backup** (Milestone 8): Store your `.jks` keystore and `key.properties` in a safe offline backup (never commit them to GitHub).
- **Privacy Policy hosting**: You can host `docs/privacy_policy.md` for free using GitHub Pages or link directly to the file in your GitHub repo.
