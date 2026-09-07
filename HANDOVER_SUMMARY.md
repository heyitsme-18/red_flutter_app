# red. Flutter App - Handover Summary

## Short project explanation

This prototype is built in Flutter/Dart. Chrome was used only as the development preview because the Android emulator was not set up yet. The same Flutter codebase can run on Android after Android Studio, Android SDK, and an emulator or physical Android device are configured.

## Work completed

- Created a Flutter version of the red. mindfulness app prototype.
- Added the app flow from the provided mind map:
  - logo splash
  - intro splash
  - home
  - collections
  - meditations
  - journal
  - settings
- Connected Firebase Storage content:
  - meditation audio
  - meditation thumbnails
  - collection thumbnails
  - Universe Collection detail thumbnails
  - Universe Collection PDFs
- Fixed Firebase web image loading by using Flutter's web HTML image rendering strategy.
- Added audio playback:
  - full audio player
  - mini-player
  - play/pause
  - draggable timeline slider
  - 10-second rewind/forward
- Added Settings pages:
  - About red.
  - Privacy Policy
  - Terms and conditions
  - Feedback placeholder
  - profile placeholder
- Added Journal prototype:
  - Daily Glow mode
  - Universe Collection mode
  - interactive calendar
  - mood toggles/chips
  - journal note field
  - save button placeholder

## Firebase folders currently used

```text
audio/
meditation-thumbnails/
collection-thumbnails/
collection-detail-thumbnails/universe/
collection-pdfs/universe/
```

## Current known pending items

- Android setup is still pending on the laptop:
  - Android Studio
  - Android SDK
  - Android Emulator or physical Android phone
  - Android licenses
- Universe Collection audio files are not currently mapped/found in the readable Firebase folders.
- Firebase Authentication is not fully implemented yet.
- Journal entries are currently UI-only and are not saving to Firebase yet.
- Final app package name, launcher icon, splash icon, and production branding should be confirmed.
- Firestore text source should be confirmed for:
  - Universe Collection description
  - About red.
  - Privacy Policy
  - Terms and conditions

## Questions to confirm with supervisor

1. Should the GitHub repo be private, and who should be added as collaborators?
2. What should the official Android package name be?
3. Where are the Universe Collection audio files stored, or are they still missing?
4. Should users log in before accessing app content, or can static content remain public-read from Firebase Storage?
5. Should journal entries be saved in Firestore, and what fields are needed?
6. Are the legal texts and About red. content final?
7. Should the Flutter UI match the iOS app exactly or follow Android/Material conventions where appropriate?

## Suggested next development steps

1. Complete Android Studio / Android SDK setup.
2. Run the Flutter app on Android emulator or physical Android device.
3. Confirm package name and Firebase Android app configuration.
4. Add Firebase Authentication if required.
5. Add Firestore structure for journal entries and user profile data.
6. Map missing Universe Collection audio.
7. Prepare APK/AAB build for Android review.
