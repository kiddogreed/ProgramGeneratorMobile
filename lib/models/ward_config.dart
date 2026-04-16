// models/ward_config.dart
// Singleton row that stores all automation rules, rotation indices, and
// ward-level settings — mirrors the FLUTTER_APP_REFERENCE.md specification.

class WardConfig {
  // Organisation
  String stakeName;
  String wardName;
  String acknowledgementTemplate;

  // Sacrament
  String sacramentTime; // e.g. "09:00"

  // Bishopric
  String bishopricPreferredDay;  // 'Thursday' or 'Sunday'
  String bishopricThursdayTime;  // e.g. "19:00"
  String bishopricSundayTime;    // e.g. "12:00"

  // Ward Council
  String wardCouncilOccurrences; // comma-separated, e.g. "1,3"
  String wardCouncilTime;

  // Speaker Cycle
  String speakerCycleBaseMonth; // yyyy-MM
  // 2nd Sunday cycle auxiliaries (cycle 1, 2, 3)
  String cycle2Slot1; // default: Relief Society
  String cycle2Slot2; // default: Elders Quorum
  String cycle2Slot3; // default: Ward Mission & Family History
  // 4th Sunday cycle auxiliaries (cycle 1, 2, 3)
  String cycle4Slot1; // default: Sunday School
  String cycle4Slot2; // default: Primary
  String cycle4Slot3; // default: Youth

  // Bishop name (for presiding auto-fill)
  String bishopName;

  // Conductor round-robin tracking
  int? lastSacramentConductorId;
  int? lastBishopricConductorId;

  // Prayer/handbook rotation indices
  int? wcOpeningPrayerIdx;
  int? wcClosingPrayerIdx;
  int? wcHandbookIdx;
  int? bpOpeningPrayerIdx;
  int? bpClosingPrayerIdx;
  int? bpHandbookIdx;

  WardConfig({
    this.stakeName = 'Pasay Philippine Stake',
    this.wardName = 'Pasay 3rd Ward',
    this.acknowledgementTemplate =
        'Acknowledge {OTHER_CONDUCTORS}, Bro. Adrian Matro (wrd Clrk), '
        'Johanne Perlas (Asst. Clrk. rec). Bro. Norman Oliva (Asst. Clrk. fin), '
        'John Russelle Domingo (wrd exc. Secr.), Genesis Ferareza (wrd exc. Asst. Secr.). '
        '{BISHOPRIC_OTHERS} To all Visitors and Stake Leaders (Welcome).',
    this.sacramentTime = '09:00',
    this.bishopricPreferredDay = 'Thursday',
    this.bishopricThursdayTime = '19:00',
    this.bishopricSundayTime = '12:00',
    this.wardCouncilOccurrences = '1,3',
    this.wardCouncilTime = '11:00',
    this.speakerCycleBaseMonth = '2026-01',
    this.cycle2Slot1 = 'Relief Society',
    this.cycle2Slot2 = 'Elders Quorum',
    this.cycle2Slot3 = 'Ward Mission & Family History',
    this.cycle4Slot1 = 'Sunday School',
    this.cycle4Slot2 = 'Primary',
    this.cycle4Slot3 = 'Youth',
    this.bishopName = 'Bishop Sherwin Tan',
    this.lastSacramentConductorId,
    this.lastBishopricConductorId,
    this.wcOpeningPrayerIdx,
    this.wcClosingPrayerIdx,
    this.wcHandbookIdx,
    this.bpOpeningPrayerIdx,
    this.bpClosingPrayerIdx,
    this.bpHandbookIdx,
  });

  WardConfig copyWith({
    String? stakeName,
    String? wardName,
    String? acknowledgementTemplate,
    String? sacramentTime,
    String? bishopricPreferredDay,
    String? bishopricThursdayTime,
    String? bishopricSundayTime,
    String? wardCouncilOccurrences,
    String? wardCouncilTime,
    String? speakerCycleBaseMonth,
    String? cycle2Slot1,
    String? cycle2Slot2,
    String? cycle2Slot3,
    String? cycle4Slot1,
    String? cycle4Slot2,
    String? cycle4Slot3,
    String? bishopName,
    int? lastSacramentConductorId,
    int? lastBishopricConductorId,
    int? wcOpeningPrayerIdx,
    int? wcClosingPrayerIdx,
    int? wcHandbookIdx,
    int? bpOpeningPrayerIdx,
    int? bpClosingPrayerIdx,
    int? bpHandbookIdx,
    bool clearLastSacramentConductorId = false,
    bool clearLastBishopricConductorId = false,
  }) {
    return WardConfig(
      stakeName: stakeName ?? this.stakeName,
      wardName: wardName ?? this.wardName,
      acknowledgementTemplate:
          acknowledgementTemplate ?? this.acknowledgementTemplate,
      sacramentTime: sacramentTime ?? this.sacramentTime,
      bishopricPreferredDay:
          bishopricPreferredDay ?? this.bishopricPreferredDay,
      bishopricThursdayTime:
          bishopricThursdayTime ?? this.bishopricThursdayTime,
      bishopricSundayTime: bishopricSundayTime ?? this.bishopricSundayTime,
      wardCouncilOccurrences:
          wardCouncilOccurrences ?? this.wardCouncilOccurrences,
      wardCouncilTime: wardCouncilTime ?? this.wardCouncilTime,
      speakerCycleBaseMonth:
          speakerCycleBaseMonth ?? this.speakerCycleBaseMonth,
      cycle2Slot1: cycle2Slot1 ?? this.cycle2Slot1,
      cycle2Slot2: cycle2Slot2 ?? this.cycle2Slot2,
      cycle2Slot3: cycle2Slot3 ?? this.cycle2Slot3,
      cycle4Slot1: cycle4Slot1 ?? this.cycle4Slot1,
      cycle4Slot2: cycle4Slot2 ?? this.cycle4Slot2,
      cycle4Slot3: cycle4Slot3 ?? this.cycle4Slot3,
      bishopName: bishopName ?? this.bishopName,
      lastSacramentConductorId: clearLastSacramentConductorId
          ? null
          : (lastSacramentConductorId ?? this.lastSacramentConductorId),
      lastBishopricConductorId: clearLastBishopricConductorId
          ? null
          : (lastBishopricConductorId ?? this.lastBishopricConductorId),
      wcOpeningPrayerIdx: wcOpeningPrayerIdx ?? this.wcOpeningPrayerIdx,
      wcClosingPrayerIdx: wcClosingPrayerIdx ?? this.wcClosingPrayerIdx,
      wcHandbookIdx: wcHandbookIdx ?? this.wcHandbookIdx,
      bpOpeningPrayerIdx: bpOpeningPrayerIdx ?? this.bpOpeningPrayerIdx,
      bpClosingPrayerIdx: bpClosingPrayerIdx ?? this.bpClosingPrayerIdx,
      bpHandbookIdx: bpHandbookIdx ?? this.bpHandbookIdx,
    );
  }

