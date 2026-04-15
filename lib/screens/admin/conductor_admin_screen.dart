// screens/admin/conductor_admin_screen.dart
// CRUD management for Conductors, grouped by program type.
// Mirrors ConductorController in the Spring Boot app.

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/conductor.dart';

class ConductorAdminScreen extends StatefulWidget {
  const ConductorAdminScreen({super.key});

  @override
  State<ConductorAdminScreen> createState() =>
      _ConductorAdminScreenState();
}

class _ConductorAdminScreenState extends State<ConductorAdminScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  late TabController _tabController;

  List<Conductor> _sacrament = [];
  List<Conductor> _bishopric = [];
  List<Conductor> _wardCouncil = [];
  bool _loading = true;

  static const _tabs = [
    ('sacrament', 'Sacrament'),
    ('bishopric', 'Bishopric'),
    ('ward_council', 'Ward Council'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await _db.getConductors(programType: 'sacrament');
    final b = await _db.getConductors(programType: 'bishopric');
    final w = await _db.getConductors(programType: 'ward_council');
    if (mounted) {
      setState(() {
        _sacrament = s;
        _bishopric = b;
        _wardCouncil = w;
        _loading = false;
      });
    }
  }

  List<Conductor> _conductorsFor(String type) => switch (type) {
        'bishopric' => _bishopric,
        'ward_council' => _wardCouncil,
        _ => _sacrament,
      };

  Future<void> _add(String type) async {
    final name = await _showDialog('Add Conductor');
    if (name == null || name.trim().isEmpty) return;
    final existing = _conductorsFor(type);
    await _db.insertConductor(Conductor(
      name: name.trim(),
      programType: type,
      displayOrder: existing.length,
    ));
    _load();
  }

  Future<void> _edit(Conductor c) async {
    final name = await _showDialog('Edit Conductor', initial: c.name);
    if (name == null || name.trim().isEmpty) return;
    await _db.updateConductor(Conductor(
      id: c.id,
      name: name.trim(),
      programType: c.programType,
      displayOrder: c.displayOrder,
    ));
    _load();
  }

  Future<void> _delete(Conductor c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Conductor'),
        content: Text('Remove ${c.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && c.id != null) {
      await _db.deleteConductor(c.id!);
      _load();
    }
  }

  Future<String?> _showDialog(String title, {String initial = ''}) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Save')),
        ],
      ),
    );
  }

  Widget _list(List<Conductor> conductors, String type) {
    if (conductors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add_disabled,
                size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('No conductors yet.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _add(type),
              icon: const Icon(Icons.add),
              label: const Text('Add Conductor'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: conductors.length,
      itemBuilder: (_, i) {
        final c = conductors[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  const Color(0xFF4527A0).withValues(alpha: 0.12),
              child: const Icon(Icons.person,
                  color: Color(0xFF4527A0)),
            ),
            title: Text(c.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(c),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 22,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red),
                  onPressed: () => _delete(c),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final types = _tabs.map((t) => t.$1).toList();
    final labels = _tabs.map((t) => t.$2).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conductor Management'),
        backgroundColor: const Color(0xFF4527A0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: types
                  .map((t) =>
                      _list(_conductorsFor(t), t))
                  .toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(
            types[_tabController.index]),
        backgroundColor: const Color(0xFF4527A0),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
