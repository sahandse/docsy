# Docsy

A minimal, bilingual (Persian/English) Flutter document hub for Android, designed around a clean black-and-white interface.

## Current scope

- Pick multiple documents through Android's system file picker.
- Filter the library by PDF, Word/text, spreadsheets, and presentations.
- Search filenames.
- Remember a recent-file list locally.
- Open a selected file with a compatible viewer installed on the device.
- Light and dark themes.
- Persian and English interface toggle.

## Important format support note

Docsy currently acts as a document library and launcher. It delegates rendering of PDF, DOC/DOCX, XLS/XLSX, PPT/PPTX, ODT/ODS/ODP and other supported files to compatible Android apps installed on the device. It does **not** yet embed a complete office rendering engine, so in-app rendering and guaranteed support for every format are not claimed.

## Requirements

- Flutter stable (Dart SDK `>=3.4.0 <4.0.0`)
- Android SDK and Android Studio for Android builds

## Run locally

    flutter pub get
    flutter analyze
    flutter test
    flutter run

## Build an APK

    flutter build apk --release

The release APK will normally be created at `build/app/outputs/flutter-apk/app-release.apk`.

## Roadmap

1. Add a dedicated in-app PDF renderer and page navigation.
2. Add safe in-app text and CSV previews.
3. Evaluate an offline Office rendering engine for DOCX, XLSX and PPTX, including Persian typography and complex layouts.
4. Add import/open-in integration tests and test on physical Android devices.
5. Produce signed release builds only after device-level validation.

## Privacy

The app does not upload documents to a server. File access and opening are handled locally through Android and installed compatible apps. Recent file paths are stored locally; a saved path may become unavailable if the source file is moved or its access permission expires.
