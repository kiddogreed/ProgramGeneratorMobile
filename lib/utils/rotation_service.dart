// utils/rotation_service.dart
// Handles all auto-population and round-robin rotation logic,
// mirroring the Spring Boot automation rules.

import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/ward_config.dart';

class RotationService {
  final DatabaseHelper _db;
  RotationService(this._db);

  // ── Date helpers ─────────────────────────────────────────────────────

  /// Next occurrence of [weekday] (DateTime.monday=1 … DateTime.sunday=7).
  static DateTime nextWeekday(int weekday) {
    final now = DateTime.now();
    int daysAhead = weekday - now.weekday;
    if (daysAhead <= 0) daysAhead += 7;
    return DateTime(now.year, now.month, now.day + daysAhead);
  }

  static DateTime nextSunday() => nextWeekday(DateTime.sunday);
  static DateTime nextThursday() => nextWeekday(DateTime.thursday);

  /// Returns the next 1st-or-3rd Sunday from today.
  static DateTime next1st3rdSunday() {
    DateTime candidate = nextSunday();
    for (int i = 0; i < 5; i++) {
      final week = (candidate.day - 1) ~/ 7 + 1;
      if (week == 1 || week == 3) return candidate;
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  static DateTime next2nd4thSunday() {
    DateTime candidate = nextSunday();
    for (int i = 0; i < 5; i++) {
      final week = (candidate.day - 1) ~/ 7 + 1;
      if (week == 2 || week == 4) return candidate;
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  // ── Sacrament auto-populate ──────────────────────────────────────────

  Future<Map<String, dynamic>> autoPopulateSacrament() async {
    final cfg = await _db.getWardConfig();
    final conductors = await _db.getConductors(programType: 'sacrament');
    final speakers = await _db.getSpeakerEntries();

    // Date
    DateTime date;
    switch (cfg.sacramentSchedule) {
      case '1ST_3RD':
        date = next1st3rdSunday();
        break;
      case '2ND_4TH':
        date = next2nd4thSunday();
        break;
      default:
        date = nextSunday();
    }

    // Conducting (round-robin)
    String conducting = '';
    if (conductors.isNotEmpty) {
      final idx = cfg.speakerCycleIndex % conductors.length;
      conducting = conductors[idx].name;
    }

    // Presiding (Bishop by default)
    String presiding = cfg.bishopricPresiding;

    // Acknowledgement template
    String ack = cfg.acknowledgementTemplate;

    // Speaker suggestions (next 2 in cycle)
    List<String> suggestedSpeakers = [];
    if (speakers.isNotEmpty) {
      final idx = cfg.speakerCycleIndex % speakers.length;
      suggestedSpeakers = [
        speakers[idx].name,
        if (speakers.length > 1) speakers[(idx + 1) % speakers.length].name,
      ];
    }

    return {
      'date': date,
      'presiding': presiding,
      'conducting': conducting,
      'acknowledgement': ack,
      'wardName': cfg.wardName,
      'stakeName': cfg.stakeName,
      'suggestedSpeakers': suggestedSpeakers,
    };
  }

  // ── Bishopric auto-populate ──────────────────────────────────────────

  Future<Map<String, dynamic>> autoPopulateBishopric() async {
    final cfg = await _db.getWardConfig();
    final conductors = await _db.getConductors(programType: 'bishopric');

    // Date
    DateTime date;
    switch (cfg.bishopricSchedule) {
      case 'EVERY_MONDAY':
        date = nextWeekday(DateTime.monday);
        break;
      default:
        date = nextThursday();
    }

    // Presiding is always the Bishop
    String presiding = cfg.bishopricPresiding;

    // Opening prayer (round-robin, no duplicate with closing)
    String openingPrayer = '';
    String closingPrayer = '';
    if (conductors.length >= 2) {
      final openIdx = cfg.bishopricPrayerIndex % conductors.length;
      final closeIdx = (openIdx + 1) % conductors.length;
      openingPrayer = conductors[openIdx].name;
      closingPrayer = conductors[closeIdx].name;
    } else if (conductors.length == 1) {
      openingPrayer = conductors[0].name;
    }

    return {
      'meetingDate': date,
      'presiding': presiding,
      'wardName': cfg.wardName,
      'openingPrayer': openingPrayer,
      'closingPrayer': closingPrayer,
    };
  }

  // ── Ward Council auto-populate ───────────────────────────────────────

  Future<Map<String, dynamic>> autoPopulateWardCouncil() async {
    final cfg = await _db.getWardConfig();
    final auxiliaries = await _db.getAuxiliaries();
    final handbooks = await _db.getHandbookReadings();

    DateTime date;
    switch (cfg.wardCouncilSchedule) {
      case 'EVERY_SUNDAY_AFTER':
        date = nextSunday();
        break;
      default:
        date = nextSunday();
    }

    // Opening prayer (round-robin from auxiliaries)
    String openingPrayer = '';
    String closingPrayer = '';
    if (auxiliaries.length >= 2) {
      final openIdx = cfg.wcOpeningPrayerIndex % auxiliaries.length;
      // Closing prayer index must not collide with opening
      int closeIdx = cfg.wcClosingPrayerIndex % auxiliaries.length;
      if (closeIdx == openIdx) closeIdx = (openIdx + 1) % auxiliaries.length;
      openingPrayer = auxiliaries[openIdx].name;
      closingPrayer = auxiliaries[closeIdx].name;
    } else if (auxiliaries.length == 1) {
      openingPrayer = auxiliaries[0].name;
    }

    // Handbook reading (round-robin)
    String handbookReading = '';
    if (handbooks.isNotEmpty) {
      final idx = cfg.wcHandbookIndex % handbooks.length;
      handbookReading = handbooks[idx].display;
    }

    return {
      'meetingDate': date,
      'wardName': cfg.wardName,
      'presiding': cfg.bishopricPresiding,
      'openingPrayer': openingPrayer,
      'closingPrayer': closingPrayer,
      'handbookReading': handbookReading,
    };
  }

  // ── Advance rotation indices ─────────────────────────────────────────

  Future<void> advanceSpeakerCycle() async {
    final cfg = await _db.getWardConfig();
    final speakers = await _db.getSpeakerEntries();
    if (speakers.isEmpty) return;
    await _db.saveWardConfig(cfg.copyWith(
      speakerCycleIndex: (cfg.speakerCycleIndex + 1) % speakers.length,
    ));
  }

  Future<void> advanceBishopricPrayer() async {
    final cfg = await _db.getWardConfig();
    final conductors = await _db.getConductors(programType: 'bishopric');
    if (conductors.isEmpty) return;
    await _db.saveWardConfig(cfg.copyWith(
      bishopricPrayerIndex:
          (cfg.bishopricPrayerIndex + 1) % conductors.length,
    ));
  }

  Future<void> advanceWardCouncilRotation() async {
    final cfg = await _db.getWardConfig();
    final auxiliaries = await _db.getAuxiliaries();
    final handbooks = await _db.getHandbookReadings();
    if (auxiliaries.isEmpty) return;
    await _db.saveWardConfig(cfg.copyWith(
      wcOpeningPrayerIndex:
          (cfg.wcOpeningPrayerIndex + 1) % auxiliaries.length,
      wcClosingPrayerIndex:
          (cfg.wcClosingPrayerIndex + 2) % auxiliaries.length,
      wcHandbookIndex: handbooks.isEmpty
          ? 0
          : (cfg.wcHandbookIndex + 1) % handbooks.length,
    ));
  }

  static String formatDate(DateTime d) =>
      DateFormat('MMMM d, yyyy').format(d);
}
