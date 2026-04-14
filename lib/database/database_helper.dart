// database/database_helper.dart
// SQLite helper using sqflite.  All local data is stored in a single DB.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/musician.dart';
import '../models/conductor.dart';
import '../models/auxiliary.dart';
import '../models/saved_program.dart';
import '../models/ward_config.dart';
import '../models/hymn.dart';
import '../models/handbook_reading.dart';
import '../models/speaker_entry.dart';

class DatabaseHelper {
  static const _dbName = 'church_programs.db';
  static const _dbVersion = 4; // v4: bishop_name + cycle slot columns

  // Singleton pattern
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._();
  factory DatabaseHelper() => _instance ??= DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  // ── Initialisation ─────────────────────────────────────────────────────

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Musicians table
    await db.execute('''
      CREATE TABLE musicians (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT NOT NULL,
        musician_type TEXT NOT NULL DEFAULT 'chorister',
        display_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Conductors table
    await db.execute('''
      CREATE TABLE conductors (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT NOT NULL,
        display_order INTEGER NOT NULL DEFAULT 0,
        program_type  TEXT NOT NULL DEFAULT 'sacrament'
      )
    ''');

    // Auxiliaries table
    await db.execute('''
      CREATE TABLE auxiliaries (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Saved programs table
    await db.execute('''
      CREATE TABLE saved_programs (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        meeting_type TEXT NOT NULL,
        description  TEXT NOT NULL,
        meeting_date TEXT NOT NULL,
        program_data TEXT NOT NULL,
        created_at   TEXT NOT NULL
      )
    ''');

    // Seed auxiliaries
    final batch = db.batch();
    for (final name in Auxiliary.defaults) {
      batch.insert('auxiliaries', {'name': name});
    }
    await batch.commit(noResult: true);

    // Create and seed new tables
    await _createNewTables(db);
    await _seedNewTables(db);
  }

  Future<void> _createNewTables(Database db) async {
    // Ward config (singleton row) — v3 schema
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ward_config (
        id                         INTEGER PRIMARY KEY DEFAULT 1,
        stake_name                 TEXT NOT NULL DEFAULT 'Pasay Philippine Stake',
        ward_name                  TEXT NOT NULL DEFAULT 'Pasay 3rd Ward',
        acknowledgement_template   TEXT NOT NULL DEFAULT '',
        sacrament_time             TEXT NOT NULL DEFAULT '09:00',
        bishopric_preferred_day    TEXT NOT NULL DEFAULT 'Thursday',
        bishopric_thursday_time    TEXT NOT NULL DEFAULT '19:00',
        bishopric_sunday_time      TEXT NOT NULL DEFAULT '12:00',
        ward_council_occurrences   TEXT NOT NULL DEFAULT '1,3',
        ward_council_time          TEXT NOT NULL DEFAULT '11:00',
        speaker_cycle_base_month   TEXT NOT NULL DEFAULT '2026-01',
        cycle2_slot1               TEXT NOT NULL DEFAULT 'Relief Society',
        cycle2_slot2               TEXT NOT NULL DEFAULT 'Elders Quorum',
        cycle2_slot3               TEXT NOT NULL DEFAULT 'Ward Mission & Family History',
        cycle4_slot1               TEXT NOT NULL DEFAULT 'Sunday School',
        cycle4_slot2               TEXT NOT NULL DEFAULT 'Primary',
        cycle4_slot3               TEXT NOT NULL DEFAULT 'Youth',
        bishop_name                TEXT NOT NULL DEFAULT 'Bishop Sherwin Tan',
        last_sacrament_conductor_id INTEGER,
        last_bishopric_conductor_id INTEGER,
        wc_opening_prayer_idx      INTEGER,
        wc_closing_prayer_idx      INTEGER,
        wc_handbook_idx            INTEGER,
        bp_opening_prayer_idx      INTEGER,
        bp_closing_prayer_idx      INTEGER,
        bp_handbook_idx            INTEGER
      )
    ''');

    // Hymns table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hymns (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        number        TEXT NOT NULL DEFAULT '',
        title         TEXT NOT NULL,
        display_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Handbook readings table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS handbook_readings (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        title         TEXT NOT NULL,
        reference     TEXT NOT NULL DEFAULT '',
        display_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Speaker rotation list
    await db.execute('''
      CREATE TABLE IF NOT EXISTS speaker_entries (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT NOT NULL,
        organization  TEXT NOT NULL DEFAULT '',
        display_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _seedNewTables(Database db) async {
    // Seed default ward config
    final existing = await db.query('ward_config', limit: 1);
    if (existing.isEmpty) {
      await db.insert('ward_config', WardConfig().toMap()..['id'] = 1);
    }

    // Seed hymns
    final hymnCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM hymns'));
    if (hymnCount == 0) {
      final batch = db.batch();
      for (final h in Hymn.seedData) {
        batch.insert('hymns', h);
      }
      await batch.commit(noResult: true);
    }

    // Seed handbook readings
    final hbCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM handbook_readings'));
    if (hbCount == 0) {
      final batch = db.batch();
      for (final h in HandbookReading.seedData) {
        batch.insert('handbook_readings', h);
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createNewTables(db);
      await _seedNewTables(db);
    }
    if (oldVersion < 3) {
      // Drop old ward_config and recreate with new schema
      await db.execute('DROP TABLE IF EXISTS ward_config');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ward_config (
          id                         INTEGER PRIMARY KEY DEFAULT 1,
          stake_name                 TEXT NOT NULL DEFAULT \'Pasay Philippine Stake\',
          ward_name                  TEXT NOT NULL DEFAULT \'Pasay 3rd Ward\',
          acknowledgement_template   TEXT NOT NULL DEFAULT \'\',
          sacrament_time             TEXT NOT NULL DEFAULT \'09:00\',
          bishopric_preferred_day    TEXT NOT NULL DEFAULT \'Thursday\',
          bishopric_thursday_time    TEXT NOT NULL DEFAULT \'19:00\',
          bishopric_sunday_time      TEXT NOT NULL DEFAULT \'12:00\',
          ward_council_occurrences   TEXT NOT NULL DEFAULT \'1,3\',
          ward_council_time          TEXT NOT NULL DEFAULT \'11:00\',
          speaker_cycle_base_month   TEXT NOT NULL DEFAULT \'2026-01\',
          cycle2_slot1               TEXT NOT NULL DEFAULT \'Relief Society\',
          cycle2_slot2               TEXT NOT NULL DEFAULT \'Elders Quorum\',
          cycle2_slot3               TEXT NOT NULL DEFAULT \'Ward Mission & Family History\',
          cycle4_slot1               TEXT NOT NULL DEFAULT \'Sunday School\',
          cycle4_slot2               TEXT NOT NULL DEFAULT \'Primary\',
          cycle4_slot3               TEXT NOT NULL DEFAULT \'Youth\',
          bishop_name                TEXT NOT NULL DEFAULT \'Bishop Sherwin Tan\',
          last_sacrament_conductor_id INTEGER,
          last_bishopric_conductor_id INTEGER,
          wc_opening_prayer_idx      INTEGER,
          wc_closing_prayer_idx      INTEGER,
          wc_handbook_idx            INTEGER,
          bp_opening_prayer_idx      INTEGER,
          bp_closing_prayer_idx      INTEGER,
          bp_handbook_idx            INTEGER
        )
      ''');
      // Re-seed with new defaults
      final existing = await db.query('ward_config', limit: 1);
      if (existing.isEmpty) {
        await db.insert('ward_config', WardConfig().toMap()..['id'] = 1);
      }
    }
    if (oldVersion < 4) {
      // Add new columns to existing ward_config
      await db.execute("ALTER TABLE ward_config ADD COLUMN cycle2_slot1 TEXT NOT NULL DEFAULT 'Relief Society'");
      await db.execute("ALTER TABLE ward_config ADD COLUMN cycle2_slot2 TEXT NOT NULL DEFAULT 'Elders Quorum'");
      await db.execute("ALTER TABLE ward_config ADD COLUMN cycle2_slot3 TEXT NOT NULL DEFAULT 'Ward Mission & Family History'");
      await db.execute("ALTER TABLE ward_config ADD COLUMN cycle4_slot1 TEXT NOT NULL DEFAULT 'Sunday School'");
      await db.execute("ALTER TABLE ward_config ADD COLUMN cycle4_slot2 TEXT NOT NULL DEFAULT 'Primary'");
      await db.execute("ALTER TABLE ward_config ADD COLUMN cycle4_slot3 TEXT NOT NULL DEFAULT 'Youth'");
      await db.execute("ALTER TABLE ward_config ADD COLUMN bishop_name TEXT NOT NULL DEFAULT 'Bishop Sherwin Tan'");
    }
  }

  // ── Musicians ──────────────────────────────────────────────────────────

  Future<List<Musician>> getMusicians({String? type}) async {
    final db = await database;
    final where = type != null ? 'musician_type = ?' : null;
    final whereArgs = type != null ? [type] : null;
    final rows = await db.query(
      'musicians',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'display_order ASC, name ASC',
    );
    return rows.map(Musician.fromMap).toList();
  }

  Future<int> insertMusician(Musician m) async {
    final db = await database;
    return db.insert('musicians', m.toMap());
  }

  Future<void> updateMusician(Musician m) async {
    final db = await database;
    await db.update(
      'musicians',
      m.toMap(),
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  Future<void> deleteMusician(int id) async {
    final db = await database;
    await db.delete('musicians', where: 'id = ?', whereArgs: [id]);
  }

  // ── Conductors ─────────────────────────────────────────────────────────

  Future<List<Conductor>> getConductors({String? programType}) async {
    final db = await database;
    final where = programType != null ? 'program_type = ?' : null;
    final whereArgs = programType != null ? [programType] : null;
    final rows = await db.query(
      'conductors',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'display_order ASC, name ASC',
    );
    return rows.map(Conductor.fromMap).toList();
  }

  Future<int> insertConductor(Conductor c) async {
    final db = await database;
    return db.insert('conductors', c.toMap());
  }

  Future<void> updateConductor(Conductor c) async {
    final db = await database;
    await db.update(
      'conductors',
      c.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<void> deleteConductor(int id) async {
    final db = await database;
    await db.delete('conductors', where: 'id = ?', whereArgs: [id]);
  }

  // ── Auxiliaries ────────────────────────────────────────────────────────

  Future<List<Auxiliary>> getAuxiliaries() async {
    final db = await database;
    final rows = await db.query('auxiliaries', orderBy: 'name ASC');
    return rows.map(Auxiliary.fromMap).toList();
  }

  Future<int> insertAuxiliary(Auxiliary a) async {
    final db = await database;
    return db.insert('auxiliaries', a.toMap());
  }

  Future<void> updateAuxiliary(Auxiliary a) async {
    final db = await database;
    await db.update('auxiliaries', a.toMap(),
        where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> deleteAuxiliary(int id) async {
    final db = await database;
    await db.delete('auxiliaries', where: 'id = ?', whereArgs: [id]);
  }

  // ── Saved Programs ─────────────────────────────────────────────────────

  Future<List<SavedProgram>> getSavedPrograms({String? meetingType}) async {
    final db = await database;
    final where = meetingType != null ? 'meeting_type = ?' : null;
    final whereArgs = meetingType != null ? [meetingType] : null;
    final rows = await db.query(
      'saved_programs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return rows.map(SavedProgram.fromMap).toList();
  }

  Future<int> insertSavedProgram(SavedProgram sp) async {
    final db = await database;
    return db.insert('saved_programs', sp.toMap());
  }

  Future<void> deleteSavedProgram(int id) async {
    final db = await database;
    await db.delete('saved_programs', where: 'id = ?', whereArgs: [id]);
  }

  // ── Ward Config ────────────────────────────────────────────────────────

  Future<WardConfig> getWardConfig() async {
    final db = await database;
    final rows = await db.query('ward_config', limit: 1);
    if (rows.isEmpty) {
      final cfg = WardConfig();
      await db.insert('ward_config', cfg.toMap()..['id'] = 1);
      return cfg;
    }
    return WardConfig.fromMap(rows.first);
  }

  Future<void> saveWardConfig(WardConfig cfg) async {
    final db = await database;
    final existing = await db.query('ward_config', limit: 1);
    if (existing.isEmpty) {
      await db.insert('ward_config', cfg.toMap()..['id'] = 1);
    } else {
      await db.update('ward_config', cfg.toMap(),
          where: 'id = 1');
    }
  }

  // ── Hymns ──────────────────────────────────────────────────────────────

  Future<List<Hymn>> getHymns() async {
    final db = await database;
    final rows =
        await db.query('hymns', orderBy: 'display_order ASC, title ASC');
    return rows.map(Hymn.fromMap).toList();
  }

  Future<int> insertHymn(Hymn h) async {
    final db = await database;
    return db.insert('hymns', h.toMap());
  }

  Future<void> updateHymn(Hymn h) async {
    final db = await database;
    await db.update('hymns', h.toMap(), where: 'id = ?', whereArgs: [h.id]);
  }

  Future<void> deleteHymn(int id) async {
    final db = await database;
    await db.delete('hymns', where: 'id = ?', whereArgs: [id]);
  }

  // ── Handbook Readings ─────────────────────────────────────────────────

  Future<List<HandbookReading>> getHandbookReadings() async {
    final db = await database;
    final rows = await db.query('handbook_readings',
        orderBy: 'display_order ASC, title ASC');
    return rows.map(HandbookReading.fromMap).toList();
  }

  Future<int> insertHandbookReading(HandbookReading h) async {
    final db = await database;
    return db.insert('handbook_readings', h.toMap());
  }

  Future<void> updateHandbookReading(HandbookReading h) async {
    final db = await database;
    await db.update('handbook_readings', h.toMap(),
        where: 'id = ?', whereArgs: [h.id]);
  }

  Future<void> deleteHandbookReading(int id) async {
    final db = await database;
    await db.delete('handbook_readings', where: 'id = ?', whereArgs: [id]);
  }

  // ── Speaker Entries ───────────────────────────────────────────────────

  Future<List<SpeakerEntry>> getSpeakerEntries() async {
    final db = await database;
    final rows = await db.query('speaker_entries',
        orderBy: 'display_order ASC, name ASC');
    return rows.map(SpeakerEntry.fromMap).toList();
  }

  Future<int> insertSpeakerEntry(SpeakerEntry s) async {
    final db = await database;
    return db.insert('speaker_entries', s.toMap());
  }

  Future<void> updateSpeakerEntry(SpeakerEntry s) async {
    final db = await database;
    await db.update('speaker_entries', s.toMap(),
        where: 'id = ?', whereArgs: [s.id]);
  }

  Future<void> deleteSpeakerEntry(int id) async {
    final db = await database;
    await db.delete('speaker_entries', where: 'id = ?', whereArgs: [id]);
  }
}
