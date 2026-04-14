// screens/sacrament/sacrament_preview_screen.dart
// Shows a formatted on-screen preview and provides Save / Export / Share.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

  Future<void> _saveToDownloads(BuildContext context) async {
    try {
      // Request permission on Android
      if (Platform.isAndroid) {
        PermissionStatus status;
        // API 30+ requires MANAGE_EXTERNAL_STORAGE
        final manageStatus = await Permission.manageExternalStorage.status;
        if (manageStatus.isGranted) {
          status = manageStatus;
        } else {
          // Try legacy storage first (API < 30)
          final legacy = await Permission.storage.request();
          if (legacy.isGranted) {
            status = legacy;
          } else {
            status = await Permission.manageExternalStorage.request();
          }
        }
        if (!status.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Storage permission needed to save to Downloads'),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: openAppSettings,
                ),
              ),
            );
          }
          return;
        }
      }

      final bytes = await PdfGenerator.sacrament(program);
      final dateStr = DateFormat('yyyy-MM-dd').format(program.date);
      final fileName = 'sacrament_${program.wardName.replaceAll(' ', '_')}_$dateStr.pdf';

      late File file;
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);
        file = File('${downloadsDir.path}/$fileName');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        file = File('${dir.path}/$fileName');
      }

      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $fileName'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
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
                      onPressed: () => _saveToDownloads(context),
                      icon: const Icon(Icons.download),
                      label: const Text('Save to Downloads'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white),
                    ),
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
                    const Divider(
                        height: 24,
                        color: Color(0xFF2E7D32),
                        thickness: 1.5),

                    _labelVal('Date', dateStr),
                    _labelVal('Presiding', program.presiding),
                    _labelVal('Conducting', program.conducting),
                    if (program.acknowledgement.isNotEmpty)
                      _labelVal('Acknowledgement', program.acknowledgement),
                    if (program.announcements
                        .where((a) => a.isNotEmpty)
                        .isNotEmpty) ...[
                      const _SectionHeader(
                          'Announcements', Color(0xFF2E7D32)),
                      ...program.announcements
                          .where((a) => a.isNotEmpty)
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text('${e.key + 1}. ${e.value}',
                                    style: const TextStyle(fontSize: 13)),
                              )),
                    ],
                    _divider(),
                    if (program.chorister.isNotEmpty ||
                        program.pianist.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(
                            'Chorister: ${program.chorister}   |   Pianist: ${program.pianist}',
                            style: const TextStyle(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    _labelVal('Opening Hymn', program.openingHymn),
                    _labelVal('Invocation', program.invocation),
                    if (program.wardBusiness.isNotEmpty)
                      _labelVal('Ward Business', program.wardBusiness),
                    if (program.stakeBusiness.isNotEmpty)
                      _labelVal('Stake Business', program.stakeBusiness),
                    _labelVal('Sacrament Hymn', program.sacramentHymn),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Thank you for your reverence during the sacrament, and thank you to the priesthood brethren who bless and passed the bread and water. You may now join your family.',
                        style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600]),
                      ),
                    ),
                    if (program.speakers.isNotEmpty) ...[
                      const _SectionHeader(
                          'Speakers', Color(0xFF2E7D32)),
                      ...program.speakers.asMap().entries.map((e) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              '${_ordinal(e.key + 1)} speaker: ${e.value.name}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          )),
                    ],
                    _labelVal('Closing Hymn', program.closingHymn),
                    _labelVal('Benediction', program.benediction),
                    _divider(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Sacrament Attendance: ________',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
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

  static String _ordinal(int n) {
    const suffixes = ['th', 'st', 'nd', 'rd'];
    final mod = n % 100;
    return '$n${(mod >= 11 && mod <= 13) ? 'th' : suffixes[n % 10 < 4 ? n % 10 : 0]}';
  }
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
