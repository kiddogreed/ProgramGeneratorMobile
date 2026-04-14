// models/speaker.dart
// Represents a speaker in a Sacrament Meeting program.

class Speaker {
  int order;
  String name;
  String title;
  String topic;

  Speaker({
    this.order = 0,
    this.name = '',
    this.title = '',
    this.topic = '',
  });

  factory Speaker.fromJson(Map<String, dynamic> json) => Speaker(
        order: (json['order'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        title: json['title'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'order': order,
        'name': name,
        'title': title,
        'topic': topic,
      };

  Speaker copyWith({int? order, String? name, String? title, String? topic}) =>
      Speaker(
        order: order ?? this.order,
        name: name ?? this.name,
        title: title ?? this.title,
        topic: topic ?? this.topic,
      );
}
