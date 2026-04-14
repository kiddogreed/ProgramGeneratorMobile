// screens/admin/seed_defaults_screen.dart
// One-tap setup screen to pre-populate the DB with the ward's default members.
// Accessible from the home screen → "Default Data Setup".

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/conductor.dart';
import '../../models/musician.dart';
import '../../models/auxiliary.dart';
import '../../utils/rotation_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Default ward data — edit these lists to match your ward's membership.
// ─────────────────────────────────────────────────────────────────────────────

const _sacramentConductors = [
  'Bishop Sherwin Tan',
  '(1st Co) Bro. John Moroni Mendoza',
  '(2nd Co) Bro. Jonathan Ordillas',
];

const _bishopric = [
  '(Bishop) Sherwin Tan',
  '(1st Co) Bro. John Moroni Mendoza',
  '(2nd Co) Bro. Jonathan Ordillas',
  '(Wrd Clrk) Bro. Adrian Matro',
  '(Asst Clrk rec) Bro. Johanne Perlas',
  '(Asst Clrk fin) Doc. Norman Oliva',
  '(Wrd Exc Secr) Bro. John Russelle Domingo',
  '(Wrd Exc Asst. Secr) Bro. Genesis Ferareza',
];

const _choristers = [
  'Sis. Kyle Domingo',
  'Sis. Alyssa Alo',
];

const _pianists = [
  'Bro. Oscar Driz',
];

const _auxiliaries = [
  'Bishopric',
  'Elders Quorum',
  'Relief Society',
  'Youth',
  'Primary',
  'Sunday School',
  'Ward Mission & Family History',
  'Stake leaders',
];

// ─────────────────────────────────────────────────────────────────────────────

class SeedDefaultsScreen extends StatefulWidget {
  const SeedDefaultsScreen({super.key});

  @override
  State<SeedDefaultsScreen> createState() => _SeedDefaultsScreenState();
}

class _SeedDefaultsScreenState extends State<SeedDefaultsScreen> {
  final _db = DatabaseHelper();

  bool _loading = false;

