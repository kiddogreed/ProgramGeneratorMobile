// widgets/announcements_editor.dart
// Manages the dynamic list of announcements in the Sacrament form.

import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _controllers = widget.announcements
        .map((a) => TextEditingController(text: a))
        .toList();
    if (_controllers.isEmpty) _controllers.add(TextEditingController());
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
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.orange),
                  onPressed: () => _remove(e.key),
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
