# red. Flutter App

Flutter prototype for the red. mindfulness app, focused on Android development with a web preview used during testing.

## Main features

- Home, Collections, Meditations, Journal, and Settings tabs
- Firebase Storage integration for meditation audio, thumbnails, collection images, and collection PDFs
- Audio player with play/pause, skip controls, draggable progress slider, and mini-player
- Universe Collection screen with Firebase image and PDF mapping
- Journal screen with Daily Glow and Universe Collection sections
- Settings screens for profile placeholder, About red., Privacy Policy, Terms and Conditions, and Feedback placeholder

## Firebase content folders

The prototype expects Firebase Storage content in these folders:

```text
audio/
meditation-thumbnails/
collection-thumbnails/
collection-detail-thumbnails/universe/
collection-pdfs/universe/
```

Optional long text can be provided from Firestore at:

```text
app_text/red
```

Expected text fields:

```text
collectionDescription
aboutRed
privacyPolicy
terms
```

## Current note

Universe Collection images and PDFs are mapped from Firebase. The matching Universe Collection audio files were not available in the checked Firebase Storage folders, so those journey audios are marked as pending in the prototype.

## Running the app

Install Flutter dependencies:

```powershell
flutter pub get
```

Run the web preview:

```powershell
flutter run -d chrome --dart-define=FIREBASE_ENABLED=true --dart-define=FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY
```

Run on Android after Android Studio, Android SDK, and an emulator/device are configured:

```powershell
flutter run -d android --dart-define=FIREBASE_ENABLED=true --dart-define=FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY
```

Build an Android APK:

```powershell
flutter build apk --dart-define=FIREBASE_ENABLED=true --dart-define=FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY
```
