// screens/history/history_screen.dart
// Shows all saved programs with filter by type, load into edit screen, or delete.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/saved_program.dart';
import '../../utils/program_storage.dart';
import '../sacrament/sacrament_form_screen.dart';
import '../bishopric/bishopric_form_screen.dart';
import '../ward_council/ward_council_form_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = ProgramStorage();
  List<SavedProgram> _all = [];
  List<SavedProgram> _filtered = [];
  String _filter = 'ALL';
  bool _loading = true;

  static const _typeLabels = {
    'ALL': 'All',
    'SACRAMENT': 'Sacrament',
    'BISHOPRIC': 'Bishopric',
    'WARD_COUNCIL': 'Ward Council',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _storage.loadAll();
    if (mounted) {
      setState(() {
        _all = all;
        _applyFilter();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    _filtered = _filter == 'ALL'
        ? List.from(_all)
        : _all.where((p) => p.meetingType == _filter).toList();
  }

  Future<void> _delete(SavedProgram sp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text('Delete "${sp.description}"?'),
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
    if (confirmed == true && sp.id != null) {
      await _storage.delete(sp.id!);
      _load();
    }
  }

  void _loadProgram(SavedProgram sp) {
    if (!mounted) return;
    switch (sp.meetingType) {
      case 'SACRAMENT':
        final prog = _storage.decodeSacrament(sp.programData);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SacramentFormScreen(initial: prog)),
        );
        break;
      case 'BISHOPRIC':
        final prog = _storage.decodeBishopric(sp.programData);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BishopricFormScreen(initial: prog)),
        );
        break;
      case 'WARD_COUNCIL':
        final prog = _storage.decodeWardCouncil(sp.programData);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => WardCouncilFormScreen(initial: prog)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program History'),
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _typeLabels.entries.map((e) {
                        final active = _filter == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(e.value),
                            selected: active,
                            onSelected: (_) {
                              setState(() {
                                _filter = e.key;
                                _applyFilter();
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No saved programs yet.\nCreate and save a program to see it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final sp = _filtered[i];
                            return _ProgramHistoryCard(
                              program: sp,
                              onLoad: () => _loadProgram(sp),
                              onDelete: () => _delete(sp),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _ProgramHistoryCard extends StatelessWidget {
  final SavedProgram program;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _ProgramHistoryCard({
    required this.program,
    required this.onLoad,
    required this.onDelete,
  });

  static const _typeColors = {
    'SACRAMENT': Color(0xFF2E7D32),
    'BISHOPRIC': Color(0xFFC62828),
    'WARD_COUNCIL': Color(0xFF6A1B9A),
  };

  static const _typeIcons = {
    'SACRAMENT': Icons.menu_book,
    'BISHOPRIC': Icons.business_center,
    'WARD_COUNCIL': Icons.groups,
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[program.meetingType] ?? Colors.grey;
    final icon = _typeIcons[program.meetingType] ?? Icons.description;
    final saved =
        DateFormat('MMM d, yyyy  h:mm a').format(program.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color)),
        title: Text(program.description,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Saved: $saved',
            style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Edit / Load',
              onPressed: onLoad,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
