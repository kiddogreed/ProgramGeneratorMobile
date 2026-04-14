// screens/bishopric/bishopric_form_screen.dart
// Full form for creating/editing a Bishopric Meeting program.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database_helper.dart';
import '../../models/bishopric_program.dart';
import '../../models/conductor.dart';
import '../../models/agenda_item.dart';
import '../../utils/rotation_service.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/agenda_item_editor.dart';
import 'bishopric_preview_screen.dart';

class BishopricFormScreen extends StatefulWidget {
  final BishopricProgram? initial;

  const BishopricFormScreen({super.key, this.initial});

  @override
  State<BishopricFormScreen> createState() => _BishopricFormScreenState();
}

class _BishopricFormScreenState extends State<BishopricFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  late final TextEditingController _wardNameCtrl;
  late final TextEditingController _presidingCtrl;
  late final TextEditingController _conductingCtrl;
  late final TextEditingController _openingPrayerCtrl;
  late final TextEditingController _handbookCtrl;
  late final TextEditingController _callingsCtrl;
  late final TextEditingController _closingPrayerCtrl;

  DateTime _meetingDate = DateTime.now();
  List<AgendaItem> _agendaItems = [];
  List<Conductor> _conductors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final p = widget.initial ?? BishopricProgram();
    _wardNameCtrl = TextEditingController(text: p.wardName);
    _presidingCtrl = TextEditingController(text: p.presiding);
    _conductingCtrl = TextEditingController(text: p.conducting);
    _openingPrayerCtrl = TextEditingController(text: p.openingPrayer);
    _handbookCtrl = TextEditingController(text: p.handbookSpiritual);
    _callingsCtrl = TextEditingController(text: p.callingsAndReleases);
    _closingPrayerCtrl = TextEditingController(text: p.closingPrayer);
    _meetingDate = p.meetingDate;
    _agendaItems = List.from(p.agendaItems);
    _loadDropdowns();
  }

  @override
  void dispose() {
    for (final c in [
      _wardNameCtrl,
      _presidingCtrl,
      _conductingCtrl,
      _openingPrayerCtrl,
      _handbookCtrl,
      _callingsCtrl,
      _closingPrayerCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    final conductors = await _db.getConductors(programType: 'bishopric');
    if (mounted) {
      setState(() {
        _conductors = conductors;
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _meetingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _meetingDate = picked);
  }

  BishopricProgram _buildProgram() => BishopricProgram(
        wardName: _wardNameCtrl.text.trim(),
        meetingDate: _meetingDate,
        presiding: _presidingCtrl.text.trim(),
        conducting: _conductingCtrl.text.trim(),
        openingPrayer: _openingPrayerCtrl.text.trim(),
        handbookSpiritual: _handbookCtrl.text.trim(),
        agendaItems: _agendaItems,
        callingsAndReleases: _callingsCtrl.text.trim(),
        closingPrayer: _closingPrayerCtrl.text.trim(),
      );

  void _preview() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BishopricPreviewScreen(program: _buildProgram()),
      ),
    );
  }

  Future<void> _autoFill() async {
    try {
      final data = await RotationService(_db).autoPopulateBishopric();
      setState(() {
        if (data['meetingDate'] != null) {
          _meetingDate = DateTime.tryParse(data['meetingDate']!) ?? _meetingDate;
        }
        if (data['wardName'] != null) _wardNameCtrl.text = data['wardName']!;
        if (data['presiding'] != null) _presidingCtrl.text = data['presiding']!;
        if (data['openingPrayer'] != null) _openingPrayerCtrl.text = data['openingPrayer']!;
        if (data['closingPrayer'] != null) _closingPrayerCtrl.text = data['closingPrayer']!;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-filled from rotation rules'),
            backgroundColor: Color(0xFFC62828),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto-fill error: \$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bishopric Meeting'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('Auto-fill', style: TextStyle(color: Colors.white)),
            onPressed: _autoFill,
          ),
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _preview,
            tooltip: 'Preview',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header('Meeting Details'),
            LabeledField(
              label: 'Ward Name *',
              controller: _wardNameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ward name is required'
                  : null,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meeting Date *',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Text(
                        DateFormat('MMMM d, yyyy').format(_meetingDate)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
            LabeledField(
                label: 'Presiding', controller: _presidingCtrl, maxLength: 150),
            _conductorAutocomplete(),
            _header('Opening'),
            LabeledField(
                label: 'Opening Prayer',
                controller: _openingPrayerCtrl,
                maxLength: 150),
            LabeledField(
              label: 'Handbook / Spiritual Thought',
              controller: _handbookCtrl,
              maxLines: 3,
              maxLength: 300,
            ),
            _header('Agenda Items'),
            AgendaItemEditor(
              items: _agendaItems,
              onChanged: (items) => setState(() => _agendaItems = items),
            ),
            _header('Closing'),
            LabeledField(
              label: 'Callings & Releases',
              controller: _callingsCtrl,
              maxLines: 4,
              maxLength: 500,
            ),
            LabeledField(
                label: 'Closing Prayer',
                controller: _closingPrayerCtrl,
                maxLength: 150),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _preview,
              icon: const Icon(Icons.preview),
              label: const Text('Preview & Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _header(String title) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFC62828),
                      fontWeight: FontWeight.w700,
                    )),
            const Divider(height: 8),
          ],
        ),
      );

  Widget _conductorAutocomplete() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Conducting', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _conductingCtrl.text),
            optionsBuilder: (v) => _conductors
                .map((c) => c.name)
                .where((n) =>
                    n.toLowerCase().contains(v.text.toLowerCase()))
                .toList(),
            onSelected: (s) => setState(() => _conductingCtrl.text = s),
            fieldViewBuilder: (ctx, ctrl, node, onFieldSubmitted) =>
                TextFormField(
              controller: ctrl,
              focusNode: node,
              decoration: const InputDecoration(),
              onChanged: (v) => _conductingCtrl.text = v,
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
}
