# P3 Church Program Generator – Mobile (Flutter Android)

A Flutter Android app for generating and managing LDS ward meeting programs.  
All data is stored **locally on-device** using SQLite — no server or internet connection required.

- **Ward**: Pasay 3rd Ward, Pasay Philippine Stake
- **App ID**: `com.church.programgenerator`
- **APK**: `installer/p3ProgramGenerator_v1.2.0.apk`

---

## Version History

| Version | Build | Date | Notes |
|---|---|---|---|
| **1.2.0+4** | 4 | April 16, 2026 | Voice input (agenda, announcements, meeting notes), center alignment fix, acknowledgement template cleanup |
| **1.1.0+3** | 3 | April 15, 2026 | UI polish, PDF fill, multi-line ward business, form improvements |
| **1.0.0+2** | 2 | April 2026 | Full feature release |
| **1.0.0+1** | 1 | April 2026 | Initial release |

---

## Changelog — v1.2.0+4 (April 16, 2026)

### Features & Improvements
- **Offline voice input everywhere**
  - Agenda items (Bishopric & Ward Council) — tap mic to dictate
  - Sacrament Announcements — mic per row
  - New Meeting Notes screen — voice dictation, text export
- **Meeting Notes screen** — from home menu, take notes by typing or voice, export as .txt
- **Agenda section centered** — Bishopric preview agenda header and items now center-aligned
- **Dropdown overflow fix** — all dropdowns in Bishopric and Ward Council forms use `isExpanded: true` (no more 40px overflow)
- **Acknowledgement template cleaned** — removed hardcoded names, now only uses template tokens

### Fixes
- Fixed: DropdownButtonFormField overflow in Bishopric and Ward Council forms
- Fixed: Agenda preview alignment (centered)
- Fixed: Announcements editor now supports voice input per row
- Fixed: Meeting Notes screen voice input and export
- Fixed: Acknowledgement template no longer has redundant hardcoded names

---

## Changelog — v1.1.0+3 (April 15, 2026)

### UI / Home Screen
- **Removed cross icon** — replaced `Icons.church` (Material icon with a cross) with the P3 ward building logo (`P3_LOGO.png`). The cross symbol is not used in LDS churches.

### Sacrament PDF
- **Full-page layout** — PDF content now fills the entire A4 page using distributed `Spacer()` widgets between sections (header, body, speakers, footer). No more large empty bottom half.
- **Larger text** — label/value font sizes increased from 10–11 pt to 12–13 pt for better readability.
- **Attendance line** — stays anchored at the bottom-right of the page.

### Sacrament Form
- **Ward Business multi-line** — field now accepts multiple lines (up to 5 rows). Press Enter to add a new line. Example:
  ```
  release: secretary
  sustain: president
  ```

### Ward Council Form
- **Presiding is now a dropdown** — populated from the Sacrament conductors list (bishop, counselors). No longer a free-text field.
- **Welfare field removed** — the Welfare text box has been removed. Use Agenda Items for welfare topics.

### Bishopric Meeting Form
- **Callings & Releases removed** — the Callings & Releases text field has been removed from the form and PDF. Use Agenda Items for callings/releases business.

---

## Changelog — v1.0.0+2 (April 2026)

### PDF
- **Single-page scalable PDFs** — all three program types auto-shrink to fit one page
- **Correct Sacrament PDF field order** — Date → Presiding → Conducting → Acknowledgement → Announcements → Chorister/Pianist → Opening Hymn → Invocation → Ward/Stake Business → Sacrament Hymn → Reverence → Speakers → Closing Hymn → Benediction → Attendance

### Speaker Rotation
- Fast & Testimony on 1st Sunday, Stake leaders on 3rd, Bishopric on 5th
- 2nd and 4th Sundays draw from configurable auxiliary cycle lists

### Management Screens
- Full CRUD for Auxiliaries, Speaker list, Hymns, Handbook readings
- Duplicate name check; warns if deleting auxiliaries referenced in rotation

### Automation Rules
- Bishop name auto-fills Presiding
- Bishopric preferred day (Monday–Sunday)
- Speaker cycle base month, 2nd/4th Sunday slot assignments

### Other
- Save to Downloads (PDF → `/storage/emulated/0/Download/`)
- Default Data Setup — one-tap seed of conductors, musicians, auxiliaries
- App icon — P3 church building logo
- DB v4 — `cycle2_slot1/2/3`, `cycle4_slot1/2/3`, `bishop_name` columns

---

## Features

| Feature | Details |
|---|---|
| **3 program types** | Sacrament Meeting, Ward Council, Bishopric Meeting |
| **Full forms** | All fields matching the reference Java back-end models |
| **PDF export** | Single-page scalable, full-page fill, correct field order |
| **Save to Downloads** | Saves PDF directly to device Downloads folder |
| **Print** | Native Android print via `printing` package |
| **Share** | Share PDF via Android share sheet |
| **Musician management** | Add / edit / delete Choristers and Pianists |
| **Conductor management** | Per meeting type with round-robin rotation |
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
│   ├── ward_config.dart
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
│   │   └── rules_screen.dart
│   └── admin/
│       ├── auxiliary_admin_screen.dart
│       ├── musician_admin_screen.dart
│       ├── conductor_admin_screen.dart
│       ├── speaker_list_admin_screen.dart
│       ├── hymn_admin_screen.dart
│       ├── handbook_admin_screen.dart
│       └── seed_defaults_screen.dart
├── utils/
│   ├── pdf_generator.dart
│   ├── rotation_service.dart
│   └── program_storage.dart
└── widgets/
    ├── labeled_field.dart
    ├── speaker_list_editor.dart
    ├── agenda_item_editor.dart
    └── announcements_editor.dart
