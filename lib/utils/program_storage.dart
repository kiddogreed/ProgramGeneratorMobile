// utils/program_storage.dart
// Helpers to serialise/deserialise programs and save/load from SQLite.

import 'dart:convert';

import '../database/database_helper.dart';
import '../models/sacrament_program.dart';
import '../models/bishopric_program.dart';
import '../models/ward_council_program.dart';
import '../models/saved_program.dart';
import 'package:intl/intl.dart';

class ProgramStorage {
  final DatabaseHelper _db = DatabaseHelper();

  // ── Save helpers ───────────────────────────────────────────────────────

  Future<void> saveSacrament(SacramentProgram p) async {
    final data = jsonEncode(p.toJson());
    final desc =
        'Sacrament – ${p.wardName} – ${DateFormat('yyyy-MM-dd').format(p.date)}';
    final sp = SavedProgram(
      meetingType: 'SACRAMENT',
      description: desc,
      meetingDate: p.date,
      programData: data,
    );
    await _db.insertSavedProgram(sp);
  }

  Future<void> saveBishopric(BishopricProgram p) async {
    final data = jsonEncode(p.toJson());
    final desc =
        'Bishopric – ${p.wardName} – ${DateFormat('yyyy-MM-dd').format(p.meetingDate)}';
    final sp = SavedProgram(
      meetingType: 'BISHOPRIC',
      description: desc,
      meetingDate: p.meetingDate,
      programData: data,
    );
    await _db.insertSavedProgram(sp);
  }

  Future<void> saveWardCouncil(WardCouncilProgram p) async {
    final data = jsonEncode(p.toJson());
    final desc =
        'Ward Council – ${p.wardName} – ${DateFormat('yyyy-MM-dd').format(p.meetingDate)}';
    final sp = SavedProgram(
      meetingType: 'WARD_COUNCIL',
      description: desc,
      meetingDate: p.meetingDate,
      programData: data,
    );
    await _db.insertSavedProgram(sp);
  }

  // ── Load helpers ───────────────────────────────────────────────────────

  Future<List<SavedProgram>> loadAll() => _db.getSavedPrograms();

  Future<void> delete(int id) => _db.deleteSavedProgram(id);

  SacramentProgram decodeSacrament(String json) =>
      SacramentProgram.fromJson(jsonDecode(json) as Map<String, dynamic>);

  BishopricProgram decodeBishopric(String json) =>
      BishopricProgram.fromJson(jsonDecode(json) as Map<String, dynamic>);

  WardCouncilProgram decodeWardCouncil(String json) =>
      WardCouncilProgram.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
