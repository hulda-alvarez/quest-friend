# Quest Friend: setup

## 1. Get a Gemini API key
Create one at https://aistudio.google.com/apikey. That single key powers everything,
including the map results. **You do not need a separate Google Maps API key.**

## 2. Copy the files into your Flutter project
From this folder into your project root:

- `lib/`    -> replaces your `lib/` (it overwrites the default `main.dart`)
- `assets/` -> `assets/logo.png` and `assets/app.env`

Delete the default `test/widget_test.dart` (it references the old `MyApp` and will fail to compile).

## 3. Add dependencies
Run in your project root:

```
flutter pub add http flutter_dotenv image_picker speech_to_text flutter_tts url_launcher geolocator
```

Then add the `flutter:` assets block from `pubspec_additions.yaml` to your `pubspec.yaml`
(the two asset lines: `assets/logo.png` and `assets/app.env`).

## 4. Add your key
Open `assets/app.env` and replace `PASTE_YOUR_KEY_HERE`. If you use git, add
`assets/app.env` to `.gitignore`. After editing it, fully stop and restart the app
(hot reload does not reload assets).

`GEMINI_MODEL` defaults to `gemini-3.5-flash`. If you get a "model not found" message,
change it to any current model name listed at https://ai.google.dev/gemini-api/docs/models.

## 5. Android permissions (for the Android build)
Paste the contents of `android_manifest_additions.xml` into
`android/app/src/main/AndroidManifest.xml`. If Gradle complains about `minSdk`,
set `minSdk = 24` in `android/app/build.gradle(.kts)`.

## 6. Run

```
flutter pub get
flutter run -d chrome
```

In Chrome, allow the **microphone** and **location** prompts when you use those features.

Chrome notes:
- Speech input uses Chrome's built-in recognizer (Chrome/Edge only).
- "Take photo" opens a file picker on desktop; on an Android phone it opens the camera.
- The layout is capped to a phone-width column so it looks right in a wide window.

## Where Gemini is used
| Feature | Gemini capability |
|---|---|
| Scan (menus, signs, labels) | Multimodal vision: reads, translates and explains the photo in one call, flags allergens and warnings, answers follow-up questions about the photo |
| Translate (typed or spoken) | Context-aware translation with auto language detection, pronunciation guide and tone notes |
| Explore (nearby places) | Grounding with Google Maps: real places with links, no Maps key needed |
| Ask (culture and rules) | Chat with Google Search grounding, so laws, prices and rates are current, with source links |
| Home (trip guide) | Structured JSON output: survival phrases, local customs, currency tips |

## How the Maps part works
- Place results come from Gemini's Maps grounding. Each place gets "Directions" and
  "Open in Maps" buttons that deep-link into Google Maps (no Maps SDK).
- If Maps grounding is unavailable for your key or model, the app falls back to general suggestions
  and always offers a "Search in Google Maps" deep-link button.

## Known limits
- The API key is bundled into the app (fine for a hackathon; rotate it afterwards).
- Everything is in-memory, so history resets on restart, as requested.
- Translation quality for emergencies, legal or medical matters should be double-checked.
