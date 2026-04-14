// models/ward_config.dart
// Singleton row that stores all automation rules, rotation indices, and
// ward-level settings – mirrors the Spring Boot ward_config table.

class WardConfig {
  // Ward identity
  String wardName;
  String stakeName;
  String meetingTime; // e.g. "9:00 AM"
  String logoPath;    // 'assets/images/P3_LOGO.png' or custom file path

  // Sacrament meeting automation
  String sacramentSchedule; // 'EVERY_SUNDAY' | '1ST_3RD' | '2ND_4TH'
  String speakerCycleJson;  // JSON list of cycle entries
  int speakerCycleIndex;
  String acknowledgementTemplate;

  // Bishopric meeting automation
  String bishopricSchedule; // 'EVERY_THURSDAY' | 'EVERY_MONDAY' | 'CUSTOM'
  String bishopricPresiding; // always "The Bishop" by default
  int bishopricPrayerIndex;  // rotation index into conductors

  // Ward council automation
  String wardCouncilSchedule; // 'EVERY_SUNDAY_AFTER' | 'CUSTOM'
  int wcOpeningPrayerIndex;   // round-robin index into auxiliaries
  int wcClosingPrayerIndex;
  int wcHandbookIndex;        // rotation index into handbook_readings

  WardConfig({
    this.wardName = 'Pasay 3rd Ward',
    this.stakeName = 'Pasay Philippines Stake',
    this.meetingTime = '9:00 AM',
    this.logoPath = 'assets/images/P3_LOGO.png',
    this.sacramentSchedule = 'EVERY_SUNDAY',
    this.speakerCycleJson = '[]',
    this.speakerCycleIndex = 0,
    this.acknowledgementTemplate =
        'We acknowledge those who have attended from other wards and stakes.',
    this.bishopricSchedule = 'EVERY_THURSDAY',
    this.bishopricPresiding = 'The Bishop',
    this.bishopricPrayerIndex = 0,
    this.wardCouncilSchedule = 'EVERY_SUNDAY_AFTER',
    this.wcOpeningPrayerIndex = 0,
    this.wcClosingPrayerIndex = 0,
    this.wcHandbookIndex = 0,
  });

  WardConfig copyWith({
    String? wardName,
    String? stakeName,
    String? meetingTime,
    String? logoPath,
    String? sacramentSchedule,
    String? speakerCycleJson,
    int? speakerCycleIndex,
    String? acknowledgementTemplate,
    String? bishopricSchedule,
    String? bishopricPresiding,
    int? bishopricPrayerIndex,
    String? wardCouncilSchedule,
    int? wcOpeningPrayerIndex,
    int? wcClosingPrayerIndex,
    int? wcHandbookIndex,
  }) {
    return WardConfig(
      wardName: wardName ?? this.wardName,
      stakeName: stakeName ?? this.stakeName,
      meetingTime: meetingTime ?? this.meetingTime,
      logoPath: logoPath ?? this.logoPath,
      sacramentSchedule: sacramentSchedule ?? this.sacramentSchedule,
      speakerCycleJson: speakerCycleJson ?? this.speakerCycleJson,
      speakerCycleIndex: speakerCycleIndex ?? this.speakerCycleIndex,
      acknowledgementTemplate:
          acknowledgementTemplate ?? this.acknowledgementTemplate,
      bishopricSchedule: bishopricSchedule ?? this.bishopricSchedule,
      bishopricPresiding: bishopricPresiding ?? this.bishopricPresiding,
      bishopricPrayerIndex: bishopricPrayerIndex ?? this.bishopricPrayerIndex,
      wardCouncilSchedule: wardCouncilSchedule ?? this.wardCouncilSchedule,
      wcOpeningPrayerIndex: wcOpeningPrayerIndex ?? this.wcOpeningPrayerIndex,
      wcClosingPrayerIndex: wcClosingPrayerIndex ?? this.wcClosingPrayerIndex,
      wcHandbookIndex: wcHandbookIndex ?? this.wcHandbookIndex,
    );
  }

  Map<String, dynamic> toMap() => {
        'ward_name': wardName,
        'stake_name': stakeName,
        'meeting_time': meetingTime,
        'logo_path': logoPath,
        'sacrament_schedule': sacramentSchedule,
        'speaker_cycle_json': speakerCycleJson,
        'speaker_cycle_index': speakerCycleIndex,
        'acknowledgement_template': acknowledgementTemplate,
        'bishopric_schedule': bishopricSchedule,
        'bishopric_presiding': bishopricPresiding,
        'bishopric_prayer_index': bishopricPrayerIndex,
        'ward_council_schedule': wardCouncilSchedule,
        'wc_opening_prayer_index': wcOpeningPrayerIndex,
        'wc_closing_prayer_index': wcClosingPrayerIndex,
        'wc_handbook_index': wcHandbookIndex,
      };

  factory WardConfig.fromMap(Map<String, dynamic> m) => WardConfig(
        wardName: m['ward_name'] as String? ?? 'Pasay 3rd Ward',
        stakeName: m['stake_name'] as String? ?? 'Pasay Philippines Stake',
        meetingTime: m['meeting_time'] as String? ?? '9:00 AM',
        logoPath: m['logo_path'] as String? ?? 'assets/images/P3_LOGO.png',
        sacramentSchedule:
            m['sacrament_schedule'] as String? ?? 'EVERY_SUNDAY',
        speakerCycleJson: m['speaker_cycle_json'] as String? ?? '[]',
        speakerCycleIndex: m['speaker_cycle_index'] as int? ?? 0,
        acknowledgementTemplate: m['acknowledgement_template'] as String? ??
            'We acknowledge those who have attended from other wards and stakes.',
        bishopricSchedule:
            m['bishopric_schedule'] as String? ?? 'EVERY_THURSDAY',
        bishopricPresiding:
            m['bishopric_presiding'] as String? ?? 'The Bishop',
        bishopricPrayerIndex: m['bishopric_prayer_index'] as int? ?? 0,
        wardCouncilSchedule:
            m['ward_council_schedule'] as String? ?? 'EVERY_SUNDAY_AFTER',
        wcOpeningPrayerIndex: m['wc_opening_prayer_index'] as int? ?? 0,
        wcClosingPrayerIndex: m['wc_closing_prayer_index'] as int? ?? 0,
        wcHandbookIndex: m['wc_handbook_index'] as int? ?? 0,
      );
}
