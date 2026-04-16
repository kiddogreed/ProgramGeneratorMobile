// widgets/announcements_editor.dart
// Manages the dynamic list of announcements in the Sacrament form.
// Includes per-announcement voice input via speech_to_text.

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class AnnouncementsEditor extends StatefulWidget {
  final List<String> announcements;
  final ValueChanged<List<String>> onChanged;

  const AnnouncementsEditor({
    super.key,
    required this.announcements,
    required this.onChanged,
  });

  @override
  State<AnnouncementsEditor> createState() => _AnnouncementsEditorState();
}

class _AnnouncementsEditorState extends State<AnnouncementsEditor> {
  late List<TextEditingController> _controllers;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  int? _listeningIdx;

  @override
  void initState() {
    super.initState();
    _controllers = widget.announcements
        .map((a) => TextEditingController(text: a))
        .toList();
    if (_controllers.isEmpty) _controllers.add(TextEditingController());
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;
    _speechReady = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listeningIdx = null);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listeningIdx = null);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _listen(int idx) async {
    if (!_speechReady) return;
    if (_speech.isListening) {
      await _speech.stop();
      setState(() => _listeningIdx = null);
      return;
    }
    setState(() => _listeningIdx = idx);
    await _speech.listen(
      onResult: (val) {
        if (val.recognizedWords.isNotEmpty) {
          setState(() => _controllers[idx].text = val.recognizedWords);
          _notify();
          if (val.finalResult) setState(() => _listeningIdx = null);
        }
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() {
    widget.onChanged(_controllers.map((c) => c.text).toList());
  }

  void _add() {
    setState(() => _controllers.add(TextEditingController()));
    _notify();
  }

  void _remove(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._controllers.asMap().entries.map((e) => Row(
              key: ValueKey('ann_${e.key}'),
              children: [
                Expanded(
                  child: TextField(
                    controller: e.value,
                    decoration:
                        InputDecoration(labelText: 'Announcement ${e.key + 1}'),
                    maxLines: 2,
                    onChanged: (_) => _notify(),
                  ),
                ),
                IconButton(
                  icon: Icon(_listeningIdx == e.key
                      ? Icons.mic
                      : Icons.mic_none),
                  color: _listeningIdx == e.key
                      ? Colors.red
                      : (_speechReady ? null : Colors.grey),
                  tooltip: !_speechReady
                      ? 'Microphone unavailable'
                      : _listeningIdx == e.key
                          ? 'Tap to stop'
                          : 'Fill by voice',
                  onPressed: _speechReady ? () => _listen(e.key) : null,
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.orange),
                  onPressed: () => _remove(e.key),
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            )),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Add Announcement'),
        ),
      ],
    );
  }
}
