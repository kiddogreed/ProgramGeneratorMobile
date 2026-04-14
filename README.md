# Church Program Generator – Mobile (Flutter Android)

A Flutter Android app that replicates all features of the Spring Boot Church Program Generator web application.  All data is stored **locally on-device** using SQLite – no server or internet connection required.

---

## Features

| Feature | Details |
|---|---|
| **3 program types** | Sacrament Meeting, Ward Council, Bishopric Meeting |
| **Full forms** | All fields matching the Java back-end models |
| **Musician management** | Add / edit / delete Choristers and Pianists |
| **Conductor management** | Per meeting type (Sacrament / Bishopric / Ward Council) |
| **Program history** | Save, browse, filter, load, and delete previous programs |
| **PDF export** | Full-page letter-format PDF matching the web preview |
| **Print** | Native Android print via `printing` package |
| **Share** | Share PDF via Android share sheet (email, Messenger, Drive, etc.) |
| **Offline** | 100 % local; no backend required |

---

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── database/
│   └── database_helper.dart         # SQLite with sqflite
├── models/
│   ├── sacrament_program.dart
│   ├── bishopric_program.dart
│   ├── ward_council_program.dart
│   ├── speaker.dart
│   ├── agenda_item.dart
│   ├── musician.dart
│   ├── conductor.dart
│   ├── auxiliary.dart
│   └── saved_program.dart
├── screens/
│   ├── home_screen.dart
│   ├── sacrament/
│   │   ├── sacrament_form_screen.dart
│   │   └── sacrament_preview_screen.dart
│   ├── bishopric/
│   │   ├── bishopric_form_screen.dart
│   │   └── bishopric_preview_screen.dart
│   ├── ward_council/
│   │   ├── ward_council_form_screen.dart
│   │   └── ward_council_preview_screen.dart
│   ├── history/
│   │   └── history_screen.dart
│   └── admin/
│       ├── musician_admin_screen.dart
│       └── conductor_admin_screen.dart
├── utils/
│   ├── pdf_generator.dart           # Builds PDF from any program type
│   └── program_storage.dart         # Save/load helpers
└── widgets/
    ├── labeled_field.dart
    ├── speaker_list_editor.dart
    ├── agenda_item_editor.dart
    └── announcements_editor.dart
```

---

## How to Build

### Prerequisites
- Flutter SDK ≥ 3.0  ([flutter.dev/docs/get-started/install](https://docs.flutter.dev/get-started/install/windows/android))
- Android SDK / an Android device or emulator
- JDK 17+

### Steps

```bash
# 1. Get dependencies
flutter pub get

# 2. Run on a connected Android device
flutter run

# 3. Build a release APK
flutter build apk --release

# 4. Install on device
flutter install
```

### App ID
`com.church.programgenerator`

---

## MVP Release (April 2026)

- All features from the Spring Boot reference implemented in Flutter
- 100% offline, local SQLite storage
- Sacrament, Bishopric, and Ward Council forms with full field parity
- Automation Rules screen for ward config, logo, and schedule
- CRUD for hymns, handbook readings, speaker rotation, musicians, conductors, auxiliaries
- Auto-rotation for prayers, speakers, conductors
- Export to PDF (all), DOCX (Sacrament), PNG (Ward Council)
- Program history with load/edit/delete
- Centralized error handling and validation
- Release APKs built and tested on emulator and real device
- To install: use `app-arm64-v8a-release.apk` from `build/app/outputs/flutter-apk/` (no compression/renaming)

---

## How to Build a Split APK (Recommended)

```bash
flutter build apk --release --split-per-abi
```

- Use `app-arm64-v8a-release.apk` for most modern Android phones.
- Transfer the APK directly to your device and install (enable "Unknown sources" if prompted).

---

For full technical details and future plans, see `FLUTTER_APP_REFERENCE.md`.
