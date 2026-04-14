// models/bishopric_program.dart
// All fields mirror the Java BishopricProgram entity.

import 'agenda_item.dart';

class BishopricProgram {
  String wardName;
  DateTime meetingDate;
  String presiding;  // max 150 chars
  String conducting; // max 150 chars
  String openingPrayer;      // max 150 chars
  String handbookSpiritual;  // max 300 chars
  List<AgendaItem> agendaItems;
  String callingsAndReleases; // max 500 chars
  String closingPrayer;       // max 150 chars

  BishopricProgram({
    this.wardName = '3rd Ward',
    DateTime? meetingDate,
    this.presiding = '',
    this.conducting = '',
    this.openingPrayer = '',
    this.handbookSpiritual = '',
    List<AgendaItem>? agendaItems,
    this.callingsAndReleases = '',
    this.closingPrayer = '',
  })  : meetingDate = meetingDate ?? DateTime.now(),
        agendaItems = agendaItems ?? [];

  factory BishopricProgram.fromJson(Map<String, dynamic> json) =>
      BishopricProgram(
        wardName: json['wardName'] as String? ?? '3rd Ward',
        meetingDate: json['meetingDate'] != null
            ? DateTime.parse(json['meetingDate'] as String)
            : DateTime.now(),
        presiding: json['presiding'] as String? ?? '',
        conducting: json['conducting'] as String? ?? '',
        openingPrayer: json['openingPrayer'] as String? ?? '',
        handbookSpiritual: json['handbookSpiritual'] as String? ?? '',
        agendaItems: (json['agendaItems'] as List<dynamic>?)
                ?.map((e) => AgendaItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        callingsAndReleases: json['callingsAndReleases'] as String? ?? '',
        closingPrayer: json['closingPrayer'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'wardName': wardName,
        'meetingDate': meetingDate.toIso8601String().split('T').first,
        'presiding': presiding,
        'conducting': conducting,
        'openingPrayer': openingPrayer,
        'handbookSpiritual': handbookSpiritual,
        'agendaItems': agendaItems.map((a) => a.toJson()).toList(),
        'callingsAndReleases': callingsAndReleases,
        'closingPrayer': closingPrayer,
      };
}
