// utils/pdf_generator.dart
// Builds a PDF document from any of the three program types and returns
// a Uint8List suitable for printing or sharing.

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/sacrament_program.dart';
import '../models/bishopric_program.dart';
import '../models/ward_council_program.dart';

// ── Colour palette (matches web app style) ──────────────────────────────────
const _green = PdfColor.fromInt(0xFF2E7D32);
const _purple = PdfColor.fromInt(0xFF6A1B9A);
const _red = PdfColor.fromInt(0xFFC62828);
const _navy = PdfColor.fromInt(0xFF1B4F8A);

class PdfGenerator {
  /// Load logo bytes from assets, returning null on error.
  static Future<pw.MemoryImage?> _loadLogo(String? logoPath) async {
    try {
      final assetPath = (logoPath != null && logoPath.isNotEmpty)
          ? logoPath
          : 'assets/images/P3_LOGO.png';
      final data = await rootBundle.load(assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  // ── Sacrament Meeting ──────────────────────────────────────────────────

  static Future<Uint8List> sacrament(SacramentProgram p,
      {bool singlePage = false, String? logoPath}) async {
    final doc = pw.Document();
    final dateStr = DateFormat('MMMM d, yyyy').format(p.date);
    final logo = await _loadLogo(logoPath);

    final widgets = [
        _churchHeader(p.stakeName, p.wardName, 'Sacrament Meeting', dateStr,
            _green, logo: logo),
        pw.SizedBox(height: 10),
        _row2('Presiding', p.presiding, 'Conducting', p.conducting),
        pw.SizedBox(height: 6),
        _row2('Chorister', p.chorister, 'Pianist', p.pianist),
        pw.SizedBox(height: 6),
        _row2('Opening Hymn', p.openingHymn, 'Sacrament Hymn',
            p.sacramentHymn),
        pw.SizedBox(height: 6),
        _labelValue('Closing Hymn', p.closingHymn),
        _divider(),
        _labelValue('Invocation', p.invocation),
        if (p.wardBusiness.isNotEmpty)
          _labelValue('Ward Business', p.wardBusiness),
        if (p.stakeBusiness.isNotEmpty)
          _labelValue('Stake Business', p.stakeBusiness),
        _divider(),
        if (p.speakers.isNotEmpty) ...[
          _sectionTitle('Speakers', _green),
          if (p.speakersAuxiliary.isNotEmpty)
            _labelValue('Auxiliary', p.speakersAuxiliary),
          ...p.speakers.map((s) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(children: [
                  pw.Expanded(
                      child: pw.Text('${s.name}  –  ${s.title}',
                          style: const pw.TextStyle(fontSize: 11))),
                  if (s.topic.isNotEmpty)
                    pw.Text('(${s.topic})',
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                            fontStyle: pw.FontStyle.italic)),
                ]),
              )),
          _divider(),
        ],
        _labelValue('Benediction', p.benediction),
        if (p.acknowledgement.isNotEmpty)
          _labelValue('Acknowledgement', p.acknowledgement),
        if (p.announcements.isNotEmpty) ...[
          _sectionTitle('Announcements', _green),
          ...p.announcements.map((a) => pw.Bullet(text: a)),
        ],
    ];

    _addPage(doc, widgets, singlePage: singlePage);
    return doc.save();
  }

  // ── Bishopric Meeting ──────────────────────────────────────────────────

  static Future<Uint8List> bishopric(BishopricProgram p,
      {bool singlePage = false, String? logoPath}) async {
    final doc = pw.Document();
    final dateStr = DateFormat('MMMM d, yyyy').format(p.meetingDate);
    final logo = await _loadLogo(logoPath);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => [
        _churchHeader('', p.wardName, 'Bishopric Meeting', dateStr, _red,
            logo: logo),
        pw.SizedBox(height: 10),
        _row2('Presiding', p.presiding, 'Conducting', p.conducting),
        _divider(),
        _labelValue('Opening Prayer', p.openingPrayer),
        if (p.handbookSpiritual.isNotEmpty)
          _labelValue('Handbook / Spiritual Thought', p.handbookSpiritual),
        _divider(),
        _sectionTitle('Agenda', _red),
        ...p.agendaItems.map((item) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(item.title,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ...item.details.map((d) => pw.Padding(
                      padding:
                          const pw.EdgeInsets.only(left: 12, top: 2),
                      child: pw.Bullet(text: d),
                    )),
                pw.SizedBox(height: 4),
              ],
            )),
        _divider(),
        if (p.callingsAndReleases.isNotEmpty)
          _labelValue('Callings & Releases', p.callingsAndReleases),
        _labelValue('Closing Prayer', p.closingPrayer),
      ],
    ));

    return doc.save();
  }

  // ── Ward Council ───────────────────────────────────────────────────────

  static Future<Uint8List> wardCouncil(WardCouncilProgram p,
      {bool singlePage = false, String? logoPath}) async {
    final doc = pw.Document();
    final dateStr = DateFormat('MMMM d, yyyy').format(p.meetingDate);
    final logo = await _loadLogo(logoPath);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => [
        _churchHeader('', p.wardName, 'Ward Council Meeting', dateStr, _purple,
            logo: logo),
        pw.SizedBox(height: 10),
        _row2('Presiding', p.presiding, 'Conducting', p.conducting),
        _divider(),
        _labelValue('Opening Prayer', p.openingPrayer),
        if (p.handbookReading.isNotEmpty)
          _labelValue('Handbook Reading', p.handbookReading),
        if (p.auxiliary.isNotEmpty)
          _labelValue('Reporting Auxiliary', p.auxiliary),
        _divider(),
        _sectionTitle('Agenda', _purple),
        ...p.agendaItems.map((item) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(item.title,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ...item.details.map((d) => pw.Padding(
                      padding:
                          const pw.EdgeInsets.only(left: 12, top: 2),
                      child: pw.Bullet(text: d),
                    )),
                pw.SizedBox(height: 4),
              ],
            )),
        _divider(),
        if (p.welfare.isNotEmpty) _labelValue('Welfare', p.welfare),
        _labelValue('Closing Prayer', p.closingPrayer),
      ],
    ));

    return doc.save();
  }

  // ── Page helper: MultiPage or single scaled page ──────────────────────

  static void _addPage(pw.Document doc, List<pw.Widget> widgets,
      {bool singlePage = false}) {
    if (!singlePage) {
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => widgets,
      ));
    } else {
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) {
          final availH = ctx.page.pageFormat.availableHeight;
          final availW = ctx.page.pageFormat.availableWidth;
          return pw.FittedBox(
            fit: pw.BoxFit.contain,
            alignment: pw.Alignment.topCenter,
            child: pw.SizedBox(
              width: availW,
              height: availH,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: widgets,
              ),
            ),
          );
        },
      ));
    }
  }

  // ── Shared helpers ─────────────────────────────────────────────────────

  static pw.Widget _churchHeader(String stake, String ward, String meeting,
      String date, PdfColor color, {pw.MemoryImage? logo}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(logo, height: 40, width: 40),
            ],
          ),
        if (logo != null) pw.SizedBox(height: 4),
        if (stake.isNotEmpty)
          pw.Text(stake,
              style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                  fontStyle: pw.FontStyle.italic)),
        pw.Text(ward,
            style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color)),
        pw.Text(meeting,
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _navy)),
        pw.Text(date, style: const pw.TextStyle(fontSize: 12)),
        pw.Divider(color: color, thickness: 1.5),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title, PdfColor color) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Text(title,
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: color)),
      );

  static pw.Widget _divider() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Divider(color: PdfColors.grey300),
      );

  static pw.Widget _labelValue(String label, String value) {
    if (value.isEmpty) return pw.SizedBox(height: 0);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _row2(
      String l1, String v1, String l2, String v2) {
    return pw.Row(children: [
      pw.Expanded(child: _labelValue(l1, v1)),
      pw.SizedBox(width: 10),
      pw.Expanded(child: _labelValue(l2, v2)),
    ]);
  }
}
