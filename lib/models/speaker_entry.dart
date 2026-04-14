// models/speaker_entry.dart
// An entry in the speaker rotation list (separate from Speaker in a program).
class SpeakerEntry {
  final int? id;
  final String name;
  final String organization; // e.g. Relief Society, Elders Quorum, Youth
  final int displayOrder;

  const SpeakerEntry({
    this.id,
    required this.name,
    this.organization = '',
    this.displayOrder = 0,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'organization': organization,
        'display_order': displayOrder,
      };

  factory SpeakerEntry.fromMap(Map<String, dynamic> m) => SpeakerEntry(
        id: m['id'] as int?,
        name: m['name'] as String? ?? '',
        organization: m['organization'] as String? ?? '',
        displayOrder: m['display_order'] as int? ?? 0,
      );

  SpeakerEntry copyWith(
          {int? id,
          String? name,
          String? organization,
          int? displayOrder}) =>
      SpeakerEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        organization: organization ?? this.organization,
        displayOrder: displayOrder ?? this.displayOrder,
      );
}
