// widgets/agenda_item_editor.dart
// Widget for managing a dynamic list of agenda items (Bishopric/Ward Council).

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item.title);
    _detailCtrl = widget.item.details
        .map((d) => TextEditingController(text: d))
        .toList();
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
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove item',
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
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.orange),
                      onPressed: () => _removeDetail(e.key),
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
