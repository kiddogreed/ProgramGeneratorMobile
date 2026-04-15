// utils/rotation_service.dart
// All scheduling logic mirrors the FLUTTER_APP_REFERENCE.md specification exactly.

import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/conductor.dart';
import '../models/ward_config.dart';

class RotationService {
  final DatabaseHelper _db;
  RotationService(this._db);

  // ── Date helpers ─────────────────────────────────────────────────────

  /// Next Sunday on or after today (today if today is Sunday).
  static DateTime nextSacramentDate() {
    final today = DateTime.now();
    final daysToSunday = today.weekday == DateTime.sunday
        ? 0
        : DateTime.sunday - today.weekday;
    return DateTime(today.year, today.month, today.day + daysToSunday);
  }

  /// Next preferred day strictly in the future — never today.
  static DateTime nextBishopricDate(WardConfig cfg) {
    final today = DateTime.now();
    final target = _dayNumber(cfg.bishopricPreferredDay);
    int daysUntil = (target - today.weekday + 7) % 7;
    if (daysUntil == 0) daysUntil = 7; // skip today
    return DateTime(today.year, today.month, today.day + daysUntil);
  }

  static int _dayNumber(String day) {
    switch (day) {
      case 'Monday':    return DateTime.monday;
      case 'Tuesday':   return DateTime.tuesday;
      case 'Wednesday': return DateTime.wednesday;
      case 'Thursday':  return DateTime.thursday;
      case 'Friday':    return DateTime.friday;
      case 'Saturday':  return DateTime.saturday;
      default:          return DateTime.sunday;
    }
  }

