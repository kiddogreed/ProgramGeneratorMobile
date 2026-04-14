# Flutter Android App Reference
## Pasay 3rd Ward Program Generator — Flutter Version Specification

**Source**: Translated from the working Spring Boot web app (April 2026).  
**Purpose**: This document is the complete specification for building the Flutter Android app. Every screen, data model, business logic, and behavior described here must match the Spring Boot version exactly.

---

## Table of Contents

1. [App Overview](#1-app-overview)
2. [Project Structure](#2-project-structure)
3. [Data Models (Dart)](#3-data-models-dart)
4. [Local Database Schema (SQLite)](#4-local-database-schema-sqlite)
5. [Scheduling Logic Service (Dart)](#5-scheduling-logic-service-dart)
6. [Screen: Sacrament Meeting Form](#6-screen-sacrament-meeting-form)
7. [Screen: Bishopric Meeting Form](#7-screen-bishopric-meeting-form)
8. [Screen: Ward Council Meeting Form](#8-screen-ward-council-meeting-form)
9. [Screen: Preview](#9-screen-preview)
10. [Export: PDF, DOCX, PNG](#10-export-pdf-docx-png)
11. [Screen: History](#11-screen-history)
12. [Screen: Manage](#12-screen-manage)
13. [Screen: Rules](#13-screen-rules)
14. [Navigation](#14-navigation)
15. [UI/UX Requirements](#15-uiux-requirements)
16. [Recommended Packages](#16-recommended-packages)

---

## 1. App Overview

| Property | Value |
|---|---|
| Platform | Android (Flutter) |
| Mode | Fully offline — local SQLite database, no server |
| Language | Dart / Flutter |
| Min SDK | Android 6.0+ (API 23) |
| Navigation | Bottom navigation bar or Drawer with 7 destinations |
| Logo asset | `assets/images/LDS_LOGO.png` — embedded in every document export |

### Navigation Destinations (in order)
1. **Home** — welcome screen with quick-action buttons
2. **Sacrament** — meeting program form
3. **Bishopric** — meeting form
4. **Ward Council** — meeting form
5. **History** — saved programs browser
6. **Manage** — manage lists (conductors, auxiliaries, musicians)
7. **Rules** — scheduling configuration

---

## 2. Project Structure

```
lib/
├── main.dart
├── app.dart                         # MaterialApp, routes, theme
├── db/
│   └── database_helper.dart         # SQLite init, migrations, singleton
├── models/
│   ├── ward_config.dart
│   ├── conductor.dart
│   ├── auxiliary.dart
│   ├── musician.dart
│   ├── saved_program.dart
│   ├── sacrament_program.dart
│   ├── bishopric_program.dart
│   ├── ward_council_program.dart
│   ├── speaker.dart
│   └── agenda_item.dart
├── repositories/
│   ├── ward_config_repository.dart
│   ├── conductor_repository.dart
│   ├── auxiliary_repository.dart
│   ├── musician_repository.dart
│   └── saved_program_repository.dart
├── services/
│   ├── ward_config_service.dart     # Scheduling logic, round-robin, date calc
│   ├── program_storage_service.dart # JSON serialize/deserialize + save/load
│   ├── export_service.dart          # PDF, DOCX, PNG generation
│   └── acknowledgement_service.dart # Template substitution
├── screens/
│   ├── home_screen.dart
│   ├── sacrament_form_screen.dart
│   ├── bishopric_form_screen.dart
│   ├── ward_council_form_screen.dart
│   ├── preview_screen.dart
│   ├── history_screen.dart
│   ├── manage_screen.dart
│   └── rules_screen.dart
├── widgets/
│   ├── app_navigation.dart          # Bottom nav or Drawer
│   ├── speaker_row_widget.dart      # Dynamic speaker add/remove
│   ├── agenda_row_widget.dart       # Dynamic agenda add/remove
│   ├── locked_field_widget.dart     # Read-only blue-tinted field (Presiding)
│   ├── flash_message_widget.dart    # SnackBar/banner for success/error
│   ├── speaker_cycle_badge.dart     # Colored badge showing speaker type hint
│   └── paginated_list_widget.dart   # Reusable paginated list
assets/
├── images/
│   └── LDS_LOGO.png
```

---

## 3. Data Models (Dart)

### WardConfig
```dart
class WardConfig {
  int id = 1; // always 1 — singleton

  // Organization
  String stakeName = 'Pasay Philippine Stake';
  String wardName = 'Pasay 3rd Ward';
  String acknowledgementTemplate =
      'Acknowledge {OTHER_CONDUCTORS}, Bro. Adrian Matro (wrd Clrk), '
      'Johanne Perlas (Asst. Clrk. rec). Bro. Norman Oliva (Asst. Clrk. fin), '
      'John Russelle Domingo (wrd exc. Secr.), Genesis Ferareza (wrd exc. Asst. Secr.). '
      '{BISHOPRIC_OTHERS} To all Visitors and Stake Leaders (Welcome).';

  // Sacrament
  String sacramentTime = '09:00';

  // Bishopric
  String bishopricPreferredDay = 'Thursday'; // or 'Sunday'
  String bishopricThursdayTime = '19:00';
  String bishopricSundayTime = '12:00';

  // Ward Council
  String wardCouncilOccurrences = '1,3'; // e.g. 1st and 3rd Sundays
  String wardCouncilTime = '11:00';

  // Speaker Cycle
  String speakerCycleBaseMonth = '2026-01'; // yyyy-MM

  // Conductor Round-Robin Tracking
  int? lastSacramentConductorId;
  int? lastBishopricConductorId;

  // Prayer/Handbook Rotation Indices
  int? wcOpeningPrayerIdx;
  int? wcClosingPrayerIdx;
  int? wcHandbookIdx;
  int? bpOpeningPrayerIdx;
  int? bpClosingPrayerIdx;
  int? bpHandbookIdx;
}
```

### Conductor
```dart
class Conductor {
  int? id;
  String name;
  int displayOrder;
  String programType; // 'sacrament' or 'bishopric'
}
```

### Auxiliary
```dart
class Auxiliary {
  int? id;
  String name; // unique
}
```

### Musician
```dart
class Musician {
  int? id;
  String name;
  String musicianType; // 'chorister' or 'pianist'
  int displayOrder;
}
```

### SavedProgram
```dart
class SavedProgram {
  int? id;
  String meetingType;   // 'SACRAMENT', 'BISHOPRIC', 'WARD_COUNCIL'
  String description;   // e.g. "Sacrament – Pasay 3rd Ward – 2026-04-13"
  DateTime meetingDate;
  String programData;   // full JSON of the program object
  DateTime createdAt;
}
```

### SacramentProgram
```dart
class SacramentProgram {
  String stakeName;
  String wardName;
  DateTime date;
  String presiding;
  String conducting;
  String acknowledgement;
  List<String> announcements;
  String chorister;
  String pianist;
  String openingHymn;
  String sacramentHymn;
  String closingHymn;
  String invocation;
  String wardBusiness;     // max 400 chars
  String stakeBusiness;    // max 400 chars
  List<Speaker> speakers;
  String speakersAuxiliary;
  String benediction;
}
```

### Speaker
```dart
class Speaker {
  int order;
  String name;
  String title;
}
```

### BishopricProgram
```dart
class BishopricProgram {
  String wardName;
  DateTime meetingDate;
  String presiding;       // always the Bishop — locked
  String conducting;
  String openingPrayer;
  String handbookSpiritual;
  List<AgendaItem> agendaItems;
  String callingsAndReleases; // max 500 chars
  String closingPrayer;
}
```

### WardCouncilProgram
```dart
class WardCouncilProgram {
  String wardName;
  DateTime meetingDate;
  String presiding;       // always the Bishop — locked
  String conducting;
  String openingPrayer;
  String handbookReading;
  List<AgendaItem> agendaItems;
  String welfare;
  String closingPrayer;
}
```

### AgendaItem
```dart
class AgendaItem {
  String title;
  String notes;
}
```

---

## 4. Local Database Schema (SQLite)

Use `sqflite` or `drift`. Create these tables on first run. Use `onUpgrade` for migrations.

### `ward_config`
```sql
CREATE TABLE ward_config (
  id INTEGER PRIMARY KEY DEFAULT 1,
  stake_name TEXT,
  ward_name TEXT,
  acknowledgement_template TEXT,
  sacrament_time TEXT,
  bishopric_preferred_day TEXT,
  bishopric_thursday_time TEXT,
  bishopric_sunday_time TEXT,
  ward_council_occurrences TEXT,
  ward_council_time TEXT,
  speaker_cycle_base_month TEXT,
  last_sacrament_conductor_id INTEGER,
  last_bishopric_conductor_id INTEGER,
  wc_opening_prayer_idx INTEGER,
  wc_closing_prayer_idx INTEGER,
  wc_handbook_idx INTEGER,
  bp_opening_prayer_idx INTEGER,
  bp_closing_prayer_idx INTEGER,
  bp_handbook_idx INTEGER
);
-- Insert defaults on first run (id = 1)
```

### `conductors`
```sql
CREATE TABLE conductors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  display_order INTEGER NOT NULL DEFAULT 0,
  program_type TEXT NOT NULL DEFAULT 'sacrament'
);
```

### `auxiliaries`
```sql
CREATE TABLE auxiliaries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);
```

### `musicians`
```sql
CREATE TABLE musicians (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  musician_type TEXT NOT NULL DEFAULT 'chorister',
  display_order INTEGER NOT NULL DEFAULT 0
);
```

### `saved_programs`
```sql
CREATE TABLE saved_programs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  meeting_type TEXT NOT NULL,
  description TEXT NOT NULL,
  meeting_date TEXT NOT NULL,
  program_data TEXT NOT NULL,
  created_at TEXT NOT NULL
);
```

### Initial Seed Data
On first launch (empty DB), seed the following so forms are usable immediately:
- Ward Config row (id=1) with defaults listed in `WardConfig` model
- At least one sacrament conductor named "Bishop [Name]" so presiding detection works from day one

---

## 5. Scheduling Logic Service (Dart)

Implement `WardConfigService` in Dart — all logic must match the Java original exactly.

```dart
// Returns nearest upcoming Sunday (today if today is Sunday)
DateTime nextSacramentDate() {
  final today = DateTime.now();
  final daysToSunday = today.weekday == DateTime.sunday
      ? 0
      : DateTime.sunday - today.weekday; // weekday: Mon=1 … Sun=7
  return DateTime(today.year, today.month, today.day + daysToSunday);
}

// Returns next Thursday (or Sunday) strictly in the future (never today)
DateTime nextBishopricDate(WardConfig cfg) {
  final today = DateTime.now();
  final target = cfg.bishopricPreferredDay == 'Sunday'
      ? DateTime.sunday : 4; // Thursday = 4
  int daysUntil = (target - today.weekday + 7) % 7;
  if (daysUntil == 0) daysUntil = 7; // skip today
  return DateTime(today.year, today.month, today.day + daysUntil);
}

// Returns next Sunday matching ward_council_occurrences
DateTime nextWardCouncilDate(WardConfig cfg) {
  final occurrences = cfg.wardCouncilOccurrences
      .split(',').map(int.parse).toList();
  var candidate = nextSacramentDate();
  for (int i = 0; i < 8; i++) {
    if (occurrences.contains(getSundayOccurrence(candidate))) return candidate;
    candidate = candidate.add(const Duration(days: 7));
  }
  return candidate;
}

// Which occurrence (1st, 2nd … 5th) of the month is this Sunday?
int getSundayOccurrence(DateTime date) => (date.day - 1) ~/ 7 + 1;

// 3-month cycle number (1, 2, or 3) for the given date
int getSpeakerCycleNumber(DateTime date, String baseMonth) {
  final parts = baseMonth.split('-');
  final baseYear = int.parse(parts[0]);
  final baseMonthNum = int.parse(parts[1]);
  final elapsed = (date.year - baseYear) * 12 + (date.month - baseMonthNum);
  return ((elapsed % 3) + 3) % 3 + 1;
}

// Human-readable speaker type label
String getSpeakerTypeLabel(DateTime sunday, WardConfig cfg) {
  final occurrence = getSundayOccurrence(sunday);
  switch (occurrence) {
    case 1: return 'Fast & Testimony';
    case 3: return 'Stake Assignment';
    case 5: return 'Bishopric Special';
    case 2:
      final cycle = getSpeakerCycleNumber(sunday, cfg.speakerCycleBaseMonth);
      if (cycle == 1) return 'Relief Society';
      if (cycle == 2) return 'Elders Quorum';
      return 'Ward Mission & Family History';
    default: // 4th Sunday
      final cycle = getSpeakerCycleNumber(sunday, cfg.speakerCycleBaseMonth);
      if (cycle == 1) return 'Sunday School';
      if (cycle == 2) return 'Primary';
      return 'Youth';
  }
}

// Round-robin: next conductor after lastUsedId
Conductor? getSuggestedConductor(List<Conductor> conductors, int? lastUsedId) {
  if (conductors.isEmpty) return null;
  if (lastUsedId == null) return conductors.first;
  final lastIndex = conductors.indexWhere((c) => c.id == lastUsedId);
  final nextIndex = (lastIndex + 1) % conductors.length;
  return conductors[nextIndex];
}

// Returns 3 consecutive different indices after baseIdx
List<int> nextThreeIndices(int listLength, int? baseIdx) {
  final base = baseIdx ?? -1;
  return [
    (base + 1) % listLength,
    (base + 2) % listLength,
    (base + 3) % listLength,
  ];
}

// Acknowledgement template substitution
String buildAcknowledgement(
    String template, String conducting,
    List<Conductor> sacramentConductors,
    List<Conductor> bishopricConductors) {
  final otherConductors = sacramentConductors
      .where((c) => c.name.toLowerCase() != conducting.toLowerCase())
      .map((c) => c.name)
      .join(', ');
  final bishop = bishopricConductors.firstWhere(
      (c) => c.name.toLowerCase().startsWith('bishop'),
      orElse: () => Conductor(name: ''));
  final bishopricOthers = bishopricConductors
      .where((c) => c.name != bishop.name && c.name.toLowerCase() != conducting.toLowerCase())
      .map((c) => c.name)
      .join(', ');
  return template
      .replaceAll('{OTHER_CONDUCTORS}', otherConductors)
      .replaceAll('{BISHOPRIC_OTHERS}', bishopricOthers);
}
```

---

## 6. Screen: Sacrament Meeting Form

**Route**: `/sacrament`  
**Widget**: `SacramentFormScreen` (single scrollable screen)

### On Load
1. Read `WardConfig` from DB (id=1)
2. Set `stakeName`, `wardName`, `acknowledgement` from config
3. Compute `date = nextSacramentDate()`
4. Load sacrament conductors from DB (`program_type = 'sacrament'`, ordered by `display_order`)
5. Call `getSuggestedConductor(conductors, cfg.lastSacramentConductorId)` → pre-select in Conducting dropdown
6. Load auxiliaries, choristers, pianists from DB for dropdowns
7. Compute `speakerTypeLabel = getSpeakerTypeLabel(date, cfg)` → show as badge

### Fields (in order on screen)
| Field | Widget | Behavior |
|---|---|---|
| Stake Name | `TextFormField` | Pre-filled, editable |
| Ward Name | `TextFormField` | Pre-filled, editable |
| Meeting Date | `TextFormField` + `showDatePicker` | Pre-filled with next Sunday; tapping opens date picker |
| Presiding | `TextFormField` | Empty, manual entry |
| Conducting | `DropdownButtonFormField` | Pre-selected via round-robin; list from sacrament conductors |
| Chorister | `DropdownButtonFormField` | List from musicians (chorister) |
| Pianist | `DropdownButtonFormField` | List from musicians (pianist) |
| Opening Hymn | `TextFormField` | Manual entry |
| Sacrament Hymn | `TextFormField` | Manual entry |
| Closing Hymn | `TextFormField` | Manual entry |
| Invocation | `TextFormField` | Manual entry |
| Benediction | `TextFormField` | Manual entry |
| Ward Business | `TextFormField` multiline | max 400 chars |
| Stake Business | `TextFormField` multiline | max 400 chars |
| **Speaker Cycle Badge** | Custom badge widget | Show `speakerTypeLabel` — e.g. "Relief Society" |
| Speakers | Dynamic list of `SpeakerRowWidget` | Each row: Name (text) + Title (text). **Add Row** / **Remove Row** buttons |
| Speakers Auxiliary | `DropdownButtonFormField` | List from auxiliaries |
| Announcements | `TextFormField` multiline | Each line = one announcement |
| Acknowledgement | `TextFormField` multiline | max 600 chars; pre-filled from template |

### Buttons
- **Preview** → navigate to `PreviewScreen` passing the filled `SacramentProgram`
- **Clear** → reset all fields to defaults

---

## 7. Screen: Bishopric Meeting Form

**Route**: `/bishopric`  
**Widget**: `BishopricFormScreen`

### On Load
1. Read `WardConfig`
2. Set `wardName` from config
3. Compute `date = nextBishopricDate(cfg)`
4. Load bishopric conductors (`program_type = 'bishopric'`, ordered by `display_order`)
5. Call `getSuggestedConductor(conductors, cfg.lastBishopricConductorId)` → set Conducting
6. **Advance index**: call `markConductorUsed('bishopric', suggested.id)` → updates `last_bishopric_conductor_id` in DB immediately
7. Find Bishop: first conductor whose name starts with "Bishop" (case-insensitive) → set `presiding` (locked)
8. Call `nextThreeIndices(conductors.length, cfg.bpHandbookIdx)` → get idxs[0], idxs[1], idxs[2]
   - `openingPrayer = conductors[idxs[0]].name`
   - `handbookSpiritual = conductors[idxs[1]].name`
   - `closingPrayer = conductors[idxs[2]].name`
9. Save `idxs[2]` back to `ward_config.bp_handbook_idx` in DB

### Fields
| Field | Widget | Behavior |
|---|---|---|
| Ward Name | `TextFormField` | Pre-filled, editable |
| Meeting Date | `TextFormField` + date picker | Pre-filled with next Thursday/Sunday |
| Presiding | `LockedFieldWidget` | Blue-tinted read-only display; value = Bishop's name. Hidden but included on submit. |
| Conducting | `DropdownButtonFormField` | Pre-selected via round-robin; bishopric conductors |
| Opening Prayer | `DropdownButtonFormField` | Pre-selected from auto-assignment; bishopric conductors |
| Handbook Spiritual Thought | `DropdownButtonFormField` | Pre-selected; bishopric conductors |
| Agenda Items | Dynamic `AgendaRowWidget` list | Each row: Title (text) + Notes (text). Add/remove rows. |
| Callings & Releases | `TextFormField` multiline | max 500 chars |
| Closing Prayer | `DropdownButtonFormField` | Pre-selected; bishopric conductors |

### LockedFieldWidget
- Styled with blue border and light blue background
- Shows current value as non-editable text
- An invisible/hidden value is passed alongside form on submit (include the presiding name)

### Buttons
- **Preview** → `PreviewScreen`
- **Clear** → reset

---

## 8. Screen: Ward Council Meeting Form

**Route**: `/ward-council`  
**Widget**: `WardCouncilFormScreen`

### On Load
1. Read `WardConfig`
2. Set `wardName` from config
3. Compute `date = nextWardCouncilDate(cfg)`
4. Load bishopric conductors
5. `getSuggestedConductor(conductors, cfg.lastBishopricConductorId)` → set Conducting
6. Advance index: `markConductorUsed('bishopric', suggested.id)`
7. Find Bishop (name starts with "Bishop") → set `presiding` (locked)
8. Load auxiliaries list
9. Call `nextThreeIndices(auxiliaries.length, cfg.wcHandbookIdx)` → idxs[0], idxs[1], idxs[2]
   - `openingPrayer = auxiliaries[idxs[0]].name`
   - `handbookReading = auxiliaries[idxs[1]].name`
   - `closingPrayer = auxiliaries[idxs[2]].name`
10. Save `idxs[2]` back to `ward_config.wc_handbook_idx` in DB

### Fields
| Field | Widget | Behavior |
|---|---|---|
| Ward Name | `TextFormField` | Pre-filled, editable |
| Meeting Date | `TextFormField` + date picker | Pre-filled with next WC Sunday |
| Presiding | `LockedFieldWidget` | Always Bishop; blue-tinted read-only |
| Conducting | `DropdownButtonFormField` | Bishopric conductors; round-robin pre-selected |
| Opening Prayer | `DropdownButtonFormField` | Pre-selected from auxiliaries auto-assignment |
| Handbook Reading | `DropdownButtonFormField` | Pre-selected from auxiliaries auto-assignment |
| Agenda Items | Dynamic `AgendaRowWidget` list | Title + Notes per row; add/remove |
| Welfare | `TextFormField` multiline | Manual entry |
| Closing Prayer | `DropdownButtonFormField` | Pre-selected from auxiliaries auto-assignment |

### Buttons
- **Preview** → `PreviewScreen`
- **Clear** → reset

---

## 9. Screen: Preview

**Route**: `/preview` (receives a program object via Navigator arguments)  
**Widget**: `PreviewScreen`

### Behavior
- Receives one of `SacramentProgram`, `BishopricProgram`, or `WardCouncilProgram` + type indicator
- Renders a read-only, formatted view of the complete program
- Mirrors the layout of the exported document as closely as possible (same order of fields, same headers/footers, logo at top)
- Shows `LDS_LOGO.png` from assets at the top

### Buttons on Preview Screen
| Button | Action |
|---|---|
| **Export PDF** | Call `ExportService.generatePdf(program)` → save to local storage and share |
| **Export Word (.docx)** | (Sacrament & Bishopric only) Call `ExportService.generateDocx(program)` → save and share |
| **Export PNG** | (Ward Council only) Call `ExportService.generatePng(program)` → save and share |
| **Edit** | Pop back to form screen with the same program data pre-filled |

### Auto-Save on Export
Every export must save the program to `saved_programs` table before triggering the file download. Use `ProgramStorageService.save(program)`.

---

## 10. Export: PDF, DOCX, PNG

### PDF (Sacrament, Bishopric)
- Use the `pdf` Dart package to build a multi-section document
- **Sacrament PDF layout** (top to bottom):
  1. Logo (LDS_LOGO.png) centered, 80×80 pt
  2. Stake name (large, centered)
  3. Ward name (large, centered)
  4. Date (centered)
  5. Presiding / Conducting row
  6. Chorister / Pianist row
  7. Hymns (Opening, Sacrament, Closing)
  8. Invocation
  9. Speakers section (each speaker: Name, auxiliary, title)
  10. Announcements (bulleted)
  11. Ward/Stake Business
  12. Benediction
  13. Acknowledgement (italic, small)
- **Bishopric PDF layout**:
  1. Logo centered
  2. Ward name header
  3. Meeting date
  4. Formal table or sections: Presiding, Conducting, Opening Prayer, Handbook Spiritual Thought
  5. Agenda Items (numbered list)
  6. Callings & Releases
  7. Closing Prayer
  8. Footer with date and ward name
- Font auto-scales: if combined text is long, reduce font size proportionally to fit one page
- All text is dynamic — no hardcoded words except structural labels ("Presiding:", "Conducting:", etc.)

### Word (.docx) — Optional / Best-effort
- Use the `archive` package to create OOXML from a template
- Alternatively, generate an RTF file which Word can open
- Match same layout as the PDF version

### PNG (Ward Council)
- Render the Ward Council program into a Flutter widget tree off-screen using `RepaintBoundary` + `RenderRepaintBoundary.toImage()`
- Capture as PNG bytes, save and share
- Layout should mirror the web PNG: formal table with ward name, date, presiding, conducting, prayer/handbook assignments, agenda items, welfare, closing prayer

### File Storage
- Save exported files to the app's external storage documents directory using `path_provider` (`getExternalStorageDirectory()` or `getApplicationDocumentsDirectory()`)
- Filename format: `{type}_{ward}_{date}.{ext}` — e.g. `sacrament_pasay3rd_2026-04-13.pdf`
- After saving, trigger share dialog using `share_plus` so users can send it to group chats, print, etc.

---

## 11. Screen: History

**Route**: `/history`  
**Widget**: `HistoryScreen`

### Behavior
- Loads saved programs from `saved_programs` table, ordered by `created_at` descending
- **Page size**: 15 records per page
- **Filter bar** at top: ALL | SACRAMENT | BISHOPRIC | WARD_COUNCIL — tapping reloads the list for that type
- Each list item shows: meeting type chip, description, meeting date, created date

### Actions per Item
| Action | Behavior |
|---|---|
| **Load / Edit** | Deserialize `program_data` JSON back into the appropriate program model, navigate to the matching form screen with all fields pre-filled |
| **Delete** | Show confirm dialog → delete from DB → refresh list |

### Load Behavior (matches Spring Boot exactly)
- **Sacrament**: Rebuild `List<Speaker>` sorted by `order`, restore announcements as newline-joined text, pass all dropdown values to pre-select in form
- **Bishopric**: Rebuild `List<AgendaItem>` from JSON, pass to form
- **Ward Council**: Rebuild `List<AgendaItem>` from JSON, pass to form

---

## 12. Screen: Manage

**Route**: `/manage`  
**Widget**: `ManageScreen` with `TabBar` for each section

### Tab 1: Sacrament Conductors
- List `conductors` where `program_type = 'sacrament'`, ordered by `display_order`
- **Add**: text field + Add button → insert new conductor
- **Edit**: inline edit or tap-to-edit dialog → update name
- **Delete**: confirm dialog → delete

### Tab 2: Bishopric Conductors
- List `conductors` where `program_type = 'bishopric'`, ordered by `display_order`
- **Note**: The first entry whose name starts with "Bishop" is automatically used as Presiding in all Bishopric and Ward Council forms
- Same CRUD as Tab 1

### Tab 3: Auxiliaries
- List `auxiliaries` ordered by name
- **Add**: text field + Add button (duplicate name rejected)
- **Delete**: confirm dialog → delete

### Tab 4: Choristers
- List `musicians` where `musician_type = 'chorister'`
- **Add**: name + Add button
- **Edit**: tap to edit
- **Delete**: confirm dialog → delete

### Tab 5: Pianists
- List `musicians` where `musician_type = 'pianist'`
- Same CRUD as choristers

### Flash Messages
After every add/edit/delete operation show a `SnackBar` with "Added.", "Updated.", or "Deleted." in green or red.

---

## 13. Screen: Rules

**Route**: `/rules`  
**Widget**: `RulesScreen`

### Display Section (read-only, computed on load)
- **Next Sacrament Date**: computed `nextSacramentDate()`
- **Next Bishopric Date**: computed `nextBishopricDate(cfg)`
- **Next Ward Council Date**: computed `nextWardCouncilDate(cfg)`
- **Next Speaker Type**: `getSpeakerTypeLabel(nextSacramentDate(), cfg)`
- **Upcoming 6 Sundays table**: Date | Occurrence | Speaker Type — computed for 6 consecutive Sundays
- **Suggested Sacrament Conductor**: `getSuggestedConductor(sacramentConductors, cfg.lastSacramentConductorId)`
- **Suggested Bishopric Conductor**: `getSuggestedConductor(bishopricConductors, cfg.lastBishopricConductorId)`

### Editable Fields (all bound to `WardConfig`)
| Field | Widget | Default |
|---|---|---|
| Ward Name | `TextFormField` | "Pasay 3rd Ward" |
| Stake Name | `TextFormField` | "Pasay Philippine Stake" |
| Acknowledgement Template | `TextFormField` multiline | (default template with placeholders) |
| Sacrament Time | `TextFormField` | "09:00" |
| Bishopric Preferred Day | `DropdownButtonFormField` | "Thursday" / "Sunday" |
| Bishopric Thursday Time | `TextFormField` | "19:00" |
| Bishopric Sunday Time | `TextFormField` | "12:00" |
| Ward Council Occurrences | `TextFormField` | "1,3" (comma-separated) |
| Ward Council Time | `TextFormField` | "11:00" |
| Speaker Cycle Base Month | `TextFormField` | "2026-01" |

### Save Button
- **Save Rules**: validates and updates `ward_config` (id=1) in DB → shows SnackBar "Rules saved."
- The display section at the top refreshes automatically using the new values

---

## 14. Navigation

### Recommended: Bottom Navigation Bar + Drawer
- Use `NavigationBar` (Material 3) or `BottomNavigationBar` for the 7 destinations
- On narrow screens, use a `Drawer` if 7 items are too cramped

### Destinations
```
[Home] [Sacrament] [Bishopric] [Ward Council] [History] [Manage] [Rules]
```

### Back Navigation from Preview
- Preview screen always has a back arrow (← Edit) that returns to the form with data intact
- After export, program is already saved; user can still go back and edit

---

## 15. UI/UX Requirements

### Theme
- Primary color: deep blue (`#2C5282` or `Color(0xFF2C5282)`) — matches the Spring Boot app
- Font: system default or `Roboto`
- All form sections have card-style containers with subtle shadows

### Forms
- All form screens are single `ListView`/`SingleChildScrollView` — no tab switching within a form
- All `TextFormField` have `fontSize: 16` to prevent system font scaling issues
- Multiline fields use `minLines: 2, maxLines: 6` and expand as user types
- Dropdowns show a "Select…" hint when no value is pre-selected

### Dynamic Rows (Speakers & Agenda Items)
- **Add** button at the bottom of the row list adds a new empty row
- **Remove (×)** button on each row deletes that row
- Minimum of 0 rows allowed (remove all if needed)
- Rows animate in/out with a subtle fade or slide animation

### Locked Field (Presiding)
- Displayed as a non-editable `Container` styled like a `TextFormField` but with:
  - Light blue background (`Colors.blue.shade50`)
  - Blue border (`Colors.blue.shade300`)
  - A lock icon (🔒) trailing

### SnackBar Messages
- Success: green background, white text
- Error: red background, white text
- Duration: 3 seconds

### Loading States
- Show a `CircularProgressIndicator` centered on screen while DB queries run
- Show one on export while file is being generated

### Speaker Cycle Badge
- Displayed above the Speakers section on the Sacrament form
- Colored chip/badge: e.g. blue for Stake Assignment, green for Relief Society, etc.
- Text = the speaker type label

---

## 16. Recommended Packages

| Package | Purpose |
|---|---|
| `sqflite` | Local SQLite database |
| `path_provider` | Get local file system paths |
| `pdf` | Generate PDF files in Dart |
| `share_plus` | Share/download generated files |
| `intl` | Date formatting |
| `provider` or `riverpod` | State management |
| `flutter_form_builder` | Form management (optional) |
| `archive` | Create ZIP/OOXML for DOCX (optional) |
| `image` | Image manipulation for PNG export |
| `permission_handler` | Request storage permissions on Android |

---

## Critical Implementation Rules

1. **Bishop detection**: Always find the presiding officer by scanning the bishopric conductors list for the first name that starts with "Bishop" (case-insensitive). Never hardcode the Bishop's name.
2. **No duplicate prayers**: The three auto-assigned roles (opening prayer, handbook, closing prayer) always use 3 consecutive different indices — no two fields ever get the same person in one meeting.
3. **Index persistence**: After each form load that advances a rotation index, immediately write the new index back to `ward_config` in SQLite before the screen finishes loading.
4. **JSON storage**: `saved_programs.program_data` stores the full program as a JSON string. Dart model classes must have `toJson()` and `fromJson()` methods. Speaker `order` field must be preserved for correct reload order.
5. **Auto-save on export**: Every export (PDF/DOCX/PNG) must save the program to `saved_programs` before generating the file. Failure to save should not block the export.
6. **No hardcoded lists**: All dropdowns (conductors, auxiliaries, choristers, pianists) must be loaded from SQLite. Never hardcode names.
7. **Acknowledgement template**: The template is user-editable and stored in `ward_config`. Build the final text at form-load time using `buildAcknowledgement()`, substituting `{OTHER_CONDUCTORS}` and `{BISHOPRIC_OTHERS}`.
8. **Sacrament conductor round-robin update**: Unlike Bishopric/WC (which advance on load), the sacrament conductor index (`last_sacrament_conductor_id`) is updated only on export, not on form load.
9. **Date format**: `meetingDate` in `saved_programs` stores as `yyyy-MM-dd` string. `createdAt` stores as ISO 8601 string.
10. **Offline only**: No network calls. All data is local SQLite. The app must function with no internet connection.

---

*Source: Spring Boot ProgramGenerator, Pasay 3rd Ward — April 2026*  
*Flutter target: Android-only, offline, local storage*
