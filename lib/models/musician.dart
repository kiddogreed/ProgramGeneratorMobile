// models/musician.dart
// Maps to the Musician JPA entity. musicianType is "chorister" or "pianist".

class Musician {
  int? id;
  String name;
  String musicianType; // "chorister" or "pianist"
  int displayOrder;

  Musician({
    this.id,
    required this.name,
    this.musicianType = 'chorister',
    this.displayOrder = 0,
  });

  factory Musician.fromMap(Map<String, dynamic> map) => Musician(
        id: map['id'] as int?,
        name: map['name'] as String,
        musicianType: map['musician_type'] as String? ?? 'chorister',
        displayOrder: map['display_order'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'musician_type': musicianType,
        'display_order': displayOrder,
      };
}
