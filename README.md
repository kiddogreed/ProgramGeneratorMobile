# P3 Church Program Generator – Mobile (Flutter Android)

A Flutter Android app for generating and managing LDS ward meeting programs.  
All data is stored **locally on-device** using SQLite — no server or internet connection required.

- **Ward**: Pasay 3rd Ward, Pasay Philippine Stake
- **App ID**: `com.church.programgenerator`
- **APK**: `installer/p3ProgramGenerator.apk`

---

## Version History

| Version | Build | Date | Notes |
|---|---|---|---|
| **1.0.0+2** | 2 | April 2026 | Full feature release — see changelog below |
| 1.0.0+1 | 1 | April 2026 | Initial release |

---

## Changelog — v1.0.0+2

### PDF
- **Single-page scalable PDFs** — all three program types (Sacrament, Bishopric, Ward Council) auto-shrink to fit one page using `pw.FittedBox(contain)` + `pw.Spacer()` bottom anchor
- **Correct Sacrament PDF field order** — Date → Presiding → Conducting → Acknowledgement → Announcements → Chorister/Pianist → Opening Hymn → Invocation → Ward/Stake Business → Sacrament Hymn → Reverence → Speakers → Closing Hymn → Benediction → Attendance
- **Export DOCX removed** — PDF is the sole export format

### Speaker Rotation
- **Fast & Testimony** — 1st Sunday is always Fast & Testimony (no speaker)
- **Stake leaders** — 3rd Sunday label corrected to `Stake leaders`
- **Bishopric** — 5th Sunday label corrected to `Bishopric`
- **Cycle slots** — 2nd and 4th Sundays draw from configurable auxiliary cycle lists
- **Fast & Testimony option in Rules** — cycle slot dropdowns show `— Fast & Testimony (no speaker) —` as first option

### Management Screens
- **Auxiliary management** — full CRUD (add / edit / delete) for auxiliaries used in speaker cycle
- **Auxiliary Admin** — duplicate name check; warns if deleting an auxiliary referenced in rotation
- **Speaker list admin** — manage the full speaker pool
- **Hymn & Handbook admin** — manage hymns and handbook readings

### Automation Rules
- **Bishop Name** — auto-fills Presiding on Sacrament & Bishopric forms
- **Bishopric preferred day** — full Monday–Sunday dropdown
- **Speaker cycle base month** — configurable start month for the 5-week cycle
- **Cycle slot dropdowns** — 2nd (slots 1/2/3) and 4th (slots 1/2/3) Sunday slots configurable from Auxiliaries list

### Other
- **Save to Downloads** — writes PDF to `/storage/emulated/0/Download/` with runtime permission handling for all Android API levels
- **Default Data Setup** — one-tap seed of conductors, musicians, and auxiliaries
- **App icon** — P3 church building logo (all mipmap sizes)
- **DB v4** — migrated from v3; adds `cycle2_slot1/2/3`, `cycle4_slot1/2/3`, `bishop_name` columns to `ward_config`

---

## Features

| Feature | Details |
|---|---|
| **3 program types** | Sacrament Meeting, Ward Council, Bishopric Meeting |
| **Full forms** | All fields matching the reference Java back-end models |
| **PDF export** | Single-page scalable, auto-shrink, correct field order |
| **Save to Downloads** | Saves PDF directly to device Downloads folder |
| **Print** | Native Android print via `printing` package |
| **Share** | Share PDF via Android share sheet |
| **Musician management** | Add / edit / delete Choristers and Pianists |
| **Conductor management** | Per meeting type with round-robin rotation (no consecutive repeats) |
| **Auxiliary management** | Full CRUD; used as cycle slot labels |
| **Speaker list** | Full CRUD speaker pool |
| **Hymn / Handbook admin** | Manage hymn and handbook reading libraries |
| **Program history** | Save, browse, load, and delete previous programs |
| **Automation Rules** | Bishop name, meeting day, speaker cycle slots, ward config |
| **Speaker cycle preview** | Next 8 Sundays with occurrence, label, and auxiliary |
| **Default Data Setup** | One-tap seed of all ward defaults |
| **Offline** | 100% local SQLite; no backend required |

---

## Project Structure

```
lib/
├── main.dart
├── database/
│   └── database_helper.dart         # SQLite via sqflite (DB v4)
├── models/
│   ├── sacrament_program.dart
│   ├── bishopric_program.dart
│   ├── ward_council_program.dart
│   ├── speaker.dart
│   ├── agenda_item.dart
│   ├── musician.dart
│   ├── conductor.dart
│   ├── auxiliary.dart
│   ├── ward_config.dart             # All automation rules (v4 fields)
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
│   ├── rules/
│   │   └── rules_screen.dart        # Automation Rules + cycle slot config
│   └── admin/
│       ├── auxiliary_admin_screen.dart
│       ├── musician_admin_screen.dart
│       ├── conductor_admin_screen.dart
│       ├── speaker_list_admin_screen.dart
│       ├── hymn_admin_screen.dart
│       ├── handbook_admin_screen.dart
│       └── seed_defaults_screen.dart
├── utils/
│   ├── pdf_generator.dart           # Single-page scalable PDFs (all types)
│   ├── rotation_service.dart        # Scheduling logic (speakers, conductors, prayers)
│   └── program_storage.dart         # Save/load program history
└── widgets/
    ├── labeled_field.dart
    ├── speaker_list_editor.dart
    ├── agenda_item_editor.dart
    └── announcements_editor.dart
```

---

## How to Build

### Prerequisites
- Flutter SDK ≥ 3.0
- Android SDK / connected Android device or emulator
- JDK 17+
- Keystore: `upload-keystore.jks` at project root; `android/key.properties` must be present

### Commands

```bash
# Get dependencies
flutter pub get

# Run in debug mode on connected device
flutter run

# Build release APK (fat APK)
flutter build apk --release

# Build split APKs (smaller, recommended for direct install)
flutter build apk --release --split-per-abi
```

For the split build, use `app-arm64-v8a-release.apk` on most modern Android phones.

### Using the build script

```powershell
.\Build-Installer.ps1
```

Outputs `installer/p3ProgramGenerator.apk` (signed, fat APK, ~56 MB).

### App ID
`com.church.programgenerator`

---

## Releases

### v1.0.0+2 (April 2026)
- APK: `installer/p3ProgramGenerator.apk`
- Also at: `build/app/outputs/flutter-apk/p3ProgramGenerator.apk`

### v1.0.0+1 (April 2026)
- Initial working release

---

For full technical details, see [FLUTTER_APP_REFERENCE.md](FLUTTER_APP_REFERENCE.md).
