# Docsy

Docsy is a minimal, bilingual (Persian/English) Flutter document library for Android. The interface uses a restrained monochrome palette with a warm orange accent.

## Implemented

- Pick one or multiple supported files using Android's system file picker.
- Search filenames and filter the library by document type.
- Store a local recent-file list on the device (no account or cloud upload).
- Open PDFs in the app with the embedded PDF viewer.
- Preview TXT and CSV files in-app when they are no larger than 2 MiB.
- Open Office and other supported formats through a compatible app installed on the device.
- Switch between Persian/RTL and English/LTR.
- Switch between light and dark themes.

## Format support

| Format | Current behavior |
|---|---|
| PDF | In-app viewer |
| TXT, CSV | In-app text preview up to 2 MiB |
| DOC, DOCX, XLS, XLSX, PPT, PPTX, RTF, ODT, ODS, ODP | Open with a compatible installed app |

Docsy does not currently include a full Office rendering/editing engine. A compatible Android app is required for Office formats; availability and rendering fidelity depend on that app.

## Build and test

Requirements: Flutter stable, Dart SDK `>=3.4.0 <4.0.0`, and Android build tooling.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The APK is normally generated at `build/app/outputs/flutter-apk/app-release.apk`.

GitHub Actions runs analysis, widget tests, and a release APK build on pushes and pull requests. When the workflow succeeds, download the `docsy-android-apk` artifact from the run's **Artifacts** section.

## Release checklist

- [ ] Confirm analysis, tests, and release APK build all pass in GitHub Actions.
- [ ] Install and test the APK on a physical Android device.
- [ ] Verify file selection, PDF scrolling/zoom, TXT/CSV preview, external Office handoff, search, filters, language, and themes.
- [ ] Verify behavior when a remembered file has been moved or its access has expired.
- [ ] Set the final application ID, app icon, version, and signing configuration before store distribution.
- [ ] Test the signed release build before publishing.

## Privacy

Documents are processed locally. Docsy does not upload document contents to a server. The recent-file list stores file paths on the device; a path can stop working if a source file is moved or Android no longer grants access to it.
