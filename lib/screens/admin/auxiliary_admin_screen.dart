// screens/admin/auxiliary_admin_screen.dart
// CRUD management screen for the Auxiliaries list used in Ward Council
// prayers / handbook rotation and speaker-type assignment.

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/auxiliary.dart';

class AuxiliaryAdminScreen extends StatefulWidget {
  const AuxiliaryAdminScreen({super.key});

  @override
  State<AuxiliaryAdminScreen> createState() => _AuxiliaryAdminScreenState();
}

class _AuxiliaryAdminScreenState extends State<AuxiliaryAdminScreen> {
  static const _color = Color(0xFF00838F); // teal

  final _db = DatabaseHelper();
  List<Auxiliary> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _db.getAuxiliaries();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  // ── Add / Edit dialog ─────────────────────────────────────────────────

  Future<void> _showDialog({Auxiliary? item}) async {
    final ctrl = TextEditingController(text: item?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Add Auxiliary' : 'Edit Auxiliary'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final trimmed = v.trim();
              final duplicate = _items.any((a) =>
                  a.name.toLowerCase() == trimmed.toLowerCase() &&
                  a.id != item?.id);
              if (duplicate) return 'Already exists';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _color,
                foregroundColor: Colors.white),
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

    if (saved == true) {
      final name = ctrl.text.trim();
      if (item == null) {
        await _db.insertAuxiliary(Auxiliary(name: name));
      } else {
        await _db.updateAuxiliary(Auxiliary(id: item.id, name: name));
      }
      await _load();
    }
  }

  // ── Delete with confirm ───────────────────────────────────────────────

  Future<void> _delete(Auxiliary item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Auxiliary'),
        content: Text('Remove "${item.name}"?\n\nThis may affect Ward Council '
            'rotation assignments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteAuxiliary(item.id!);
      await _load();
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auxiliary Management'),
        backgroundColor: _color,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _color,
        foregroundColor: Colors.white,
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_items.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: _color.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      '${_items.length} auxiliary(ies) — tap to edit',
                      style:
                          const TextStyle(fontSize: 12, color: _color),
                    ),
                  ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.groups_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text('No auxiliaries yet.',
                                  style:
                                      TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: _color,
                                    foregroundColor: Colors.white),
                                onPressed: () => _showDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Auxiliary'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final item = _items[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _color.withValues(alpha: 0.12),
                                child: const Icon(Icons.groups,
                                    color: _color),
                              ),
                              title: Text(item.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _delete(item),
                              ),
                              onTap: () => _showDialog(item: item),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
