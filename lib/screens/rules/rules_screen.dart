// screens/rules/rules_screen.dart
// Configuration screen for automation rules and ward settings.
// Mirrors the Spring Boot Rules tab.

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/ward_config.dart';
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
  late TextEditingController _meetingTimeCtrl;
  late TextEditingController _acknowledgementCtrl;
  late TextEditingController _bishopricPresidingCtrl;

  // Schedules
  String _sacramentSchedule = 'EVERY_SUNDAY';
  String _bishopricSchedule = 'EVERY_THURSDAY';
  String _wardCouncilSchedule = 'EVERY_SUNDAY_AFTER';

  // Logo
  String _logoPath = 'assets/images/P3_LOGO.png';

  @override
  void initState() {
    super.initState();
    _wardNameCtrl = TextEditingController();
    _stakeNameCtrl = TextEditingController();
    _meetingTimeCtrl = TextEditingController();
    _acknowledgementCtrl = TextEditingController();
    _bishopricPresidingCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _wardNameCtrl,
      _stakeNameCtrl,
      _meetingTimeCtrl,
      _acknowledgementCtrl,
      _bishopricPresidingCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _load() async {
    final cfg = await _db.getWardConfig();
    setState(() {
      _wardNameCtrl.text = cfg.wardName;
      _stakeNameCtrl.text = cfg.stakeName;
      _meetingTimeCtrl.text = cfg.meetingTime;
      _acknowledgementCtrl.text = cfg.acknowledgementTemplate;
      _bishopricPresidingCtrl.text = cfg.bishopricPresiding;
      _sacramentSchedule = cfg.sacramentSchedule;
      _bishopricSchedule = cfg.bishopricSchedule;
      _wardCouncilSchedule = cfg.wardCouncilSchedule;
      _logoPath = cfg.logoPath;
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
        meetingTime: _meetingTimeCtrl.text.trim(),
        acknowledgementTemplate: _acknowledgementCtrl.text.trim(),
        bishopricPresiding: _bishopricPresidingCtrl.text.trim(),
        sacramentSchedule: _sacramentSchedule,
        bishopricSchedule: _bishopricSchedule,
        wardCouncilSchedule: _wardCouncilSchedule,
        logoPath: _logoPath,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rules updated successfully'),
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
            label: const Text('Save', style: TextStyle(color: Colors.white)),
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
                  _sectionCard(
                    title: 'Ward Identity',
                    color: const Color(0xFF1B4F8A),
                    icon: Icons.church,
                    children: [
                      LabeledField(
                        label: 'Ward Name',
                        controller: _wardNameCtrl,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      LabeledField(
                        label: 'Stake Name',
                        controller: _stakeNameCtrl,
                      ),
                      LabeledField(
                        label: 'Meeting Time',
                        controller: _meetingTimeCtrl,
                        hint: 'e.g. 9:00 AM',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _sectionCard(
                    title: 'Logo',
                    color: const Color(0xFF37474F),
                    icon: Icons.image,
                    children: [
                      Text('Select which logo to display in exported documents:',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _logoOption('P3_LOGO.png', 'Pasay 3rd Ward Logo',
                              'assets/images/P3_LOGO.png'),
                          const SizedBox(width: 8),
                          _logoOption('LDS_LOGO.png', 'LDS/CoJCoLDS Logo',
                              'assets/images/LDS_LOGO.png'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _sectionCard(
                    title: 'Sacrament Meeting Rules',
                    color: const Color(0xFF2E7D32),
                    icon: Icons.menu_book,
                    children: [
                      _dropdownRow(
                        label: 'Meeting Schedule',
                        value: _sacramentSchedule,
                        items: const {
                          'EVERY_SUNDAY': 'Every Sunday',
                          '1ST_3RD': '1st & 3rd Sunday',
                          '2ND_4TH': '2nd & 4th Sunday',
                        },
                        onChanged: (v) =>
                            setState(() => _sacramentSchedule = v!),
                      ),
                      LabeledField(
                        label: 'Acknowledgement Template',
                        controller: _acknowledgementCtrl,
                        maxLines: 3,
                        hint:
                            'Default text for the acknowledgement section',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _sectionCard(
                    title: 'Bishopric Meeting Rules',
                    color: const Color(0xFFC62828),
                    icon: Icons.business_center,
                    children: [
                      _dropdownRow(
                        label: 'Meeting Schedule',
                        value: _bishopricSchedule,
                        items: const {
                          'EVERY_THURSDAY': 'Every Thursday',
                          'EVERY_MONDAY': 'Every Monday',
                        },
                        onChanged: (v) =>
                            setState(() => _bishopricSchedule = v!),
                      ),
                      LabeledField(
                        label: 'Presiding (always)',
                        controller: _bishopricPresidingCtrl,
                        hint: 'e.g. The Bishop (read-only in form)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _sectionCard(
                    title: 'Ward Council Meeting Rules',
                    color: const Color(0xFF6A1B9A),
                    icon: Icons.groups,
                    children: [
                      _dropdownRow(
                        label: 'Meeting Schedule',
                        value: _wardCouncilSchedule,
                        items: const {
                          'EVERY_SUNDAY_AFTER':
                              'Every Sunday (after Sacrament)',
                          'EVERY_THURSDAY': 'Every Thursday',
                          'CUSTOM': 'Custom date',
                        },
                        onChanged: (v) =>
                            setState(() => _wardCouncilSchedule = v!),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Prayers and handbook reading are auto-assigned '
                          'in round-robin order from the Auxiliaries and '
                          'Handbook Readings lists.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Rules'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saving ? null : _save,
                  ),
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

  Widget _dropdownRow({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _logoOption(String filename, String label, String assetPath) {
    final selected = _logoPath == assetPath;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _logoPath = assetPath),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? const Color(0xFF1B4F8A)
                  : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: selected
                ? const Color(0xFF1B4F8A).withValues(alpha: 0.05)
                : null,
          ),
          child: Column(
            children: [
              Image.asset(assetPath, height: 50, errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image, size: 50)),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? const Color(0xFF1B4F8A)
                        : Colors.grey[700],
                  )),
              if (selected)
                const Icon(Icons.check_circle,
                    color: Color(0xFF1B4F8A), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
