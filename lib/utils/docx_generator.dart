// utils/docx_generator.dart
// Generates a minimal DOCX file for Sacrament Meeting programs.
// DOCX format is a ZIP archive containing XML files per Office Open XML spec.

import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../models/sacrament_program.dart';

class DocxGenerator {
  /// Generate a DOCX [Uint8List] from a [SacramentProgram].
  static Uint8List generate(SacramentProgram p) {
    final archive = Archive();

    _addFile(archive, '[Content_Types].xml', _contentTypes());
    _addFile(archive, '_rels/.rels', _rootRels());
    _addFile(archive, 'word/document.xml', _documentXml(p));
    _addFile(archive, 'word/_rels/document.xml.rels', _documentRels());
    _addFile(archive, 'word/styles.xml', _styles());
    _addFile(archive, 'docProps/app.xml', _appXml());

    final encoder = ZipEncoder();
    final bytes = encoder.encode(archive);
    return Uint8List.fromList(bytes!);
  }

  static void _addFile(Archive archive, String path, String xml) {
    final data = Uint8List.fromList(xml.codeUnits);
    archive.addFile(ArchiveFile(path, data.length, data));
  }

  // ────────────────────────────── XML parts ──────────────────────────────

  static String _contentTypes() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml"
    ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml"
    ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/app.xml"
    ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';

  static String _rootRels() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1"
    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
    Target="word/document.xml"/>
  <Relationship Id="rId2"
    Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties"
    Target="docProps/app.xml"/>
</Relationships>''';

  static String _documentRels() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1"
    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"
    Target="styles.xml"/>
</Relationships>''';

  static String _appXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
  <Application>Church Program Generator</Application>
</Properties>''';

  static String _styles() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:styleId="Heading1" w:default="0">
    <w:name w:val="heading 1"/>
    <w:pPr><w:jc w:val="center"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="28"/><w:color w:val="1B4F8A"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2" w:default="0">
    <w:name w:val="heading 2"/>
    <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="1B4F8A"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Normal" w:default="1">
    <w:name w:val="Normal"/>
    <w:rPr><w:sz w:val="22"/></w:rPr>
  </w:style>
</w:styles>''';

  static String _documentXml(SacramentProgram p) {
    final body = StringBuffer();

    // Header
    body.writeln(_heading(p.wardName ?? 'Ward Name', size: 28, bold: true, center: true, color: '1B4F8A'));
    if (p.stakeName != null && p.stakeName!.isNotEmpty) {
      body.writeln(_paragraph(p.stakeName!, center: true, size: 22));
    }
    body.writeln(_paragraph('Sacrament Meeting', center: true, bold: true, size: 24));
    body.writeln(_paragraph(_formatDate(p.date.toIso8601String()), center: true, size: 22));
    body.writeln(_separator());

    // Presiding / Conducting
    if (p.presiding != null && p.presiding!.isNotEmpty) {
      body.writeln(_labelValue('Presiding', p.presiding!));
    }
    if (p.conducting != null && p.conducting!.isNotEmpty) {
      body.writeln(_labelValue('Conducting', p.conducting!));
    }

    // Hymns
    if (p.openingHymn != null && p.openingHymn!.isNotEmpty) {
      body.writeln(_labelValue('Opening Hymn', p.openingHymn!));
    }
    if (p.invocation.isNotEmpty) {
      body.writeln(_labelValue('Opening Prayer', p.invocation));
    }
    if (p.sacramentHymn != null && p.sacramentHymn!.isNotEmpty) {
      body.writeln(_labelValue('Sacrament Hymn', p.sacramentHymn!));
    }

    // Speakers
    if (p.speakers != null && p.speakers!.isNotEmpty) {
      body.writeln(_sectionTitle('Speakers'));
      for (final s in p.speakers!) {
        body.writeln(_paragraph(
          '${s.name}${s.topic != null && s.topic!.isNotEmpty ? " — ${s.topic}" : ""}',
          indent: true,
        ));
      }
    }

    if (p.closingHymn != null && p.closingHymn!.isNotEmpty) {
      body.writeln(_labelValue('Closing Hymn', p.closingHymn!));
    }
    if (p.benediction.isNotEmpty) {
      body.writeln(_labelValue('Closing Prayer', p.benediction));
    }

    // Acknowledgements
    if (p.acknowledgement.isNotEmpty) {
      body.writeln(_sectionTitle('Acknowledgements'));
      body.writeln(_paragraph(p.acknowledgement, italic: true));
    }

    // Announcements
    if (p.announcements != null && p.announcements!.isNotEmpty) {
      body.writeln(_sectionTitle('Announcements'));
      for (final a in p.announcements!) {
        body.writeln(_paragraph('• $a', indent: true));
      }
    }

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
$body
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>
    </w:sectPr>
  </w:body>
</w:document>''';
  }

  // ────────────────────────── XML builder helpers ────────────────────────────

  static String _heading(String text,
      {int size = 28, bool bold = false, bool center = false, String? color}) {
    final jc = center ? '<w:jc w:val="center"/>' : '';
    final b = bold ? '<w:b/>' : '';
    final col = color != null ? '<w:color w:val="$color"/>' : '';
    return '''    <w:p>
      <w:pPr>$jc</w:pPr>
      <w:r>
        <w:rPr>$b<w:sz w:val="$size"/>$col</w:rPr>
        <w:t>${_esc(text)}</w:t>
      </w:r>
    </w:p>''';
  }

  static String _paragraph(String text,
      {bool bold = false,
      bool italic = false,
      bool center = false,
      bool indent = false,
      int size = 22}) {
    final jc = center ? '<w:jc w:val="center"/>' : '';
    final ind = indent ? '<w:ind w:left="360"/>' : '';
    final b = bold ? '<w:b/>' : '';
    final i = italic ? '<w:i/>' : '';
    return '''    <w:p>
      <w:pPr>$jc$ind</w:pPr>
      <w:r>
        <w:rPr>$b$i<w:sz w:val="$size"/></w:rPr>
        <w:t xml:space="preserve">${_esc(text)}</w:t>
      </w:r>
    </w:p>''';
  }

  static String _labelValue(String label, String value) {
    return '''    <w:p>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="22"/></w:rPr>
        <w:t xml:space="preserve">${_esc(label)}: </w:t>
      </w:r>
      <w:r>
        <w:rPr><w:sz w:val="22"/></w:rPr>
        <w:t>${_esc(value)}</w:t>
      </w:r>
    </w:p>''';
  }

  static String _sectionTitle(String text) {
    return '''    <w:p>
      <w:pPr><w:spacing w:before="120"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="1B4F8A"/></w:rPr>
        <w:t>${_esc(text)}</w:t>
      </w:r>
    </w:p>''';
  }

  static String _separator() {
    return '''    <w:p>
      <w:pPr>
        <w:pBdr>
          <w:bottom w:val="single" w:sz="4" w:space="1" w:color="1B4F8A"/>
        </w:pBdr>
      </w:pPr>
    </w:p>''';
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final d = DateTime.parse(dateStr);
      const months = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[d.month]} ${d.day}, ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
