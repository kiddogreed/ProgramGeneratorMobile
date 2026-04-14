// models/hymn.dart
class Hymn {
  final int? id;
  final String number;
  final String title;
  final int displayOrder;

  const Hymn({
    this.id,
    required this.number,
    required this.title,
    this.displayOrder = 0,
  });

  String get display => '${number.isNotEmpty ? "#$number – " : ""}$title';

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'number': number,
        'title': title,
        'display_order': displayOrder,
      };

  factory Hymn.fromMap(Map<String, dynamic> m) => Hymn(
        id: m['id'] as int?,
        number: m['number'] as String? ?? '',
        title: m['title'] as String? ?? '',
        displayOrder: m['display_order'] as int? ?? 0,
      );

  Hymn copyWith({int? id, String? number, String? title, int? displayOrder}) =>
      Hymn(
        id: id ?? this.id,
        number: number ?? this.number,
        title: title ?? this.title,
        displayOrder: displayOrder ?? this.displayOrder,
      );

  static List<Map<String, dynamic>> get seedData => [
        {'number': '2', 'title': 'The Spirit of God', 'display_order': 1},
        {'number': '19', 'title': 'We Thank Thee, O God, for a Prophet', 'display_order': 2},
        {'number': '27', 'title': 'Praise to the Man', 'display_order': 3},
        {'number': '65', 'title': 'Come, All Ye Sons of God', 'display_order': 4},
        {'number': '77', 'title': 'Great King of Heaven', 'display_order': 5},
        {'number': '116', 'title': 'Come, Ye Children of the Lord', 'display_order': 6},
        {'number': '169', 'title': 'As Now We Take the Sacrament', 'display_order': 7},
        {'number': '175', 'title': 'O God, the Eternal Father', 'display_order': 8},
        {'number': '176', 'title': 'Tis Sweet to Sing the Matchless Love', 'display_order': 9},
        {'number': '177', 'title': 'In Remembrance of Thy Suffering', 'display_order': 10},
        {'number': '178', 'title': 'O Lord of Hosts', 'display_order': 11},
        {'number': '179', 'title': 'Again, Our Dear Redeeming Lord', 'display_order': 12},
        {'number': '180', 'title': 'Father in Heaven, We Do Believe', 'display_order': 13},
        {'number': '181', 'title': 'Jesus of Nazareth, Savior and King', 'display_order': 14},
        {'number': '182', 'title': 'We\'ll Sing All Hail to Jesus\' Name', 'display_order': 15},
        {'number': '183', 'title': 'In Humility, Our Savior', 'display_order': 16},
        {'number': '184', 'title': 'Upon the Cross of Calvary', 'display_order': 17},
        {'number': '185', 'title': 'Reverently and Meekly Now', 'display_order': 18},
        {'number': '186', 'title': 'Again We Meet Around the Board', 'display_order': 19},
        {'number': '187', 'title': 'God Loved Us, So He Sent His Son', 'display_order': 20},
        {'number': '188', 'title': 'Thy Will, O Lord, Be Done', 'display_order': 21},
        {'number': '189', 'title': 'O Thou, Before the World Began', 'display_order': 22},
        {'number': '190', 'title': 'In Memory of the Crucified', 'display_order': 23},
        {'number': '191', 'title': 'Behold the Great Redeemer Die', 'display_order': 24},
        {'number': '192', 'title': 'He Died! The Great Redeemer Died', 'display_order': 25},
        {'number': '193', 'title': 'I Stand All Amazed', 'display_order': 26},
        {'number': '194', 'title': 'There Is a Green Hill Far Away', 'display_order': 27},
        {'number': '195', 'title': 'How Great the Wisdom and the Love', 'display_order': 28},
        {'number': '196', 'title': 'Jesus, Once of Humble Birth', 'display_order': 29},
        {'number': '197', 'title': "O Savior, Thou Who Wearest a Crown", 'display_order': 30},
      ];
}
