// models/handbook_reading.dart
class HandbookReading {
  final int? id;
  final String title;
  final String reference; // e.g. "Handbook 2: Section 4.2"
  final int displayOrder;

  const HandbookReading({
    this.id,
    required this.title,
    this.reference = '',
    this.displayOrder = 0,
  });

  String get display =>
      reference.isNotEmpty ? '$title ($reference)' : title;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'reference': reference,
        'display_order': displayOrder,
      };

  factory HandbookReading.fromMap(Map<String, dynamic> m) => HandbookReading(
        id: m['id'] as int?,
        title: m['title'] as String? ?? '',
        reference: m['reference'] as String? ?? '',
        displayOrder: m['display_order'] as int? ?? 0,
      );

  HandbookReading copyWith(
          {int? id,
          String? title,
          String? reference,
          int? displayOrder}) =>
      HandbookReading(
        id: id ?? this.id,
        title: title ?? this.title,
        reference: reference ?? this.reference,
        displayOrder: displayOrder ?? this.displayOrder,
      );

  static List<Map<String, dynamic>> get seedData => [
        {'title': 'Strengthening the Family', 'reference': 'General Handbook 2.1', 'display_order': 1},
        {'title': 'Ward Organization and Leadership', 'reference': 'General Handbook 7', 'display_order': 2},
        {'title': 'Supporting Individuals and Families', 'reference': 'General Handbook 22', 'display_order': 3},
        {'title': 'Temporal Self-Reliance', 'reference': 'General Handbook 22.1', 'display_order': 4},
        {'title': 'Welfare Principles', 'reference': 'General Handbook 22.2', 'display_order': 5},
        {'title': 'Temple and Family History Work', 'reference': 'General Handbook 25', 'display_order': 6},
        {'title': 'Sharing the Gospel', 'reference': 'General Handbook 23', 'display_order': 7},
        {'title': 'Callings and Service', 'reference': 'General Handbook 4', 'display_order': 8},
      ];
}
