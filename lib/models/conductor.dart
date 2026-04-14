// models/conductor.dart
// Maps to the Conductor JPA entity.
// programType values: "sacrament", "bishopric", "ward_council"

class Conductor {
  int? id;
  String name;
  int displayOrder;
  String programType; // "sacrament" | "bishopric" | "ward_council"

  Conductor({
    this.id,
    required this.name,
    this.displayOrder = 0,
    this.programType = 'sacrament',
  });

  factory Conductor.fromMap(Map<String, dynamic> map) => Conductor(
        id: map['id'] as int?,
        name: map['name'] as String,
        displayOrder: map['display_order'] as int? ?? 0,
        programType: map['program_type'] as String? ?? 'sacrament',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'display_order': displayOrder,
        'program_type': programType,
      };
}
