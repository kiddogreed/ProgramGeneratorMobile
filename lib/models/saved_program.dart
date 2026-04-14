// models/saved_program.dart
// Mirrors the SavedProgram JPA entity. programData holds a JSON-encoded program.

class SavedProgram {
  int? id;
  String meetingType;   // "SACRAMENT" | "WARD_COUNCIL" | "BISHOPRIC"
  String description;   // e.g. "Sacrament – Pasay 3rd Ward – 2026-04-13"
  DateTime meetingDate;
  String programData;   // JSON-serialised program object
  DateTime createdAt;

  SavedProgram({
    this.id,
    required this.meetingType,
    required this.description,
    required this.meetingDate,
    required this.programData,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SavedProgram.fromMap(Map<String, dynamic> map) => SavedProgram(
        id: map['id'] as int?,
        meetingType: map['meeting_type'] as String,
        description: map['description'] as String,
        meetingDate: DateTime.parse(map['meeting_date'] as String),
        programData: map['program_data'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'meeting_type': meetingType,
        'description': description,
        'meeting_date': meetingDate.toIso8601String().split('T').first,
        'program_data': programData,
        'created_at': createdAt.toIso8601String(),
      };
}
