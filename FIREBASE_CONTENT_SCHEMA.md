# Firebase Storage connection used by the Flutter app

The app now reads from the company Firebase Storage bucket first.

Bucket:

```text
red-app-b361a.firebasestorage.app
```

Expected folders from the company Firebase console:

```text
audio/
  A Letter from the Future [EN 10].mp3
  A Letter from the Future [EN 20].mp3
  Body Scan Energizer [EN 10].mp3

meditation-thumbnails/
  a-letter-from-the-future.png
  body-scan-energizer.png
  radical-kindness.png

collection-thumbnails/
  universe-collection-cover.png

collection-detail-thumbnails/universe/
  01-creation.png
  02-void.png
  03-time.png
  ...

collection-pdfs/universe/
  01-creation.pdf
  02-void.pdf
  03-time.pdf
  ...

Workshops_Courses/
  Universe Journal No. 1 CREATION.pdf
  Your Best Life Sleep Meditation by Manifest with Neuroscience_app.mp3
```

## What the app does now

- Lists files from `audio/`
- Turns audio filenames into display titles
- Lists files from `meditation-thumbnails/`
- Pairs meditation thumbnails with audio files when filenames match
- Lists files from `collection-thumbnails/` and `collection-detail-thumbnails/`
- Uses those for Universe Collection / journey visuals
- Lists files from `collection-pdfs/`
- Links the first matching PDF to journey content

## Filename matching rule

The app matches files by simplified filename.

Example:

```text
audio/01-creation.mp3
meditation-thumbnails/creation.png
collection-pdfs/creation.pdf
```

All become the same key:

```text
creation
```

So they can be connected together.

The app also knows how to match names like:

```text
audio/A Letter from the Future [EN 10].mp3
meditation-thumbnails/a-letter-from-the-future.png
```

Both become:

```text
aletterfromthefuture
```

## Optional Firestore text

Long text can still come from Firestore if this document exists:

```text
app_text/red
```

Optional fields:

```text
collectionDescription
aboutRed
privacyPolicy
terms
```

If this document does not exist, the app uses local fallback text.
