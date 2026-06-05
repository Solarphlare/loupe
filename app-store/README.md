# App Store assets

Source of truth for Loupe's App Store listing, kept under version control
alongside the app. App Store ID: 6766152470.

## Layout

```
app-store/
  metadata/
    copyright.txt           Copyright          (not localized)
    en-CA/
      name.txt              App name           (max 30 chars)
      subtitle.txt          Subtitle           (max 30 chars)
      keywords.txt          Keyword field      (max 100 chars, comma-separated, no spaces)
      promotional_text.txt  Promotional text   (max 170 chars, editable without review)
      description.txt       Description        (max 4000 chars)
      support_url.txt       Support URL
      marketing_url.txt     Marketing URL
  screenshots/
    captions.md             Suggested OCR-friendly screenshot captions
```

`copyright.txt` sits at the metadata root because App Store Connect treats it
as version-level information, not a per-language field. `support_url.txt` and
`marketing_url.txt` are per-locale (App Store Connect stores them under each
localization), so they live in every locale folder.

The `metadata/` naming follows the fastlane `deliver` convention, so the
listing can be uploaded automatically later if desired. `en-CA` is the primary
locale. Add more locale folders (e.g. `de-DE`, `ar-SA`) beside it to localize
the listing; each locale gets its own keyword field, which multiplies keyword
reach.

## ASO notes (2026)

- Apple search ranks on intent themes, not exact-match keywords. The fields
  are arranged so each one covers new ground: title and subtitle, keyword
  field, description, and screenshot captions never repeat a word.
- Themes covered: privacy, device fingerprinting, tracking awareness, what
  apps can read, free and open source.
- Refresh the keyword field every 3–5 weeks against impression data.

## Publishing with fastlane

The text metadata in this folder is pushed to App Store Connect with fastlane
`deliver`. Config lives at the repo root in `fastlane/` and points `deliver`
here via `metadata_path`.

### One-time setup

1. Install fastlane (the repo pins it via the root `Gemfile`):

   ```sh
   bundle install
   ```

   If your system Ruby is too old for the current fastlane, install it with
   Homebrew instead (`brew install fastlane`) and drop the `bundle exec` prefix
   below.

2. Create an App Store Connect API key with the **App Manager** role at
   *App Store Connect -> Users and Access -> Integrations -> App Store Connect API*,
   download the `.p8` (one-time download), and keep it inside `fastlane/`.

3. Copy `fastlane/.env.example` to `fastlane/.env` and fill in `ASC_KEY_ID`,
   `ASC_ISSUER_ID`, and `ASC_KEY_FILEPATH`. The real `.env` and any `*.p8` are
   gitignored — never commit them.

### Pushing metadata

```sh
bundle exec fastlane metadata             # renders an HTML preview, then asks before uploading
bundle exec fastlane metadata force:true  # skip the preview (CI / non-interactive)
```

This uploads text only — no build, no screenshots (`skip_binary_upload`,
`skip_screenshots`) — and saves it to the editable version without submitting
for review.

### Locale folder names

`deliver` matches each folder to an App Store Connect language code, so each
folder name must be a valid code (e.g. Arabic is `ar-SA`, not `ar`).

## Screenshots with fastlane

Screenshots are captured automatically with fastlane `snapshot`, driven by the
`LoupeUITests` UI-test target. Each test launches the app with the
`-LoupeMockData` flag, so every screen renders the fixed persona from
`code/Loupe/Support/MockData.swift` instead of live device readings — giving
deterministic, believable shots across every locale.

```sh
bundle exec fastlane screenshots         # capture on the simulator (no ASC login)
bundle exec fastlane screenshots_upload  # push fastlane/screenshots to App Store Connect
```

Config lives in `fastlane/Snapfile` (devices, languages, output). The iPhone is
captured in portrait and the iPad in landscape (the UI test rotates per idiom,
and on iPad the home shots select a category to fill the detail pane). Eight
screens are captured per device/language:

1. Home (iPad selects the first category)
2. Onboarding — "What your apps can see"
3. The Needs Permission section (iPad selects "Motion & Sensors")
4. Onboarding — "What your installed apps say about you"
5. Photos, scrolled to the geolocation (recent / frequent locations)
6. Bluetooth
7. Local Network
8. Motion & Sensors

Generated PNGs land in `fastlane/screenshots/` (gitignored). Adjust the exact
simulator names in the `Snapfile` to match the runtimes installed locally
(`xcrun simctl list devicetypes`).
