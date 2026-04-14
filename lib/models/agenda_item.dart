// models/agenda_item.dart
// Represents a single agenda item used in Bishopric and Ward Council programs.

class AgendaItem {
  String title;
  List<String> details;

  AgendaItem({this.title = '', List<String>? details})
      : details = details ?? [];

  factory AgendaItem.fromJson(Map<String, dynamic> json) => AgendaItem(
        title: json['title'] as String? ?? '',
        details: (json['details'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'details': details,
      };

  AgendaItem copyWith({String? title, List<String>? details}) => AgendaItem(
        title: title ?? this.title,
        details: details ?? List.from(this.details),
      );
}
