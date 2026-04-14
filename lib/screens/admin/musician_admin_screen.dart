// screens/admin/musician_admin_screen.dart
// CRUD management for Choristers and Pianists. Mirrors AuxiliaryAdminController.

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/musician.dart';

class MusicianAdminScreen extends StatefulWidget {
  const MusicianAdminScreen({super.key});

  @override
  State<MusicianAdminScreen> createState() =>
      _MusicianAdminScreenState();
}

class _MusicianAdminScreenState extends State<MusicianAdminScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  late TabController _tabController;

  List<Musician> _choristers = [];
  List<Musician> _pianists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = await _db.getMusicians(type: 'chorister');
    final p = await _db.getMusicians(type: 'pianist');
    if (mounted) {
      setState(() {
        _choristers = c;
        _pianists = p;
        _loading = false;
      });
    }
  }

  Future<void> _add(String type) async {
    final name = await _showNameDialog(
        'Add ${type == 'chorister' ? 'Chorister' : 'Pianist'}');
    if (name == null || name.trim().isEmpty) return;
    final musicians =
        type == 'chorister' ? _choristers : _pianists;
    await _db.insertMusician(Musician(
      name: name.trim(),
      musicianType: type,
      displayOrder: musicians.length,
    ));
    _load();
  }

  Future<void> _edit(Musician m) async {
    final name = await _showNameDialog('Edit Name', initial: m.name);
    if (name == null || name.trim().isEmpty) return;
    await _db.updateMusician(
        Musician(id: m.id, name: name.trim(), musicianType: m.musicianType,
            displayOrder: m.displayOrder));
    _load();
  }

  Future<void> _delete(Musician m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Remove ${m.name}?'),
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
    if (ok == true && m.id != null) {
      await _db.deleteMusician(m.id!);
      _load();
    }
  }

  Future<String?> _showNameDialog(String title, {String initial = ''}) {
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

  Widget _list(List<Musician> musicians, String type) {
    if (musicians.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text('No ${type == 'chorister' ? 'choristers' : 'pianists'} yet.',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _add(type),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: musicians.length,
      itemBuilder: (_, i) {
        final m = musicians[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  const Color(0xFF00695C).withValues(alpha: 0.12),
              child: const Icon(Icons.person,
                  color: Color(0xFF00695C)),
            ),
            title: Text(m.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(m),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red),
                  onPressed: () => _delete(m),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Musician Management'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Choristers'),
            Tab(text: 'Pianists'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _list(_choristers, 'chorister'),
                _list(_pianists, 'pianist'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(
            _tabController.index == 0 ? 'chorister' : 'pianist'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
