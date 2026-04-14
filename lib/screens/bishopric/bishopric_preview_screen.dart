// screens/bishopric/bishopric_preview_screen.dart
// On-screen preview for Bishopric Meeting with Save / Print / Share.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/bishopric_program.dart';
import '../../models/agenda_item.dart';
import '../../utils/pdf_generator.dart';
import '../../utils/program_storage.dart';

class BishopricPreviewScreen extends StatelessWidget {
  final BishopricProgram program;

  const BishopricPreviewScreen({super.key, required this.program});

  Future<void> _save(BuildContext context) async {
    await ProgramStorage().saveBishopric(program);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program saved to history')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final bytes = await PdfGenerator.bishopric(program);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _sharePdf(BuildContext context) async {
    final bytes = await PdfGenerator.bishopric(program);
    final dir = await getTemporaryDirectory();
    final dateStr =
        DateFormat('yyyy-MM-dd').format(program.meetingDate);
    final file = File('${dir.path}/bishopric_$dateStr.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject:
          'Bishopric Meeting – ${program.wardName} – $dateStr',
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('MMMM d, yyyy').format(program.meetingDate);
    const accent = Color(0xFFC62828);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bishopric Preview'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFFFFEBEE),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _save(context),
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportPdf(context),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Print / PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _sharePdf(context),
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
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
                    const Text('Bishopric Meeting',
                        style: TextStyle(fontSize: 16, color: accent)),
                    Text(dateStr,
                        style: const TextStyle(fontSize: 14)),
                    const Divider(
                        height: 24, color: accent, thickness: 1.5),
                    _row2('Presiding', program.presiding, 'Conducting',
                        program.conducting),
                    _divider(),
                    _lv('Opening Prayer', program.openingPrayer),
                    if (program.handbookSpiritual.isNotEmpty)
                      _lv('Handbook Thought',
                          program.handbookSpiritual),
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
                    if (program.callingsAndReleases.isNotEmpty)
                      _lv('Callings & Releases',
                          program.callingsAndReleases),
                    _lv('Closing Prayer', program.closingPrayer),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
              child:
                  Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: Colors.grey, height: 1),
      );
}
