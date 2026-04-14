// screens/admin/handbook_admin_screen.dart
// CRUD management screen for General Handbook reading list.

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/handbook_reading.dart';

class HandbookAdminScreen extends StatefulWidget {
  const HandbookAdminScreen({super.key});

  @override
  State<HandbookAdminScreen> createState() => _HandbookAdminScreenState();
}

class _HandbookAdminScreenState extends State<HandbookAdminScreen> {
  final _db = DatabaseHelper();
  List<HandbookReading> _readings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final readings = await _db.getHandbookReadings();
    setState(() {
      _readings = readings;
      _loading = false;
    });
  }

  Future<void> _showDialog({HandbookReading? reading}) async {
    final titleCtrl = TextEditingController(text: reading?.title ?? '');
    final refCtrl =
        TextEditingController(text: reading?.reference ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(reading == null
            ? 'Add Handbook Reading'
            : 'Edit Handbook Reading'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: refCtrl,
                decoration: const InputDecoration(
                    labelText: 'Reference (e.g. Section 2.1)'),
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
      final r = HandbookReading(
        id: reading?.id,
        title: titleCtrl.text.trim(),
        reference: refCtrl.text.trim(),
      );
      if (reading == null) {
        await _db.insertHandbookReading(r);
      } else {
        await _db.updateHandbookReading(r);
      }
      await _load();
    }
  }

  Future<void> _delete(HandbookReading r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reading'),
        content: Text('Delete "${r.title}"?'),
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
      await _db.deleteHandbookReading(r.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handbook Readings'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _readings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book, size: 64, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No readings yet'),
                      TextButton(
                          onPressed: () => _showDialog(),
                          child: const Text('Add first reading')),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  itemCount: _readings.length,
                  onReorder: (oldIndex, newIndex) {
                    // Simple reorder without persisting display order
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _readings.removeAt(oldIndex);
                      _readings.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (ctx, i) {
                    final r = _readings[i];
                    return ListTile(
                      key: ValueKey(r.id ?? i),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF6A1B9A),
                        foregroundColor: Colors.white,
                        child: Text('${i + 1}'),
                      ),
                      title: Text(r.title),
                      subtitle: Text(r.reference.isNotEmpty
                          ? r.reference
                          : 'No reference'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showDialog(reading: r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(r),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