```

---

## Development Guide

### Prerequisites

| Tool | Version |
|---|---|
| Flutter SDK | ≥ 3.0 |
| Dart SDK | ≥ 3.0 |
| Android SDK | API 21+ (Android 5.0+) |
| JDK | 17+ |
| Android emulator or physical device | — |

### 1. Get Dependencies

```bash
flutter pub get
```

### 2. Run on Android Emulator

Start an Android emulator from Android Studio (AVD Manager), then:

```bash
# List available devices
flutter devices

# Run in debug mode (picks connected device/emulator automatically)
flutter run

# Run on a specific device by ID
flutter run -d <device-id>

# Example
flutter run -d emulator-5554
```

The app will build, install, and launch on the emulator automatically.

### 3. Hot Reload & Hot Restart

While `flutter run` is active in your terminal:

| Key | Action | When to use |
|---|---|---|
| `r` | **Hot Reload** | UI/widget changes — rebuilds widget tree instantly (~300 ms) |
| `R` | **Hot Restart** | State/logic changes — restarts the app from scratch (~1.5 s) |
| `q` | **Quit** | Stop the app and exit flutter run |
| `h` | **Help** | List all available commands |

> **Tip:** Hot reload preserves app state (e.g. form data) — use it for layout tweaks.  
> Hot restart clears all state — use it after changing business logic, models, or database migrations.

### 4. Build Release APK

#### Option A — Using the PowerShell build script (recommended)

```powershell
.\Build-Installer.ps1
```

Outputs `installer/p3ProgramGenerator.apk` (signed fat APK).

#### Option B — Flutter CLI

```bash
# Fat APK (all architectures, ~56 MB)
flutter build apk --release

# Split APKs (smaller per-architecture builds)
flutter build apk --release --split-per-abi
```

For split builds, install the correct ABI for your device:
- `app-arm64-v8a-release.apk` — most modern phones (64-bit ARM)
- `app-armeabi-v7a-release.apk` — older 32-bit ARM phones
- `app-x86_64-release.apk` — x86 emulators

Output location: `build/app/outputs/flutter-apk/`

#### Keystore Setup (required for signed APK)

Ensure `android/key.properties` is present:

```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload
storeFile=../upload-keystore.jks
```

The keystore file `upload-keystore.jks` must be at the project root. See `android/key.properties.template` for the template.

### 5. Versioning Convention

Version format: `major.minor.patch+buildNumber`

| Component | When to increment |
|---|---|
| `major` | Complete rewrite or breaking change |
| `minor` | New features or significant improvements |
| `patch` | Bug fixes or small tweaks |
| `buildNumber` | Every APK build (auto-increments) |

**Current version**: `1.2.0+4`

Update in `pubspec.yaml`:

```yaml
version: 1.2.0+4
```

---

## Releases

### v1.2.0+4 (April 16, 2026)
- APK: `installer/p3ProgramGenerator_v1.2.0.apk`
- Changes: Voice input (agenda, announcements, meeting notes), center alignment fix, acknowledgement template cleanup

### v1.1.0+3 (April 15, 2026)
- APK: `installer/p3ProgramGenerator_v1.1.0.apk`
- Changes: Logo icon fix, full-page PDF, multi-line ward business, Ward Council presiding dropdown, Bishopric form cleanup

### v1.0.0+2 (April 2026)
- APK: (archived)
- Full feature release

### v1.0.0+1 (April 2026)
- Initial working release

---

## Roadmap

### Near-term
- [ ] **Sacrament attendance tracking** — tap-to-increment counter stored per program
- [ ] **Ward Council auxiliary report** — select which auxiliary is presenting each week
- [ ] **PDF font size setting** — user-configurable font scale per program type
- [ ] **Dark mode** — system-aware dark/light theme toggle
- [x] **Offline Voice Input for Agenda** — Use device mic and free local AI (offline speech-to-text) to add agenda items in Bishopric Meeting, Ward Council, and Sacrament announcements

### Mid-term
- [ ] **Program templates** — save a partially-filled form as a reusable template
- [ ] **Email export** — send PDF directly via email without sharing manually
- [ ] **Multiple wards** — support more than one ward configuration in the same app
- [ ] **Backup & restore** — export/import the full SQLite database as a JSON or ZIP archive
- [ ] **Anniversary/holiday banners** — auto-add holiday notice on program PDFs (Christmas, Easter)

### Long-term
- [ ] **iOS support** — port to iPhone/iPad via the existing Flutter codebase
- [ ] **Web version** — deploy as a Progressive Web App for in-browser use
- [ ] **Cloud sync** — optional Firebase sync so bishop's secretary can share programs with other devices
- [ ] **Bishopric approval workflow** — mark programs as "pending review" / "approved" before printing

---

For full technical details, see [FLUTTER_APP_REFERENCE.md](FLUTTER_APP_REFERENCE.md).

