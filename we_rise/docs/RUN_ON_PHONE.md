# Running WE RISE on Your Android Phone

No emulator is required — testing directly on a physical Android phone is faster and lets you test the real camera, GPS, and voice input.

---

## Option A: Install the Debug APK Directly (Fastest)

1. Build the debug APK (already built if you followed Milestone 5):
   ```powershell
   flutter build apk --debug
   ```
   The APK is created at:
   `we_rise\build\app\outputs\flutter-apk\app-debug.apk`

2. Copy `app-debug.apk` to your phone (via USB cable, Google Drive, or WhatsApp to yourself).
3. On your phone, tap `app-debug.apk`.
4. If Android asks, tap **Settings → Allow from this source** (for your file manager or browser) and tap **Install**.
5. If Google Play Protect shows a warning about an unrecognized developer, tap **More details → Install anyway**.
6. Open **WE RISE**. It starts in **Demo Mode** with Chennai seed data — no login or API keys needed.

---

## Option B: Live Run via USB (`flutter run`)

### 1. Enable Developer Options & USB Debugging on Your Phone
1. Open **Settings → About phone**.
2. Tap **Build number** 7 times until you see *"You are now a developer!"*.
3. Go back to **Settings → System → Developer options** (or search "Developer options" in Settings).
4. Turn on **USB debugging**.

### 2. Connect and Run
1. Connect your phone to your PC with a USB data cable.
2. On your phone, tap **Allow** on the *"Allow USB debugging?"* prompt (check *Always allow from this computer*).
3. In PowerShell, verify your phone is detected and launch the app:
   ```powershell
   cd "we_rise"
   flutter devices
   flutter run
   ```

---

## Switching Roles in Demo Mode
Inside the app, open the **Profile** tab (or **Settings**) and use **Switch Demo Role** (or long-press the **WE RISE** title) to switch instantly between **Citizen**, **Volunteer**, **Moderator**, **Partner Organisation**, and **Authority** without signing out.

---

## Alternative: Installing an Android Emulator (via Android Studio)
If you prefer a virtual device on your PC:
1. Install **Android Studio** from [developer.android.com/studio](https://developer.android.com/studio).
2. Open Android Studio → **More Actions → Virtual Device Manager** (or **Tools → Device Manager**).
3. Click **Create Device** → choose a phone (e.g., **Pixel 6** or a low-RAM profile) → download a system image (e.g., **Android 13 / API 33** or **Android 14 / API 34**) → **Finish**.
4. Start the emulator from Device Manager, then run `flutter run` in `we_rise`.
