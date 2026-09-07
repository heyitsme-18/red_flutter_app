# Copy this file to RUN_WITH_FIREBASE.ps1, fill in the values from Firebase Console,
# then run it from PowerShell.
#
# Firebase Console:
# Project settings -> General -> Your apps -> Web app -> Firebase SDK config

flutter run -d chrome `
  --dart-define=FIREBASE_ENABLED=true `
  --dart-define=FIREBASE_API_KEY="PASTE_API_KEY_HERE" `
  --dart-define=FIREBASE_APP_ID="PASTE_WEB_APP_ID_HERE" `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="PASTE_MESSAGING_SENDER_ID_HERE" `
  --dart-define=FIREBASE_PROJECT_ID="PASTE_PROJECT_ID_HERE" `
  --dart-define=FIREBASE_AUTH_DOMAIN="PASTE_AUTH_DOMAIN_HERE" `
  --dart-define=FIREBASE_STORAGE_BUCKET="PASTE_STORAGE_BUCKET_HERE"

