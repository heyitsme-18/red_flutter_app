# Meeting Script

## 30-second update

I created a Flutter/Dart prototype of the red. app based on the mind map and iOS reference. I used Chrome for quick preview during development, but the codebase is Flutter and can run as an Android app once Android Studio and the Android SDK are configured.

The app currently includes splash screens, bottom navigation, Home, Collections, Meditations, Journal, and Settings. Firebase Storage is connected for audio, thumbnails, collection images, and PDFs. The audio player works and includes play/pause, skip controls, a draggable timeline, and a mini-player.

## What I can demo

- Open the app preview.
- Show the splash flow.
- Show Home and Meditations pulling Firebase audio/thumbnails.
- Play an audio track from Firebase.
- Drag the audio timeline.
- Open Universe Collection.
- Show Firebase collection thumbnails and PDF links.
- Show Journal tabs and calendar interaction.
- Show Settings, About red., Privacy Policy, and Terms.

## Honest current limitations

The main pending part is Android packaging/testing, because Android Studio and the Android SDK still need to be set up on my laptop. The Flutter code does not need to be rewritten for Android; it just needs the Android toolchain to run/build it as an Android app.

Universe Collection audio is also still pending because I could not find the matching Creation, Void, Time, Stardust, Orbit, Expansion, and Infinity audio files in the readable Firebase folders. The thumbnails and PDFs are mapped.

Journal saving is currently UI-only. The next step would be deciding the Firestore structure for saved journal entries.

## What I need confirmed

- Should the GitHub repository be private, and who should I add?
- What is the official Android package name?
- Where are the Universe Collection audio files?
- Should Firebase content be public-read, or should the app require login before content loads?
- What Firestore structure should I use for users, journal entries, favorites, and progress?
- Are the About red., Privacy Policy, and Terms texts final?

## Suggested next milestone

For the next stage, I would set up Android Studio/SDK, run the Flutter app on an Android emulator, confirm Firebase Android configuration, then add Authentication and Firestore saving for profile/journal/favorites.
