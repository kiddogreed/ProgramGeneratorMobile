// models/ward_council_program.dart
// All fields mirror the Java WardCouncilProgram entity.

import 'agenda_item.dart';

class WardCouncilProgram {
  String wardName;
  DateTime meetingDate;
  String presiding;
  String conducting;
  String openingPrayer;
  String handbookReading;
  String auxiliary;          // which auxiliary is presenting
  List<AgendaItem> agendaItems;
  String welfare;
  String closingPrayer;

  WardCouncilProgram({
    this.wardName = 'Pasay 3rd',
    DateTime? meetingDate,
    this.presiding = '',
    this.conducting = '',
    this.openingPrayer = '',
    this.handbookReading = '',
    this.auxiliary = '',
    List<AgendaItem>? agendaItems,
    this.welfare = '',
    this.closingPrayer = '',
  })  : meetingDate = meetingDate ?? DateTime.now(),
        agendaItems = agendaItems ?? [];

  factory WardCouncilProgram.fromJson(Map<String, dynamic> json) =>
      WardCouncilProgram(
        wardName: json['wardName'] as String? ?? 'Pasay 3rd',
        meetingDate: json['meetingDate'] != null
            ? DateTime.parse(json['meetingDate'] as String)
            : DateTime.now(),
        presiding: json['presiding'] as String? ?? '',
        conducting: json['conducting'] as String? ?? '',
        openingPrayer: json['openingPrayer'] as String? ?? '',
        handbookReading: json['handbookReading'] as String? ?? '',
        auxiliary: json['auxiliary'] as String? ?? '',
        agendaItems: (json['agendaItems'] as List<dynamic>?)
                ?.map((e) => AgendaItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        welfare: json['welfare'] as String? ?? '',
        closingPrayer: json['closingPrayer'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'wardName': wardName,
        'meetingDate': meetingDate.toIso8601String().split('T').first,
        'presiding': presiding,
        'conducting': conducting,
        'openingPrayer': openingPrayer,
        'handbookReading': handbookReading,
        'auxiliary': auxiliary,
        'agendaItems': agendaItems.map((a) => a.toJson()).toList(),
        'welfare': welfare,
        'closingPrayer': closingPrayer,
      };
}
