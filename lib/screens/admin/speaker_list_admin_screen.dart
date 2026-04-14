// screens/admin/speaker_list_admin_screen.dart
// CRUD management screen for the rotating speaker list used in Sacrament.

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/speaker_entry.dart';

class SpeakerListAdminScreen extends StatefulWidget {
  const SpeakerListAdminScreen({super.key});

  @override
  State<SpeakerListAdminScreen> createState() =>
      _SpeakerListAdminScreenState();
}

class _SpeakerListAdminScreenState extends State<SpeakerListAdminScreen> {
  final _db = DatabaseHelper();
  List<SpeakerEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _db.getSpeakerEntries();
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _showDialog({SpeakerEntry? entry}) async {
    final nameCtrl = TextEditingController(text: entry?.name ?? '');
    final orgCtrl =
        TextEditingController(text: entry?.organization ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(entry == null ? 'Add Speaker' : 'Edit Speaker'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: orgCtrl,
                decoration: const InputDecoration(
                    labelText: 'Organization / Calling',
                    hintText: 'e.g. Elders Quorum, Primary'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final e = SpeakerEntry(
        id: entry?.id,
        name: nameCtrl.text.trim(),
        organization: orgCtrl.text.trim(),
        displayOrder: entry?.displayOrder ?? _entries.length,
      );
      if (entry == null) {
        await _db.insertSpeakerEntry(e);
      } else {
        await _db.updateSpeakerEntry(e);
      }
      await _load();
    }
  }

  Future<void> _delete(SpeakerEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Speaker'),
        content: Text('Remove "${e.name}" from the rotation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteSpeakerEntry(e.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaker Rotation List'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_entries.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      '${_entries.length} speaker(s) in rotation — '
                      'drag to reorder',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF2E7D32)),
                    ),
                  ),
                Expanded(
                  child: _entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_search,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('No speakers in rotation'),
                              TextButton(
                                  onPressed: () => _showDialog(),
                                  child: const Text('Add first speaker')),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          itemCount: _entries.length,
                          onReorder: (oldIndex, newIndex) async {
                            setState(() {
                              if (newIndex > oldIndex) newIndex--;
                              final item = _entries.removeAt(oldIndex);
                              _entries.insert(newIndex, item);
                            });
                            // Persist new order
                            for (int i = 0; i < _entries.length; i++) {
                              final updated = SpeakerEntry(
                                id: _entries[i].id,
                                name: _entries[i].name,
                                organization: _entries[i].organization,
                                displayOrder: i,
                              );
                              await _db.updateSpeakerEntry(updated);
                            }
                          },
                          itemBuilder: (ctx, i) {
                            final e = _entries[i];
                            return ListTile(
                              key: ValueKey(e.id ?? i),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                child: Text('${i + 1}'),
                              ),
                              title: Text(e.name),
                              subtitle: Text(e.organization.isNotEmpty
                                  ? e.organization
                                  : 'No organization'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _showDialog(entry: e),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _delete(e),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// Helper extension for InputDecoration hint
extension on String {
  String get hint => this;
}