  /// Next Sunday matching ward_council_occurrences (e.g. "1,3").
  static DateTime nextWardCouncilDate(WardConfig cfg) {
    final occurrences = cfg.wardCouncilOccurrences
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 1)
        .toList();
    var candidate = nextSacramentDate();
    for (int i = 0; i < 8; i++) {
      if (occurrences.contains(getSundayOccurrence(candidate))) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  /// Which occurrence (1st, 2nd … 5th) of the month is this Sunday?
  static int getSundayOccurrence(DateTime date) => (date.day - 1) ~/ 7 + 1;

  /// 3-month cycle number (1, 2, or 3) for the given date.
  static int getSpeakerCycleNumber(DateTime date, String baseMonth) {
    final parts = baseMonth.split('-');
    final baseYear = int.parse(parts[0]);
    final baseMonthNum = int.parse(parts[1]);
    final elapsed =
        (date.year - baseYear) * 12 + (date.month - baseMonthNum);
    return ((elapsed % 3) + 3) % 3 + 1;
  }

  /// Maps a speaker type label to an auxiliary DB name for auto-fill.
  /// Returns null for Fast & Testimony (whole ward — no specific auxiliary).
  /// All other labels already match the auxiliary name exactly.
  static String? speakerLabelToAuxiliary(String label) {
    if (label == 'Fast & Testimony') return null;
    return label; // label matches auxiliary name exactly
  }

  /// Human-readable speaker type label for a given Sunday.
  /// Rules: 1st→Fast & Testimony, 3rd→Stake leaders, 5th→Bishopric,
  /// 2nd/4th→configurable auxiliary cycle slots.
  static String getSpeakerTypeLabel(DateTime sunday, WardConfig cfg) {
    final occurrence = getSundayOccurrence(sunday);
    switch (occurrence) {
      case 1:
        return 'Fast & Testimony';
      case 3:
        return 'Stake leaders';
      case 5:
        return 'Bishopric';
      case 2:
        final cycle2 =
            getSpeakerCycleNumber(sunday, cfg.speakerCycleBaseMonth);
        if (cycle2 == 1) return cfg.cycle2Slot1;
        if (cycle2 == 2) return cfg.cycle2Slot2;
        return cfg.cycle2Slot3;
      default: // 4th Sunday
        final cycle4 =
            getSpeakerCycleNumber(sunday, cfg.speakerCycleBaseMonth);
        if (cycle4 == 1) return cfg.cycle4Slot1;
        if (cycle4 == 2) return cfg.cycle4Slot2;
        return cfg.cycle4Slot3;
    }
  }

  /// Round-robin: next conductor after lastUsedId.
  static Conductor? getSuggestedConductor(
      List<Conductor> conductors, int? lastUsedId) {
    if (conductors.isEmpty) return null;
    if (lastUsedId == null) return conductors.first;
    final lastIndex =
        conductors.indexWhere((c) => c.id == lastUsedId);
    if (lastIndex < 0) return conductors.first;
    final nextIndex = (lastIndex + 1) % conductors.length;
    return conductors[nextIndex];
  }

  /// Returns 3 consecutive different indices after baseIdx.
  static List<int> nextThreeIndices(int listLength, int? baseIdx) {
    if (listLength == 0) return [];
    final base = baseIdx ?? -1;
    return [
      (base + 1) % listLength,
      (base + 2) % listLength,
      (base + 3) % listLength,
    ];
  }

  /// Acknowledgement template substitution.
  static String buildAcknowledgement(
    String template,
    String conducting,
    List<Conductor> sacramentConductors,
    List<Conductor> bishopricConductors,
  ) {
    final otherConductors = sacramentConductors
        .where((c) =>
            c.name.toLowerCase() != conducting.toLowerCase())
        .map((c) => c.name)
        .join(', ');

    final bishopIdx = bishopricConductors.indexWhere(
        (c) => c.name.toLowerCase().startsWith('bishop'));
    final bishopName =
        bishopIdx >= 0 ? bishopricConductors[bishopIdx].name : '';

    final bishopricOthers = bishopricConductors
        .where((c) =>
            c.name != bishopName &&
            c.name.toLowerCase() != conducting.toLowerCase())
        .map((c) => c.name)
        .join(', ');

    return template
        .replaceAll('{OTHER_CONDUCTORS}', otherConductors)
        .replaceAll('{BISHOPRIC_OTHERS}', bishopricOthers);
  }

  // ── Sacrament auto-populate ──────────────────────────────────────────
  // Note: sacrament conductor index is advanced on EXPORT, not on form load.

  Future<Map<String, dynamic>> autoPopulateSacrament() async {
    final cfg = await _db.getWardConfig();
    final sacramentConductors =
        await _db.getConductors(programType: 'sacrament');
    final bishopricConductors =
        await _db.getConductors(programType: 'bishopric');

    final date = nextSacramentDate();

    // Suggested conductor (round-robin, advance pointer immediately)
    final suggested = getSuggestedConductor(
        sacramentConductors, cfg.lastSacramentConductorId);
    final conducting = suggested?.name ?? '';
    if (suggested?.id != null) {
      await _db.saveWardConfig(
          cfg.copyWith(lastSacramentConductorId: suggested!.id));
    }

    // Presiding: use bishopName from config; fallback to first "Bishop*" conductor
    final presiding = cfg.bishopName.isNotEmpty
        ? cfg.bishopName
        : () {
            final bishopEntry = bishopricConductors.firstWhere(
              (c) => c.name.toLowerCase().startsWith('bishop'),
              orElse: () => Conductor(name: '', displayOrder: 0, programType: 'bishopric'),
            );
            return bishopEntry.name;
          }();

    // Acknowledgement
    final ack = buildAcknowledgement(
      cfg.acknowledgementTemplate,
      conducting,
      sacramentConductors,
      bishopricConductors,
    );

    // Speaker type label for badge + auxiliary auto-fill
    final speakerTypeLabel = getSpeakerTypeLabel(date, cfg);
    final speakerAuxiliary = speakerLabelToAuxiliary(speakerTypeLabel);

    return {
      'date': date.toIso8601String().split('T').first,
      'presiding': presiding,
      'conducting': conducting,
      'acknowledgement': ack,
      'wardName': cfg.wardName,
      'stakeName': cfg.stakeName,
      'speakerTypeLabel': speakerTypeLabel,
      'speakerAuxiliary': speakerAuxiliary,
    };
  }

  // ── Bishopric auto-populate ──────────────────────────────────────────

  Future<Map<String, dynamic>> autoPopulateBishopric() async {
    final cfg = await _db.getWardConfig();
    final conductors = await _db.getConductors(programType: 'bishopric');

    final date = nextBishopricDate(cfg);

    // Presiding: use bishopName from config; fallback to first "Bishop*" conductor
    final presiding = cfg.bishopName.isNotEmpty
        ? cfg.bishopName
        : () {
            final bishopEntry = conductors.firstWhere(
              (c) => c.name.toLowerCase().startsWith('bishop'),
              orElse: () => Conductor(name: '', displayOrder: 0, programType: 'bishopric'),
            );
            return bishopEntry.name;
          }();

    // Conducting (round-robin, advance immediately per spec)
    final suggested =
        getSuggestedConductor(conductors, cfg.lastBishopricConductorId);
    final conducting = suggested?.name ?? '';
    if (suggested?.id != null) {
      await _db.saveWardConfig(
          cfg.copyWith(lastBishopricConductorId: suggested!.id));
    }

    // Three consecutive indices for prayer/handbook
    final idxs = nextThreeIndices(conductors.length, cfg.bpHandbookIdx);
    String openingPrayer = '';
    String handbookSpiritual = '';
    String closingPrayer = '';
    if (idxs.length == 3) {
      openingPrayer = conductors[idxs[0]].name;
      handbookSpiritual = conductors[idxs[1]].name;
      closingPrayer = conductors[idxs[2]].name;
      // Save last index (idxs[2]) back to DB
      final updatedCfg = await _db.getWardConfig();
      await _db.saveWardConfig(
          updatedCfg.copyWith(bpHandbookIdx: idxs[2]));
    }

    return {
      'meetingDate': date.toIso8601String().split('T').first,
      'presiding': presiding,
      'conducting': conducting,
      'wardName': cfg.wardName,
      'openingPrayer': openingPrayer,
      'handbookSpiritual': handbookSpiritual,
      'closingPrayer': closingPrayer,
    };
  }

  // ── Ward Council auto-populate ───────────────────────────────────────

  Future<Map<String, dynamic>> autoPopulateWardCouncil() async {
    final cfg = await _db.getWardConfig();
    final conductors = await _db.getConductors(programType: 'bishopric');
    final auxiliaries = await _db.getAuxiliaries();

    final date = nextWardCouncilDate(cfg);

    // Presiding: first conductor named "Bishop*"
    final bishopEntry = conductors.firstWhere(
      (c) => c.name.toLowerCase().startsWith('bishop'),
      orElse: () => Conductor(name: '', displayOrder: 0, programType: 'bishopric'),
    );
    final presiding = bishopEntry.name;

    // Conducting (round-robin, advance immediately)
    final suggested =
        getSuggestedConductor(conductors, cfg.lastBishopricConductorId);
    final conducting = suggested?.name ?? '';
    if (suggested?.id != null) {
      await _db.saveWardConfig(
          cfg.copyWith(lastBishopricConductorId: suggested!.id));
    }

    // Three indices from auxiliaries for prayer/handbook
    final idxs = nextThreeIndices(auxiliaries.length, cfg.wcHandbookIdx);
    String openingPrayer = '';
    String handbookReading = '';
    String closingPrayer = '';
    if (idxs.length == 3) {
      openingPrayer = auxiliaries[idxs[0]].name;
      handbookReading = auxiliaries[idxs[1]].name;
      closingPrayer = auxiliaries[idxs[2]].name;
      final updatedCfg = await _db.getWardConfig();
      await _db.saveWardConfig(
          updatedCfg.copyWith(wcHandbookIdx: idxs[2]));
    }

    return {
      'meetingDate': date.toIso8601String().split('T').first,
      'wardName': cfg.wardName,
      'presiding': presiding,
      'conducting': conducting,
      'openingPrayer': openingPrayer,
      'handbookReading': handbookReading,
      'closingPrayer': closingPrayer,
    };
  }

  static String formatDate(DateTime d) =>
      DateFormat('MMMM d, yyyy').format(d);
}
