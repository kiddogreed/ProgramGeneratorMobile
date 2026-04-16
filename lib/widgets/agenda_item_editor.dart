// widgets/agenda_item_editor.dart
// Widget for managing a dynamic list of agenda items (Bishopric/Ward Council).

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../models/agenda_item.dart';

class AgendaItemEditor extends StatefulWidget {
  final List<AgendaItem> items;
  final ValueChanged<List<AgendaItem>> onChanged;

  const AgendaItemEditor({
    super.key,
    required this.items,
    required this.onChanged,
  });

  @override
  State<AgendaItemEditor> createState() => _AgendaItemEditorState();
}

class _AgendaItemEditorState extends State<AgendaItemEditor> {
  late List<AgendaItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  void _add() {
    setState(() => _items.add(AgendaItem()));
    widget.onChanged(_items);
  }

  void _remove(int index) {
    setState(() => _items.removeAt(index));
    widget.onChanged(_items);
  }

  void _update(int index, AgendaItem updated) {
    setState(() => _items[index] = updated);
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._items.asMap().entries.map((e) => _AgendaItemTile(
              key: ValueKey('agenda_${e.key}'),
              item: e.value,
              index: e.key,
              onChanged: (updated) => _update(e.key, updated),
              onRemove: () => _remove(e.key),
            )),
        TextButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Add Agenda Item'),
        ),
      ],
    );
  }
}

class _AgendaItemTile extends StatefulWidget {
  final AgendaItem item;
  final int index;
  final ValueChanged<AgendaItem> onChanged;
  final VoidCallback onRemove;

  const _AgendaItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_AgendaItemTile> createState() => _AgendaItemTileState();
}

class _AgendaItemTileState extends State<_AgendaItemTile> {
  late final TextEditingController _titleCtrl;
  late List<TextEditingController> _detailCtrl;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListeningTitle = false;
  int? _isListeningDetailIdx;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item.title);
    _detailCtrl = widget.item.details
        .map((d) => TextEditingController(text: d))
        .toList();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return; // _speechReady stays false; mic buttons will be disabled
    }
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() {
              _isListeningTitle = false;
              _isListeningDetailIdx = null;
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListeningTitle = false;
            _isListeningDetailIdx = null;
          });
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _listenAgendaTitle() async {
    if (!_speechReady) return;
    if (_speech.isListening) {
      await _speech.stop();
      setState(() => _isListeningTitle = false);
      return;
    }
    setState(() => _isListeningTitle = true);
    await _speech.listen(
      onResult: (val) {
        if (val.recognizedWords.isNotEmpty) {
          setState(() {
            _titleCtrl.text = val.recognizedWords;
          });
          _notify();
          if (val.finalResult) {
            setState(() => _isListeningTitle = false);
          }
        }
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
    );
  }

  Future<void> _listenAgendaDetail(int idx) async {
    if (!_speechReady) return;
    if (_speech.isListening) {
      await _speech.stop();
      setState(() => _isListeningDetailIdx = null);
      return;
    }
    setState(() => _isListeningDetailIdx = idx);
    await _speech.listen(
      onResult: (val) {
        if (val.recognizedWords.isNotEmpty) {
          setState(() {
            _detailCtrl[idx].text = val.recognizedWords;
          });
          _notify();
          if (val.finalResult) {
            setState(() => _isListeningDetailIdx = null);
          }
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
    _titleCtrl.dispose();
    for (final c in _detailCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() {
    widget.onChanged(AgendaItem(
      title: _titleCtrl.text,
      details: _detailCtrl.map((c) => c.text).toList(),
    ));
  }

  void _addDetail() {
    setState(() => _detailCtrl.add(TextEditingController()));
    _notify();
  }

  void _removeDetail(int index) {
    setState(() {
      _detailCtrl[index].dispose();
      _detailCtrl.removeAt(index);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Item ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_isListeningTitle ? Icons.mic : Icons.mic_none),
                  color: _isListeningTitle ? Colors.red : (_speechReady ? null : Colors.grey),
                  tooltip: !_speechReady
                      ? 'Microphone unavailable'
                      : _isListeningTitle
                          ? 'Tap to stop'
                          : 'Fill title by voice',
                  onPressed: _speechReady ? _listenAgendaTitle : null,
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove item',
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (_) => _notify(),
            ),
            const SizedBox(height: 6),
            ..._detailCtrl.asMap().entries.map((e) => Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: e.value,
                        decoration: InputDecoration(
                          labelText: 'Detail ${e.key + 1}',
                        ),
                        onChanged: (_) => _notify(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isListeningDetailIdx == e.key
                          ? Icons.mic
                          : Icons.mic_none),
                      color: _isListeningDetailIdx == e.key
                          ? Colors.red
                          : (_speechReady ? null : Colors.grey),
                      tooltip: !_speechReady
                          ? 'Microphone unavailable'
                          : _isListeningDetailIdx == e.key
                              ? 'Tap to stop'
                              : 'Fill detail by voice',
                      onPressed: _speechReady ? () => _listenAgendaDetail(e.key) : null,
                      iconSize: 20,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.orange),
                      onPressed: () => _removeDetail(e.key),
                      iconSize: 20,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                  ],
                )),
            TextButton.icon(
              onPressed: _addDetail,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add detail'),
            ),
          ],
        ),
      ),
    );
  }
}
