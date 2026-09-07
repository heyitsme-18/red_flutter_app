# GitHub Handover Checklist

## Recommended repository setting

Use a private GitHub repository unless the company explicitly approves a public repository.

## Files/folders to include

Include the Flutter project code:

```text
android/
assets/
ios/
lib/
test/
web/
windows/
linux/
macos/
pubspec.yaml
pubspec.lock
README.md
FIREBASE_CONTENT_SCHEMA.md
SETUP_FLUTTER_AND_FIREBASE.md
SUPERVISOR_QUESTIONS.md
HANDOVER_SUMMARY.md
MEETING_SCRIPT.md
RUN_WITH_FIREBASE_TEMPLATE.ps1
```

## Files/folders not to include

Do not upload local/generated/development-only files:

```text
build/
.dart_tool/
.dart_cache/
.idea/
.vscode/
RUN_WITH_FIREBASE.ps1
drive_folder.html
ios_reference_*.mp4
video_frames/
```

`RUN_WITH_FIREBASE.ps1` is excluded because it contains the filled Firebase config for this laptop/project. The template file is safe to include.

## Before uploading

Run:

```powershell
cd "C:\Users\ashra\Documents\App Development\red_flutter_app"
flutter analyze
flutter build web --debug --dart-define=FIREBASE_ENABLED=true --no-wasm-dry-run
```

If Android setup is completed later, also run:

```powershell
flutter doctor
flutter run -d android
```

## Suggested GitHub repo description

```text
Flutter prototype for the red. mindfulness app with Firebase Storage media integration.
```

## Suggested first commit message

```text
Initial Flutter prototype with Firebase media integration
```
