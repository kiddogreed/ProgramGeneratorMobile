// models/auxiliary.dart
// Mirrors the Auxiliary JPA entity. Used for Ward Council program type selector.

class Auxiliary {
  int? id;
  String name;

  Auxiliary({this.id, required this.name});

  factory Auxiliary.fromMap(Map<String, dynamic> map) => Auxiliary(
        id: map['id'] as int?,
        name: map['name'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
      };

  /// Default set seeded in the database on first launch.
  static const List<String> defaults = [
    'Bishopric',
    'Elders Quorum',
    'Relief Society',
    'Sunday School',
    'Primary',
    'Ward Mission & Family History',
    'Stake leaders',
  ];
}