  // Counts currently in DB for each category
  int _sacCount = 0;
  int _bpCount = 0;
  int _choristerCount = 0;
  int _pianistCount = 0;
  int _auxCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _loading = true);
    final raw = await _db.database;
    final sac = await raw.rawQuery(
        "SELECT COUNT(*) as c FROM conductors WHERE program_type='sacrament'");
    final bp = await raw.rawQuery(
        "SELECT COUNT(*) as c FROM conductors WHERE program_type='bishopric'");
    final cho = await raw.rawQuery(
        "SELECT COUNT(*) as c FROM musicians WHERE musician_type='chorister'");
    final pia = await raw.rawQuery(
        "SELECT COUNT(*) as c FROM musicians WHERE musician_type='pianist'");
    final aux = await raw.rawQuery('SELECT COUNT(*) as c FROM auxiliaries');
    setState(() {
      _sacCount = (sac.first['c'] as int?) ?? 0;
      _bpCount = (bp.first['c'] as int?) ?? 0;
      _choristerCount = (cho.first['c'] as int?) ?? 0;
      _pianistCount = (pia.first['c'] as int?) ?? 0;
      _auxCount = (aux.first['c'] as int?) ?? 0;
      _loading = false;
    });
  }

  Future<void> _seed({required bool replace}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(replace ? 'Replace All Data?' : 'Add Missing Data?'),
        content: Text(replace
            ? 'This will DELETE all existing conductors, musicians, and auxiliaries then reload the defaults. This cannot be undone.'
            : 'This will add default entries only to categories that are currently empty. Existing data is kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: replace
                  ? FilledButton.styleFrom(backgroundColor: Colors.red)
                  : null,
              child: Text(replace ? 'Yes, Replace' : 'Confirm')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final raw = await _db.database;

      if (replace) {
        await raw.delete('conductors');
        await raw.delete('musicians');
        await raw.delete('auxiliaries');
      }

      // Sacrament conductors
      if (replace || _sacCount == 0) {
        for (int i = 0; i < _sacramentConductors.length; i++) {
          await _db.insertConductor(Conductor(
            name: _sacramentConductors[i],
            displayOrder: i,
            programType: 'sacrament',
          ));
        }
      }

      // Bishopric conductors
      if (replace || _bpCount == 0) {
        for (int i = 0; i < _bishopric.length; i++) {
          await _db.insertConductor(Conductor(
            name: _bishopric[i],
            displayOrder: i,
            programType: 'bishopric',
          ));
        }
      }

      // Choristers
      if (replace || _choristerCount == 0) {
        for (int i = 0; i < _choristers.length; i++) {
          await _db.insertMusician(Musician(
            name: _choristers[i],
            musicianType: 'chorister',
            displayOrder: i,
          ));
        }
      }

      // Pianists
      if (replace || _pianistCount == 0) {
        for (int i = 0; i < _pianists.length; i++) {
          await _db.insertMusician(Musician(
            name: _pianists[i],
            musicianType: 'pianist',
            displayOrder: i,
          ));
        }
      }

      // Auxiliaries
      if (replace || _auxCount == 0) {
        for (final name in _auxiliaries) {
          await _db.insertAuxiliary(Auxiliary(name: name));
        }
      }

      await _loadCounts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(replace
                ? 'All default data loaded!'
                : 'Missing defaults added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding data: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Default Data Setup'),
        backgroundColor: const Color(0xFF1B4F8A),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info banner
                Card(
                  color: const Color(0xFFE3F2FD),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF1B4F8A)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pre-load your ward\'s default members into each category. '
                            'You can always edit these later via the Management screens.',
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _SeedSection(
                  title: 'Sacrament Conductors',
                  icon: Icons.menu_book,
                  color: const Color(0xFF2C5282),
                  currentCount: _sacCount,
                  entries: _sacramentConductors,
                ),
                const SizedBox(height: 12),

                _SeedSection(
                  title: 'Bishopric Members',
                  icon: Icons.business_center,
                  color: const Color(0xFFC62828),
                  currentCount: _bpCount,
                  entries: _bishopric,
                ),
                const SizedBox(height: 12),

                _SeedSection(
                  title: 'Choristers',
                  icon: Icons.music_note,
                  color: const Color(0xFF00695C),
                  currentCount: _choristerCount,
                  entries: _choristers,
                ),
                const SizedBox(height: 12),

                _SeedSection(
                  title: 'Pianists',
                  icon: Icons.piano,
                  color: const Color(0xFF00695C),
                  currentCount: _pianistCount,
                  entries: _pianists,
                ),
                const SizedBox(height: 12),

                _SeedSection(
                  title: 'Auxiliaries',
                  icon: Icons.groups,
                  color: const Color(0xFF6A1B9A),
                  currentCount: _auxCount,
                  entries: _auxiliaries,
                ),
                const SizedBox(height: 12),

                const _SpeakerCyclePreview(),
                const SizedBox(height: 28),

                // Action buttons
                FilledButton.icon(
                  onPressed: _loading ? null : () => _seed(replace: false),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Missing Only'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4F8A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _seed(replace: true),
                  icon: const Icon(Icons.refresh, color: Colors.red),
                  label: const Text('Replace All with Defaults',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"Add Missing Only" skips categories that already have data.\n'
                  '"Replace All" clears all conductors, musicians & auxiliaries first.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widget: expandable section card
// ─────────────────────────────────────────────────────────────────────────────

class _SeedSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int currentCount;
  final List<String> entries;

  const _SeedSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.currentCount,
    required this.entries,
  });

  @override
  State<_SeedSection> createState() => _SeedSectionState();
}

class _SeedSectionState extends State<_SeedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasData = widget.currentCount > 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.color.withAlpha(30),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            title: Text(widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              hasData
                  ? '${widget.currentCount} already in database'
                  : 'Empty — will be seeded',
              style: TextStyle(
                color: hasData ? Colors.orange[700] : Colors.green[700],
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.entries.length} defaults',
                    style: TextStyle(
                        fontSize: 11,
                        color: widget.color,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  const Divider(height: 1),
                  ...widget.entries.asMap().entries.map((e) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: widget.color.withAlpha(20),
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(
                                fontSize: 10,
                                color: widget.color,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(e.value,
                            style: const TextStyle(fontSize: 13)),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Speaker cycle preview — shows the next 8 Sundays' assignments
// ─────────────────────────────────────────────────────────────────────────────

class _SpeakerCyclePreview extends StatefulWidget {
  const _SpeakerCyclePreview();

  @override
  State<_SpeakerCyclePreview> createState() => _SpeakerCyclePreviewState();
}

class _SpeakerCyclePreviewState extends State<_SpeakerCyclePreview> {
  bool _expanded = false;
  List<_CycleRow> _rows = [];

  static const _color = Color(0xFF2C5282);
  static final _dateFmt = DateFormat('EEE, MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _buildRows();
  }

  Future<void> _buildRows() async {
    final db = DatabaseHelper();
    final cfg = await db.getWardConfig();

    // Find next Sunday on or after today
    final today = DateTime.now();
    final daysToSunday =
        today.weekday == DateTime.sunday ? 0 : DateTime.sunday - today.weekday;
    var sunday = DateTime(today.year, today.month, today.day + daysToSunday);

    final rows = <_CycleRow>[];
    for (int i = 0; i < 8; i++) {
      final occ = RotationService.getSundayOccurrence(sunday);
      final label = RotationService.getSpeakerTypeLabel(sunday, cfg);
      final auxName = RotationService.speakerLabelToAuxiliary(label);
      rows.add(_CycleRow(
        date: sunday,
        occurrence: _ordinal(occ),
        label: label,
        auxiliary: auxName,
      ));
      sunday = sunday.add(const Duration(days: 7));
    }

    if (mounted) setState(() => _rows = rows);
  }

  static String _ordinal(int n) {
    const suffixes = ['th', 'st', 'nd', 'rd'];
    final mod = n % 100;
    final suffix =
        (mod >= 11 && mod <= 13) ? 'th' : suffixes[n % 10 < 4 ? n % 10 : 0];
    return '$n$suffix Sunday';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _color.withAlpha(30),
              child:
                  const Icon(Icons.calendar_month, color: _color, size: 22),
            ),
            title: const Text('Speaker Cycle Preview',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Upcoming 8 Sundays — auto-fills Sacrament form',
              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Dynamic',
                    style: TextStyle(
                        fontSize: 11,
                        color: _color,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  const Divider(height: 1),
                  // Header row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text('Date',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700]))),
                        Expanded(
                            flex: 2,
                            child: Text('Occurrence',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700]))),
                        Expanded(
                            flex: 3,
                            child: Text('Assignment',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700]))),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ..._rows.map((row) => Container(
                        decoration: BoxDecoration(
                          color: row.auxiliary == null
                              ? Colors.orange[50]
                              : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  _dateFmt.format(row.date),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  row.occurrence,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600]),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  row.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: row.auxiliary == null
                                        ? Colors.orange[800]
                                        : _color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      '* Orange rows (Fast & Testimony) have no auxiliary auto-assigned.\n'
                      'Change "Speaker Cycle Base Month" in Automation Rules to shift the cycle.',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CycleRow {
  final DateTime date;
  final String occurrence;
  final String label;
  final String? auxiliary;
  const _CycleRow({
    required this.date,
    required this.occurrence,
    required this.label,
    required this.auxiliary,
  });
}
