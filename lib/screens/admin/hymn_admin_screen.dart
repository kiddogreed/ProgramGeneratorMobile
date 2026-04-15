// screens/admin/hymn_admin_screen.dart
// CRUD management screen for hymn list used in program dropdowns.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/database_helper.dart';
import '../../models/hymn.dart';

class HymnAdminScreen extends StatefulWidget {
  const HymnAdminScreen({super.key});

  @override
  State<HymnAdminScreen> createState() => _HymnAdminScreenState();
}

class _HymnAdminScreenState extends State<HymnAdminScreen> {
  final _db = DatabaseHelper();
  List<Hymn> _hymns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hymns = await _db.getHymns();
    setState(() {
      _hymns = hymns;
      _loading = false;
    });
  }

  Future<void> _showDialog({Hymn? hymn}) async {
    final numberCtrl = TextEditingController(
        text: hymn?.number.toString() ?? '');
    final titleCtrl = TextEditingController(text: hymn?.title ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hymn == null ? 'Add Hymn' : 'Edit Hymn'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: numberCtrl,
                decoration: const InputDecoration(labelText: 'Hymn Number'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
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
      final h = Hymn(
        id: hymn?.id,
        number: numberCtrl.text.trim(),
        title: titleCtrl.text.trim(),
      );
      if (hymn == null) {
        await _db.insertHymn(h);
      } else {
        await _db.updateHymn(h);
      }
      await _load();
    }
  }

  Future<void> _delete(Hymn h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Hymn'),
        content: Text('Delete "${h.display}"?'),
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
      await _db.deleteHymn(h.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hymns'),
        backgroundColor: const Color(0xFF1B4F8A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1B4F8A),
        foregroundColor: Colors.white,
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hymns.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.music_note,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No hymns yet'),
                      TextButton(
                          onPressed: () => _showDialog(),
                          child: const Text('Add first hymn')),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _hymns.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final h = _hymns[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1B4F8A),
                        foregroundColor: Colors.white,
                        child: Text('#${h.number}',
                            style: const TextStyle(fontSize: 11)),
                      ),
                      title: Text(h.title),
                      subtitle: Text(h.display),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showDialog(hymn: h),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 22,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(h),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 22,
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
