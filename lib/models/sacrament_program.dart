// models/sacrament_program.dart
// All fields mirror the Java SacramentProgram entity.

import 'speaker.dart';

class SacramentProgram {
  String stakeName;
  String wardName;
  DateTime date;
  String presiding;
  String conducting;
  String acknowledgement; // max 600 characters
  List<String> announcements;

  // Music
  String chorister;
  String pianist;
  String openingHymn;
  String sacramentHymn;
  String closingHymn;

  // Program sections
  String invocation;
  String wardBusiness;   // max 400 characters
  String stakeBusiness;  // max 400 characters
  List<Speaker> speakers;
  String speakersAuxiliary;
  String benediction;

  SacramentProgram({
    this.stakeName = '',
    this.wardName = '',
    DateTime? date,
    this.presiding = '',
    this.conducting = '',
    this.acknowledgement = '',
    List<String>? announcements,
    this.chorister = '',
    this.pianist = '',
    this.openingHymn = '',
    this.sacramentHymn = '',
    this.closingHymn = '',
    this.invocation = '',
    this.wardBusiness = '',
    this.stakeBusiness = '',
    List<Speaker>? speakers,
    this.speakersAuxiliary = '',
    this.benediction = '',
  })  : date = date ?? DateTime.now(),
        announcements = announcements ?? [],
        speakers = speakers ?? [];

  factory SacramentProgram.fromJson(Map<String, dynamic> json) =>
      SacramentProgram(
        stakeName: json['stakeName'] as String? ?? '',
        wardName: json['wardName'] as String? ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        presiding: json['presiding'] as String? ?? '',
        conducting: json['conducting'] as String? ?? '',
        acknowledgement: json['acknowledgement'] as String? ?? '',
        announcements: (json['announcements'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        chorister: json['chorister'] as String? ?? '',
        pianist: json['pianist'] as String? ?? '',
        openingHymn: json['openingHymn'] as String? ?? '',
        sacramentHymn: json['sacramentHymn'] as String? ?? '',
        closingHymn: json['closingHymn'] as String? ?? '',
        invocation: json['invocation'] as String? ?? '',
        wardBusiness: json['wardBusiness'] as String? ?? '',
        stakeBusiness: json['stakeBusiness'] as String? ?? '',
        speakers: (json['speakers'] as List<dynamic>?)
                ?.map((e) => Speaker.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        speakersAuxiliary: json['speakersAuxiliary'] as String? ?? '',
        benediction: json['benediction'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'stakeName': stakeName,
        'wardName': wardName,
        'date': date.toIso8601String().split('T').first,
        'presiding': presiding,
        'conducting': conducting,
        'acknowledgement': acknowledgement,
        'announcements': announcements,
        'chorister': chorister,
        'pianist': pianist,
        'openingHymn': openingHymn,
        'sacramentHymn': sacramentHymn,
        'closingHymn': closingHymn,
        'invocation': invocation,
        'wardBusiness': wardBusiness,
        'stakeBusiness': stakeBusiness,
        'speakers': speakers.map((s) => s.toJson()).toList(),
        'speakersAuxiliary': speakersAuxiliary,
        'benediction': benediction,
      };
}
