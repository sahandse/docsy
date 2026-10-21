# Docsy

Docsy is a minimal Persian/English document library for Android, built with Flutter. Its interface uses a clean monochrome palette with a restrained orange accent.

## Implemented features

- Select one or multiple files with Android's system file picker.
- Browse recent files, search filenames, and filter by file type.
- Copy selected documents into Docsy's private app storage so file access does not depend on a temporary picker path.\n- Remove library entries and clean up Docsy-managed copies without deleting the user's original source document.\n- Automatically drop stale library entries when their stored file is no longer available.
- Remember recent file paths, language choice, and light/dark theme locally.
- View PDFs inside the app, including normal PDF viewer navigation and zoom gestures provided by the viewer.
- Preview TXT and CSV files in-app when they are no larger than 2 MiB.
- Hand off Office formats to compatible apps installed on the device.
- Switch between Persian (RTL) and English (LTR).
- Use light and dark themes.
- No demo documents are preloaded; the library starts empty and uses files selected by the user.

## Format support

| Format | Current behavior |
|---|---|
| PDF | In-app PDF viewer |
| TXT, CSV | In-app text preview up to 2 MiB |
| DOC, DOCX, XLS, XLSX, PPT, PPTX, RTF, ODT, ODS, ODP | Open with a compatible installed app |

Docsy does not currently include a full Office document rendering or editing engine. Office-format support depends on another compatible app being installed.

## Build and test

Requirements: Flutter stable, Dart SDK `>=3.4.0 <4.0.0`, Android SDK and Android build tooling.

This repository generates the Android platform scaffold during GitHub Actions. To build locally from a fresh checkout, generate it first:

```sh
flutter create --platforms=android --org com.sahandse --project-name docsy .
# Ensure android/app/build.gradle.kts uses compileSdk = 36
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The APK is normally generated at `build/app/outputs/flutter-apk/app-release.apk`.

GitHub Actions checks analysis and widget tests, builds a release APK, and uploads it as the `docsy-android-apk` artifact when the workflow succeeds. Open the Actions run and download the artifact from its Artifacts section.

## Release checklist

- [ ] Confirm the latest GitHub Actions run passes analysis, tests, and release APK build.
- [ ] Install the APK on a physical Android device and verify file selection, PDF viewing, TXT/CSV preview, external Office handoff, search, filters, delete-from-library, language, and theme persistence.
- [ ] Verify behavior when a remembered file has moved or Android access has expired.
- [ ] Confirm the generated minimalist orange-and-black launcher icon on a physical Android device.\n- [ ] Set the final store application ID, version, and store signing configuration before publishing to an app store.
- [ ] Produce and validate a signed store release before distribution.

## Privacy

Documents are processed locally and are not uploaded to a Docsy server. Files selected for the library are copied into Docsy's private app storage; removing a library entry deletes that private copy when possible, but does not delete the original file. The recent-file list stores app-private paths, and preferences store the selected language and theme. Uninstalling the app removes its private copies.
