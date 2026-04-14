// widgets/speaker_list_editor.dart
// Widget that manages a dynamic list of speakers in the Sacrament form.

import 'package:flutter/material.dart';
import '../models/speaker.dart';

class SpeakerListEditor extends StatefulWidget {
  final List<Speaker> speakers;
  final ValueChanged<List<Speaker>> onChanged;

  const SpeakerListEditor({
    super.key,
    required this.speakers,
    required this.onChanged,
  });

  @override
  State<SpeakerListEditor> createState() => _SpeakerListEditorState();
}

class _SpeakerListEditorState extends State<SpeakerListEditor> {
  late List<Speaker> _speakers;

  @override
  void initState() {
    super.initState();
    _speakers = List.from(widget.speakers);
  }

  void _add() {
    setState(() {
      _speakers.add(Speaker(order: _speakers.length + 1));
    });
    widget.onChanged(_speakers);
  }

  void _remove(int index) {
    setState(() {
      _speakers.removeAt(index);
      // Re-number remaining speakers
      for (var i = 0; i < _speakers.length; i++) {
        _speakers[i] = _speakers[i].copyWith(order: i + 1);
      }
    });
    widget.onChanged(_speakers);
  }

  void _update(int index, Speaker updated) {
    setState(() {
      _speakers[index] = updated;
    });
    widget.onChanged(_speakers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._speakers.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return _SpeakerTile(
            key: ValueKey('speaker_$i'),
            speaker: s,
            index: i,
            onChanged: (updated) => _update(i, updated),
            onRemove: () => _remove(i),
          );
        }),
        TextButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Add Speaker'),
        ),
      ],
    );
  }
}

class _SpeakerTile extends StatefulWidget {
  final Speaker speaker;
  final int index;
  final ValueChanged<Speaker> onChanged;
  final VoidCallback onRemove;

  const _SpeakerTile({
    super.key,
    required this.speaker,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_SpeakerTile> createState() => _SpeakerTileState();
}

class _SpeakerTileState extends State<_SpeakerTile> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _topicCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.speaker.name);
    _titleCtrl = TextEditingController(text: widget.speaker.title);
    _topicCtrl = TextEditingController(text: widget.speaker.topic);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(widget.speaker.copyWith(
      name: _nameCtrl.text,
      title: _titleCtrl.text,
      topic: _topicCtrl.text,
    ));
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
                  'Speaker ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove speaker',
                ),
              ],
            ),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => _notify(),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title / Calling'),
              onChanged: (_) => _notify(),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _topicCtrl,
              decoration: const InputDecoration(labelText: 'Topic (optional)'),
              onChanged: (_) => _notify(),
            ),
          ],
        ),
      ),
    );
  }
}
