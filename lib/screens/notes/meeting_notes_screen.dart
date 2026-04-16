// screens/notes/meeting_notes_screen.dart
// Quick meeting notes pad with offline voice-to-text and text export.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MeetingNotesScreen extends StatefulWidget {
  const MeetingNotesScreen({super.key});

  @override
  State<MeetingNotesScreen> createState() => _MeetingNotesScreenState();
}

class _MeetingNotesScreenState extends State<MeetingNotesScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;

  static const _accent = Color(0xFF1B4F8A);

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;
    _speechReady = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleListen() async {
    if (!_speechReady) return;
    if (_speech.isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    // Track text length before listening so partial results don't double-append
    final baseText = _notesCtrl.text;
    await _speech.listen(
      onResult: (val) {
        if (!mounted) return;
        if (val.recognizedWords.isNotEmpty) {
          final separator = baseText.isNotEmpty &&
                  !baseText.endsWith('\n') &&
                  !baseText.endsWith(' ')
              ? ' '
              : '';
          setState(() {
            _notesCtrl.text = baseText + separator + val.recognizedWords;
            _notesCtrl.selection = TextSelection.fromPosition(
              TextPosition(offset: _notesCtrl.text.length),
            );
          });
          if (val.finalResult) setState(() => _isListening = false);
        }
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 4),
      cancelOnError: true,
    );
  }

  Future<void> _export() async {
    final title =
        _titleCtrl.text.trim().isEmpty ? 'Meeting Notes' : _titleCtrl.text.trim();
    final body = _notesCtrl.text.trim();
    if (body.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No notes to export')),
        );
      }
      return;
    }
    final underline = '=' * title.length;
    final content = '$title\n$underline\n\n$body';
    final dir = await getTemporaryDirectory();
    final safe = title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final file = File('${dir.path}/${safe.isEmpty ? 'notes' : safe}.txt');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/plain')],
      subject: title,
    );
  }

  void _clear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear notes?'),
        content: const Text('This will erase the title and all notes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _titleCtrl.clear();
                _notesCtrl.clear();
              });
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Notes'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all',
            onPressed: _clear,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export as text',
            onPressed: _export,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Bishopric Meeting – April 16',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_isListening)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.mic, color: Colors.red, size: 16),
                    SizedBox(width: 6),
                    Text('Listening… speak now',
                        style: TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                ),
              ),
            if (_isListening) const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speechReady ? _toggleListen : null,
        backgroundColor: _isListening
            ? Colors.red
            : (_speechReady ? _accent : Colors.grey),
        tooltip: !_speechReady
            ? 'Microphone unavailable'
            : _isListening
                ? 'Tap to stop recording'
                : 'Tap to speak',
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
