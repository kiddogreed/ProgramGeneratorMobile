// screens/ward_council/ward_council_form_screen.dart
// Full form for creating/editing a Ward Council program.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database_helper.dart';
import '../../models/ward_council_program.dart';
import '../../models/conductor.dart';
import '../../models/auxiliary.dart';
import '../../models/agenda_item.dart';
import '../../utils/rotation_service.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/agenda_item_editor.dart';
import 'ward_council_preview_screen.dart';

class WardCouncilFormScreen extends StatefulWidget {
  final WardCouncilProgram? initial;

  const WardCouncilFormScreen({super.key, this.initial});

  @override
  State<WardCouncilFormScreen> createState() => _WardCouncilFormScreenState();
}

class _WardCouncilFormScreenState extends State<WardCouncilFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  late final TextEditingController _wardNameCtrl;
  late final TextEditingController _presidingCtrl;
  late final TextEditingController _conductingCtrl;
  late final TextEditingController _openingPrayerCtrl;
  late final TextEditingController _handbookCtrl;
  late final TextEditingController _welfareCtrl;
  late final TextEditingController _closingPrayerCtrl;

  DateTime _meetingDate = DateTime.now();
  String _auxiliary = '';
  List<AgendaItem> _agendaItems = [];
  List<Conductor> _conductors = [];
  List<Auxiliary> _auxiliaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final p = widget.initial ?? WardCouncilProgram();
    _wardNameCtrl = TextEditingController(text: p.wardName);
    _presidingCtrl = TextEditingController(text: p.presiding);
    _conductingCtrl = TextEditingController(text: p.conducting);
    _openingPrayerCtrl = TextEditingController(text: p.openingPrayer);
    _handbookCtrl = TextEditingController(text: p.handbookReading);
    _welfareCtrl = TextEditingController(text: p.welfare);
    _closingPrayerCtrl = TextEditingController(text: p.closingPrayer);
    _meetingDate = p.meetingDate;
    _auxiliary = p.auxiliary;
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
      _welfareCtrl,
      _closingPrayerCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    final conductors = await _db.getConductors(programType: 'ward_council');
    final auxiliaries = await _db.getAuxiliaries();
    if (mounted) {
      setState(() {
        _conductors = conductors;
        _auxiliaries = auxiliaries;
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

  WardCouncilProgram _buildProgram() => WardCouncilProgram(
        wardName: _wardNameCtrl.text.trim(),
        meetingDate: _meetingDate,
        presiding: _presidingCtrl.text.trim(),
        conducting: _conductingCtrl.text.trim(),
        openingPrayer: _openingPrayerCtrl.text.trim(),
        handbookReading: _handbookCtrl.text.trim(),
        auxiliary: _auxiliary,
        agendaItems: _agendaItems,
        welfare: _welfareCtrl.text.trim(),
        closingPrayer: _closingPrayerCtrl.text.trim(),
      );

  void _preview() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WardCouncilPreviewScreen(program: _buildProgram()),
      ),
    );
  }

  Future<void> _autoFill() async {
    try {
      final data = await RotationService(_db).autoPopulateWardCouncil();
      setState(() {
        if (data['meetingDate'] != null) {
          _meetingDate = DateTime.tryParse(data['meetingDate']!) ?? _meetingDate;
        }
        if (data['wardName'] != null) _wardNameCtrl.text = data['wardName']!;
        if (data['presiding'] != null) _presidingCtrl.text = data['presiding']!;
        if (data['openingPrayer'] != null) _openingPrayerCtrl.text = data['openingPrayer']!;
        if (data['closingPrayer'] != null) _closingPrayerCtrl.text = data['closingPrayer']!;
        if (data['handbookReading'] != null) _handbookCtrl.text = data['handbookReading']!;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-filled from rotation rules'),
            backgroundColor: Color(0xFF6A1B9A),
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

    final auxNames = _auxiliaries.map((a) => a.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ward Council'),
        backgroundColor: const Color(0xFF6A1B9A),
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
            LabeledField(label: 'Presiding', controller: _presidingCtrl),
            _conductorAutocomplete(),
            _header('Opening'),
            LabeledField(
                label: 'Opening Prayer', controller: _openingPrayerCtrl),
            LabeledField(
              label: 'Handbook Reading',
              controller: _handbookCtrl,
              maxLines: 3,
            ),
            _header('Agenda'),
            // Auxiliary selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reporting Auxiliary',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: (_auxiliary.isNotEmpty && auxNames.contains(_auxiliary))
                      ? _auxiliary
                      : null,
                  items: auxNames
                      .map((n) =>
                          DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) => setState(() => _auxiliary = v ?? ''),
                  decoration: const InputDecoration(),
                  hint: const Text('Select auxiliary…'),
                ),
                const SizedBox(height: 12),
              ],
            ),
            AgendaItemEditor(
              items: _agendaItems,
              onChanged: (items) => setState(() => _agendaItems = items),
            ),
            _header('Closing'),
            LabeledField(label: 'Welfare', controller: _welfareCtrl, maxLines: 3),
            LabeledField(
                label: 'Closing Prayer', controller: _closingPrayerCtrl),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _preview,
              icon: const Icon(Icons.preview),
              label: const Text('Preview & Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
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
                      color: const Color(0xFF6A1B9A),
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
