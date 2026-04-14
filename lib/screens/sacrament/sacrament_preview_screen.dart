// screens/sacrament/sacrament_preview_screen.dart
// Shows a formatted on-screen preview and provides Save / Export / Share.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/sacrament_program.dart';
import '../../utils/pdf_generator.dart';
import '../../utils/docx_generator.dart';
import '../../utils/program_storage.dart';

class SacramentPreviewScreen extends StatelessWidget {
  final SacramentProgram program;

  const SacramentPreviewScreen({super.key, required this.program});

  Future<void> _save(BuildContext context) async {
    await ProgramStorage().saveSacrament(program);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program saved to history')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final bytes = await PdfGenerator.sacrament(program);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _sharePdf(BuildContext context) async {
    final bytes = await PdfGenerator.sacrament(program);
    final dir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyy-MM-dd').format(program.date);
    final file = File('${dir.path}/sacrament_$dateStr.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Sacrament Meeting – ${program.wardName} – $dateStr',
    );
  }

  Future<void> _exportDocx(BuildContext context) async {
    try {
      final bytes = DocxGenerator.generate(program);
      final dir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyy-MM-dd').format(program.date);
      final file = File('${dir.path}/sacrament_$dateStr.docx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document')],
        subject: 'Sacrament Meeting – ${program.wardName} – $dateStr',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DOCX export error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM d, yyyy').format(program.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sacrament Preview'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action bar
            Card(
              color: const Color(0xFFE8F5E9),
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
                          backgroundColor: const Color(0xFF2E7D32),
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
                    OutlinedButton.icon(
                      onPressed: () => _exportDocx(context),
                      icon: const Icon(Icons.description),
                      label: const Text('Export DOCX'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Formatted program preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (program.stakeName.isNotEmpty)
                      Text(program.stakeName,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic)),
                    Text(
                      program.wardName,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32)),
                    ),
                    const Text(
                      'Sacrament Meeting',
                      style: TextStyle(
                          fontSize: 16, color: Color(0xFF2E7D32)),
                    ),
                    Text(dateStr,
                        style: const TextStyle(fontSize: 14)),
                    const Divider(
                        height: 24,
                        color: Color(0xFF2E7D32),
                        thickness: 1.5),

                    _row2('Presiding', program.presiding, 'Conducting',
                        program.conducting),
                    _divider(),
                    _row2('Chorister', program.chorister, 'Pianist',
                        program.pianist),
                    _divider(),
                    _row2('Opening Hymn', program.openingHymn,
                        'Sacrament Hymn', program.sacramentHymn),
                    _labelVal('Closing Hymn', program.closingHymn),
                    _divider(),
                    _labelVal('Invocation', program.invocation),
                    if (program.wardBusiness.isNotEmpty)
                      _labelVal('Ward Business', program.wardBusiness),
                    if (program.stakeBusiness.isNotEmpty)
                      _labelVal('Stake Business', program.stakeBusiness),

                    if (program.speakers.isNotEmpty) ...[
                      const _SectionHeader(
                          'Speakers', Color(0xFF2E7D32)),
                      if (program.speakersAuxiliary.isNotEmpty)
                        _labelVal('Auxiliary', program.speakersAuxiliary),
                      ...program.speakers.map((s) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('${s.name}  –  ${s.title}',
                                      style: const TextStyle(fontSize: 14)),
                                ),
                                if (s.topic.isNotEmpty)
                                  Text('(${s.topic})',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic)),
                              ],
                            ),
                          )),
                    ],
                    _divider(),
                    _labelVal('Benediction', program.benediction),
                    if (program.acknowledgement.isNotEmpty)
                      _labelVal(
                          'Acknowledgement', program.acknowledgement),
                    if (program.announcements.isNotEmpty) ...[
                      const _SectionHeader(
                          'Announcements', Color(0xFF2E7D32)),
                      ...program.announcements
                          .where((a) => a.isNotEmpty)
                          .map((a) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: TextStyle(fontSize: 13)),
                                    Expanded(
                                        child: Text(a,
                                            style: const TextStyle(
                                                fontSize: 13))),
                                  ],
                                ),
                              )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row2(String l1, String v1, String l2, String v2) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: _labelVal(l1, v1)),
            Expanded(child: _labelVal(l2, v2)),
          ],
        ),
      );

  Widget _labelVal(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ),
          Expanded(
              child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: Colors.grey, height: 1),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader(this.title, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(
          title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color),
        ),
      );
}
