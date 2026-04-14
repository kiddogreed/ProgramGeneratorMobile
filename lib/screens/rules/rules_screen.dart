// screens/rules/rules_screen.dart
// Configuration screen for automation rules and ward settings.
// All fields aligned to the new WardConfig model (FLUTTER_APP_REFERENCE.md).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/database_helper.dart';
import '../../widgets/labeled_field.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  final _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  // Ward identity
  late TextEditingController _wardNameCtrl;
  late TextEditingController _stakeNameCtrl;
  late TextEditingController _acknowledgementCtrl;

  // Bishop
  late TextEditingController _bishopNameCtrl;

  // Sacrament
  late TextEditingController _sacramentTimeCtrl;

  // Bishopric
  String _bishopricPreferredDay = 'Thursday';
  late TextEditingController _bishopricThursdayTimeCtrl;
  late TextEditingController _bishopricSundayTimeCtrl;

  // Ward Council — comma-separated occurrence numbers (1..5)
  late TextEditingController _wardCouncilOccurrencesCtrl;
  late TextEditingController _wardCouncilTimeCtrl;

  // Speaker Cycle base month
  late TextEditingController _speakerCycleBaseMonthCtrl;

  // Speaker Cycle slot assignments (2nd / 4th Sunday cycles)
  String _cycle2Slot1 = 'Relief Society';
  String _cycle2Slot2 = 'Elders Quorum';
  String _cycle2Slot3 = 'Ward Mission & Family History';
  String _cycle4Slot1 = 'Sunday School';
  String _cycle4Slot2 = 'Primary';
  String _cycle4Slot3 = 'Youth';

  // Available auxiliaries for cycle dropdowns
  List<String> _auxiliaryNames = [];

  @override
  void initState() {
    super.initState();
    _wardNameCtrl = TextEditingController();
    _stakeNameCtrl = TextEditingController();
    _acknowledgementCtrl = TextEditingController();
    _bishopNameCtrl = TextEditingController();
    _sacramentTimeCtrl = TextEditingController();
    _bishopricThursdayTimeCtrl = TextEditingController();
    _bishopricSundayTimeCtrl = TextEditingController();
    _wardCouncilOccurrencesCtrl = TextEditingController();
    _wardCouncilTimeCtrl = TextEditingController();
    _speakerCycleBaseMonthCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _wardNameCtrl,
      _stakeNameCtrl,
      _acknowledgementCtrl,
      _bishopNameCtrl,
      _sacramentTimeCtrl,
      _bishopricThursdayTimeCtrl,
      _bishopricSundayTimeCtrl,
      _wardCouncilOccurrencesCtrl,
      _wardCouncilTimeCtrl,
      _speakerCycleBaseMonthCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final cfg = await _db.getWardConfig();
    final auxList = await _db.getAuxiliaries();
    setState(() {
      _wardNameCtrl.text = cfg.wardName;
      _stakeNameCtrl.text = cfg.stakeName;
      _acknowledgementCtrl.text = cfg.acknowledgementTemplate;
      _bishopNameCtrl.text = cfg.bishopName;
      _sacramentTimeCtrl.text = cfg.sacramentTime;
      _bishopricPreferredDay = cfg.bishopricPreferredDay;
      _bishopricThursdayTimeCtrl.text = cfg.bishopricThursdayTime;
      _bishopricSundayTimeCtrl.text = cfg.bishopricSundayTime;
      _wardCouncilOccurrencesCtrl.text = cfg.wardCouncilOccurrences;
      _wardCouncilTimeCtrl.text = cfg.wardCouncilTime;
      _speakerCycleBaseMonthCtrl.text = cfg.speakerCycleBaseMonth;
      _cycle2Slot1 = cfg.cycle2Slot1;
      _cycle2Slot2 = cfg.cycle2Slot2;
      _cycle2Slot3 = cfg.cycle2Slot3;
      _cycle4Slot1 = cfg.cycle4Slot1;
      _cycle4Slot2 = cfg.cycle4Slot2;
      _cycle4Slot3 = cfg.cycle4Slot3;
      _auxiliaryNames = auxList.map((a) => a.name).toList();
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final existing = await _db.getWardConfig();
      await _db.saveWardConfig(existing.copyWith(
        wardName: _wardNameCtrl.text.trim(),
        stakeName: _stakeNameCtrl.text.trim(),
        acknowledgementTemplate: _acknowledgementCtrl.text.trim(),
        bishopName: _bishopNameCtrl.text.trim(),
        sacramentTime: _sacramentTimeCtrl.text.trim(),
        bishopricPreferredDay: _bishopricPreferredDay,
        bishopricThursdayTime: _bishopricThursdayTimeCtrl.text.trim(),
        bishopricSundayTime: _bishopricSundayTimeCtrl.text.trim(),
        wardCouncilOccurrences: _wardCouncilOccurrencesCtrl.text.trim(),
        wardCouncilTime: _wardCouncilTimeCtrl.text.trim(),
        speakerCycleBaseMonth: _speakerCycleBaseMonthCtrl.text.trim(),
        cycle2Slot1: _cycle2Slot1,
        cycle2Slot2: _cycle2Slot2,
        cycle2Slot3: _cycle2Slot3,
        cycle4Slot1: _cycle4Slot1,
        cycle4Slot2: _cycle4Slot2,
        cycle4Slot3: _cycle4Slot3,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation Rules'),
        backgroundColor: const Color(0xFF1B4F8A),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Save',
                style: TextStyle(color: Colors.white)),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Ward Identity ──────────────────────────────
                  _sectionCard(
                    title: 'Ward Identity',
                    color: const Color(0xFF1B4F8A),
                    icon: Icons.church,
                    children: [
                      LabeledField(
                        label: 'Ward Name *',
                        controller: _wardNameCtrl,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      LabeledField(
                        label: 'Stake Name',
                        controller: _stakeNameCtrl,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Bishop Rule ────────────────────────────────
                  _sectionCard(
                    title: 'Bishop',
                    color: const Color(0xFF1B5E20),
                    icon: Icons.person,
                    children: [
                      LabeledField(
                        label: 'Bishop Name',
                        controller: _bishopNameCtrl,
                        hint: 'e.g. Bishop Sherwin Tan',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Used to auto-fill Presiding in Sacrament & Bishopric programs.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Sacrament Meeting ──────────────────────────
                  _sectionCard(
                    title: 'Sacrament Meeting',
                    color: const Color(0xFF2C5282),
                    icon: Icons.menu_book,
                    children: [
                      LabeledField(
                        label: 'Meeting Time',
                        controller: _sacramentTimeCtrl,
                        hint: 'e.g. 9:00 AM',
                      ),
                      LabeledField(
                        label: 'Acknowledgement Template',
                        controller: _acknowledgementCtrl,
                        maxLines: 3,
                        hint:
                            'Use {OTHER_CONDUCTORS} for sacrament members, '
                            '{BISHOPRIC_OTHERS} for bishopric members.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Bishopric Meeting ──────────────────────────
                  _sectionCard(
                    title: 'Bishopric Meeting',
                    color: const Color(0xFFC62828),
                    icon: Icons.business_center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preferred Meeting Day',
                              style:
                                  Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _bishopricPreferredDay,
                            decoration: const InputDecoration(),
                            items: const [
                              DropdownMenuItem(value: 'Monday',    child: Text('Monday')),
                              DropdownMenuItem(value: 'Tuesday',   child: Text('Tuesday')),
                              DropdownMenuItem(value: 'Wednesday', child: Text('Wednesday')),
                              DropdownMenuItem(value: 'Thursday',  child: Text('Thursday')),
                              DropdownMenuItem(value: 'Friday',    child: Text('Friday')),
                              DropdownMenuItem(value: 'Saturday',  child: Text('Saturday')),
                              DropdownMenuItem(value: 'Sunday',    child: Text('Sunday')),
                            ],
                            onChanged: (v) => setState(
                                () => _bishopricPreferredDay = v!),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                      LabeledField(
                        label: 'Thursday Meeting Time',
                        controller: _bishopricThursdayTimeCtrl,
                        hint: 'e.g. 7:00 PM',
                      ),
                      LabeledField(
                        label: 'Sunday Meeting Time',
                        controller: _bishopricSundayTimeCtrl,
                        hint: 'e.g. 8:00 AM',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Ward Council Meeting ───────────────────────
                  _sectionCard(
                    title: 'Ward Council Meeting',
                    color: const Color(0xFF6A1B9A),
                    icon: Icons.groups,
                    children: [
                      LabeledField(
                        label: 'Occurrences (comma-separated)',
                        controller: _wardCouncilOccurrencesCtrl,
                        hint:
                            'e.g. 1,3  (1st and 3rd Sunday of month)',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,]')),
                        ],
                      ),
                      LabeledField(
                        label: 'Meeting Time',
                        controller: _wardCouncilTimeCtrl,
                        hint: 'e.g. 12:00 PM',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Speaker Cycle ──────────────────────────────
                  _sectionCard(
                    title: 'Speaker Cycle',
                    color: const Color(0xFF37474F),
                    icon: Icons.rotate_right,
                    children: [
                      LabeledField(
                        label: 'Base Month (yyyy-MM)',
                        controller: _speakerCycleBaseMonthCtrl,
                        hint: 'e.g. 2026-01 (month when cycle 1 starts)',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final re = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
                          if (!re.hasMatch(v.trim())) {
                            return 'Enter format yyyy-MM (e.g. 2026-01)';
                          }
                          return null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Text(
                          'Cycle repeats 1→2→3→1. Set the first month when cycle 1 occurred.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('2nd Sunday Cycle Assignments',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700])),
                      ),
                      _cycleDropdown('Cycle 1', _cycle2Slot1,
                          (v) => setState(() => _cycle2Slot1 = v!)),
                      _cycleDropdown('Cycle 2', _cycle2Slot2,
                          (v) => setState(() => _cycle2Slot2 = v!)),
                      _cycleDropdown('Cycle 3', _cycle2Slot3,
                          (v) => setState(() => _cycle2Slot3 = v!)),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, top: 4),
                        child: Text('4th Sunday Cycle Assignments',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700])),
                      ),
                      _cycleDropdown('Cycle 1', _cycle4Slot1,
                          (v) => setState(() => _cycle4Slot1 = v!)),
                      _cycleDropdown('Cycle 2', _cycle4Slot2,
                          (v) => setState(() => _cycle4Slot2 = v!)),
                      _cycleDropdown('Cycle 3', _cycle4Slot3,
                          (v) => setState(() => _cycle4Slot3 = v!)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saving ? null : _save,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Color color,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  static const _fastTestimony = 'Fast & Testimony';

  Widget _cycleDropdown(String label, String value, ValueChanged<String?> onChanged) {
    // All selectable values: Fast & Testimony sentinel first, then auxiliaries
    final auxItems = _auxiliaryNames.isEmpty ? <String>[] : _auxiliaryNames;
    final allValues = [_fastTestimony, ...auxItems];
    final safeValue = allValues.contains(value) ? value : allValues.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: safeValue,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(
                  value: _fastTestimony,
                  child: Text(
                    '— Fast & Testimony (no speaker) —',
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...auxItems.map((n) => DropdownMenuItem(
                    value: n,
                    child: Text(n, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