  Map<String, dynamic> toMap() => {
        'stake_name': stakeName,
        'ward_name': wardName,
        'acknowledgement_template': acknowledgementTemplate,
        'sacrament_time': sacramentTime,
        'bishopric_preferred_day': bishopricPreferredDay,
        'bishopric_thursday_time': bishopricThursdayTime,
        'bishopric_sunday_time': bishopricSundayTime,
        'ward_council_occurrences': wardCouncilOccurrences,
        'ward_council_time': wardCouncilTime,
        'speaker_cycle_base_month': speakerCycleBaseMonth,
        'cycle2_slot1': cycle2Slot1,
        'cycle2_slot2': cycle2Slot2,
        'cycle2_slot3': cycle2Slot3,
        'cycle4_slot1': cycle4Slot1,
        'cycle4_slot2': cycle4Slot2,
        'cycle4_slot3': cycle4Slot3,
        'bishop_name': bishopName,
        'last_sacrament_conductor_id': lastSacramentConductorId,
        'last_bishopric_conductor_id': lastBishopricConductorId,
        'wc_opening_prayer_idx': wcOpeningPrayerIdx,
        'wc_closing_prayer_idx': wcClosingPrayerIdx,
        'wc_handbook_idx': wcHandbookIdx,
        'bp_opening_prayer_idx': bpOpeningPrayerIdx,
        'bp_closing_prayer_idx': bpClosingPrayerIdx,
        'bp_handbook_idx': bpHandbookIdx,
      };

  factory WardConfig.fromMap(Map<String, dynamic> m) => WardConfig(
        stakeName: m['stake_name'] as String? ?? 'Pasay Philippine Stake',
        wardName: m['ward_name'] as String? ?? 'Pasay 3rd Ward',
        acknowledgementTemplate: m['acknowledgement_template'] as String? ??
            'Acknowledge {OTHER_CONDUCTORS}. {BISHOPRIC_OTHERS} To all Visitors and Stake Leaders (Welcome).',
        sacramentTime: m['sacrament_time'] as String? ?? '09:00',
        bishopricPreferredDay:
            m['bishopric_preferred_day'] as String? ?? 'Thursday',
        bishopricThursdayTime:
            m['bishopric_thursday_time'] as String? ?? '19:00',
        bishopricSundayTime: m['bishopric_sunday_time'] as String? ?? '12:00',
        wardCouncilOccurrences:
            m['ward_council_occurrences'] as String? ?? '1,3',
        wardCouncilTime: m['ward_council_time'] as String? ?? '11:00',
        speakerCycleBaseMonth:
            m['speaker_cycle_base_month'] as String? ?? '2026-01',
        cycle2Slot1: m['cycle2_slot1'] as String? ?? 'Relief Society',
        cycle2Slot2: m['cycle2_slot2'] as String? ?? 'Elders Quorum',
        cycle2Slot3: m['cycle2_slot3'] as String? ?? 'Ward Mission & Family History',
        cycle4Slot1: m['cycle4_slot1'] as String? ?? 'Sunday School',
        cycle4Slot2: m['cycle4_slot2'] as String? ?? 'Primary',
        cycle4Slot3: m['cycle4_slot3'] as String? ?? 'Youth',
        bishopName: m['bishop_name'] as String? ?? 'Bishop Sherwin Tan',
        lastSacramentConductorId:
            m['last_sacrament_conductor_id'] as int?,
        lastBishopricConductorId:
            m['last_bishopric_conductor_id'] as int?,
        wcOpeningPrayerIdx: m['wc_opening_prayer_idx'] as int?,
        wcClosingPrayerIdx: m['wc_closing_prayer_idx'] as int?,
        wcHandbookIdx: m['wc_handbook_idx'] as int?,
        bpOpeningPrayerIdx: m['bp_opening_prayer_idx'] as int?,
        bpClosingPrayerIdx: m['bp_closing_prayer_idx'] as int?,
        bpHandbookIdx: m['bp_handbook_idx'] as int?,
      );
}
