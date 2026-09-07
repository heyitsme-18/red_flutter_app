# Flutter + Firebase setup checklist

Use this checklist on the laptop where you want to run the app.

## 1. Install these first

### Required

- Git for Windows
- Visual Studio Code
- Android Studio
- Flutter SDK
- Firebase CLI
- FlutterFire CLI

### VS Code extensions

- Flutter
- Dart

The Flutter extension usually installs/activates the Dart extension too.

## 2. Android Studio setup

Open Android Studio and install:

- Android SDK
- Android SDK Platform-Tools
- Android SDK Command-line Tools
- Android Emulator

Then create an emulator:

- Device: Pixel 7 or Pixel 8
- System image: latest stable Android image with Google Play
- Orientation: portrait

Firebase recommends using an emulator image with Google Play for Android Firebase testing.

## 3. Check Flutter

Open a new PowerShell window and run:

```powershell
flutter doctor
```

If Android licenses are missing, run:

```powershell
flutter doctor --android-licenses
```

Then accept the licenses and run:

```powershell
flutter doctor
```

again until Android is green.

## 4. Prepare this app

From this folder:

```powershell
cd "C:\Users\ashra\Documents\App Development\red_flutter_app"
flutter create .
flutter pub get
flutter run
```

If an emulator is open, Flutter should show it as a device.

## 5. Firebase login and FlutterFire

Install Firebase CLI, then run:

```powershell
firebase login
```

Install FlutterFire CLI:

```powershell
dart pub global activate flutterfire_cli
```

Then from the app folder:

```powershell
flutterfire configure
```

Choose the existing Firebase project you already have access to.

## 6. First Firebase packages we will likely add

Start small:

```powershell
flutter pub add firebase_core
flutter pub add cloud_firestore
flutter pub add firebase_storage
flutter pub add firebase_auth
```

Then rerun:

```powershell
flutterfire configure
flutter run
```

## 7. What to send Codex after setup

After installation, send:

```powershell
flutter doctor
```

output, or just ask Codex to check it. Once Flutter is visible from the terminal, Codex can run:

- `flutter pub get`
- `flutter analyze`
- `flutter run`
- Firebase configuration checks

