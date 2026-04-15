// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
// screens/ward_council/ward_council_preview_screen.dart
// On-screen preview for Ward Council Meeting with Save / Print / Share / PNG.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/ward_council_program.dart';
import '../../models/agenda_item.dart';
import '../../utils/pdf_generator.dart';
import '../../utils/png_generator.dart';
import '../../utils/program_storage.dart';

class WardCouncilPreviewScreen extends StatefulWidget {
  final WardCouncilProgram program;

  const WardCouncilPreviewScreen({super.key, required this.program});

  @override
  State<WardCouncilPreviewScreen> createState() =>
      _WardCouncilPreviewScreenState();
}

class _WardCouncilPreviewScreenState extends State<WardCouncilPreviewScreen> {
  final _screenshotCtrl = ScreenshotController();

  Future<void> _save() async {
    await ProgramStorage().saveWardCouncil(widget.program);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Program saved')));
    }
  }

  Future<void> _exportPdf() async {
    final bytes = await PdfGenerator.wardCouncil(widget.program);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _sharePdf() async {
    final bytes = await PdfGenerator.wardCouncil(widget.program);
    final dir = await getTemporaryDirectory();
    final dateStr =
        DateFormat('yyyy-MM-dd').format(widget.program.meetingDate);
    final file =
        File('${dir.path}/ward_council_$dateStr.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Ward Council – ${widget.program.wardName} – $dateStr',
    );
  }

  Future<void> _exportPng() async {
    final bytes = await PngGenerator.captureWidget(_screenshotCtrl);
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PNG capture failed')),
        );
      }
      return;
    }
    final dateStr =
        DateFormat('yyyy-MM-dd').format(widget.program.meetingDate);
    if (mounted) {
      await PngGenerator.shareAsPng(
          bytes, 'ward_council_$dateStr.png', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final dateStr =
        DateFormat('MMMM d, yyyy').format(program.meetingDate);
    const accent = Color(0xFF6A1B9A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ward Council Preview'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFFF3E5F5),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white),
                    ),
                    OutlinedButton.icon(
                      onPressed: _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Print / PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _sharePdf,
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _exportPng,
                      icon: const Icon(Icons.image),
                      label: const Text('Export PNG'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Screenshot wrapper captures the program card as PNG
            Screenshot(
              controller: _screenshotCtrl,
              child: LayoutBuilder(
                builder: (context, constraints) => FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 595,
                    child: Card(
                      child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(program.wardName,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: accent)),
                    const Text('Ward Council Meeting',
                        style: TextStyle(fontSize: 16, color: accent)),
                    Text(dateStr,
                        style: const TextStyle(fontSize: 14)),
                    const Divider(
                        height: 24, color: accent, thickness: 1.5),
                    _row2('Presiding', program.presiding, 'Conducting',
                        program.conducting),
                    _divider(),
                    _lv('Opening Prayer', program.openingPrayer),
                    if (program.handbookReading.isNotEmpty)
                      _lv('Handbook Reading', program.handbookReading),
                    if (program.auxiliary.isNotEmpty)
                      _lv('Reporting Auxiliary', program.auxiliary),
                    _divider(),
                    if (program.agendaItems.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Agenda',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: accent)),
                      ),
                      const SizedBox(height: 6),
                      ...program.agendaItems
                          .map((item) => _agendaTile(item)),
                      _divider(),
                    ],
                    if (program.welfare.isNotEmpty)
                      _lv('Welfare', program.welfare),
                    _lv('Closing Prayer', program.closingPrayer),
                  ],  // Column children
                ),    // Column
              ),      // Padding
            ),        // Card
                  ),  // SizedBox
                ),    // FittedBox
              ),      // LayoutBuilder
          ),          // Screenshot
          ],          // outer Column children
        ),            // outer Column
      ),              // SingleChildScrollView
    );
  }

  Widget _agendaTile(AgendaItem item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
            ...item.details.map((d) => Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Text('• $d',
                      style: const TextStyle(fontSize: 12)),
                )),
          ],
        ),
      );

  Widget _row2(String l1, String v1, String l2, String v2) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: _lv(l1, v1)),
            Expanded(child: _lv(l2, v2)),
          ],
        ),
      );

  Widget _lv(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: Colors.grey, height: 1),
      );
}
