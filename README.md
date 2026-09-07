# red. Flutter App Prototype

This is the Flutter/Dart prototype for the red. mindfulness app. It was previewed in Chrome during development because Android emulator setup was not completed yet, but the codebase is a Flutter app and can run on Android once Android Studio/SDK is configured.

## What is included

- Logo splash screen: `red.`
- Intro splash screen: `Pause. Breathe. Glow.`
- Bottom navigation with Home, Collections, Meditations, Journal, and Settings
- Firebase Storage connection for meditation audio, meditation thumbnails, collection thumbnails, collection detail thumbnails, and collection PDFs
- Audio player with play/pause, 10-second rewind/forward, draggable timeline slider, and mini-player
- Universe Collection page with Firebase thumbnail/PDF mapping
- Journal screen with Daily Glow and Universe Collection tabs, interactive calendar, mood/toggle fields, and journal note field
- Settings pages for profile placeholder, About red., Privacy Policy, Terms and conditions, and Feedback placeholder

## Firebase project used

Bucket:

```text
red-app-b361a.firebasestorage.app
```

The app currently reads content from these Storage folders:

```text
audio/
meditation-thumbnails/
collection-thumbnails/
collection-detail-thumbnails/universe/
collection-pdfs/universe/
```

Optional long text can come from Firestore:

```text
app_text/red
```

Expected optional fields:

```text
collectionDescription
aboutRed
privacyPolicy
terms
```

If Firestore text is missing, the app uses local fallback text.

## Current known limitation

Universe Collection audio is not currently linked because the matching audio files were not found in the readable Firebase folders. The app maps Universe Collection images and PDFs, but the journey audio remains pending.

Expected Universe journey audio names:

```text
Creation
Void
Time
Stardust
Orbit
Expansion
Infinity
```

## How to run the current preview

From PowerShell:

```powershell
cd "C:\Users\ashra\Documents\App Development\red_flutter_app"
.\RUN_WITH_FIREBASE.ps1
```

If the app is already running, press `q` in the terminal first, then run the script again.

For a new laptop or fresh clone, copy `RUN_WITH_FIREBASE_TEMPLATE.ps1` to `RUN_WITH_FIREBASE.ps1` and fill in the Firebase values from Firebase Console before running.

## How to run later as Android app

Install and configure:

- Android Studio
- Android SDK
- Android Emulator, or connect a real Android phone
- Android licenses through Flutter

Then run:

```powershell
flutter doctor
flutter doctor --android-licenses
flutter run -d android
```

To build an installable Android APK:

```powershell
flutter build apk
```

## Notes for GitHub

Recommended: create a private GitHub repository unless the company gives permission for a public repo.

Do not commit secrets or private credentials. The current Firebase values are passed through the run script / Dart defines and should be reviewed before sharing externally.
