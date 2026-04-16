// screens/bishopric/bishopric_form_screen.dart
// Full form for creating/editing a Bishopric Meeting program.
// Fields and auto-populate logic follow FLUTTER_APP_REFERENCE.md §7.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database_helper.dart';
import '../../models/bishopric_program.dart';
import '../../models/conductor.dart';
import '../../models/agenda_item.dart';
import '../../utils/rotation_service.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/locked_field_widget.dart';
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

  // Locked / auto-populated
  String _presiding = '';

  // Dropdown selections
  String? _conducting;
  String? _openingPrayer;
  String? _handbookSpiritual;
  String? _closingPrayer;

  DateTime _meetingDate = DateTime.now();
  List<AgendaItem> _agendaItems = [];
  List<Conductor> _conductors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _wardNameCtrl = TextEditingController(text: p?.wardName ?? '');

    if (p != null) {
      _meetingDate = p.meetingDate;
      _presiding = p.presiding;
      _conducting = p.conducting.isEmpty ? null : p.conducting;
      _openingPrayer = p.openingPrayer.isEmpty ? null : p.openingPrayer;
      _handbookSpiritual =
          p.handbookSpiritual.isEmpty ? null : p.handbookSpiritual;
      _closingPrayer = p.closingPrayer.isEmpty ? null : p.closingPrayer;
      _agendaItems = List.from(p.agendaItems);
    }

    _loadAll();
  }

  @override
  void dispose() {
    _wardNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final conductors = await _db.getConductors(programType: 'bishopric');

    if (widget.initial == null) {
      // Auto-populate on new form: advances conductor immediately (per spec)
      try {
        final data = await RotationService(_db).autoPopulateBishopric();
        if (mounted) {
          setState(() {
            _conductors = conductors;
            if (data['meetingDate'] != null) {
              _meetingDate =
                  DateTime.tryParse(data['meetingDate'] as String) ??
                      _meetingDate;
            }
            if (data['wardName'] != null) {
              _wardNameCtrl.text = data['wardName'] as String;
            }
            _presiding = (data['presiding'] as String?) ?? '';
            final cond = data['conducting'] as String? ?? '';
            _conducting =
                conductors.any((c) => c.name == cond) ? cond : null;
            final op = data['openingPrayer'] as String? ?? '';
            _openingPrayer =
                conductors.any((c) => c.name == op) ? op : null;
            final hb = data['handbookSpiritual'] as String? ?? '';
            _handbookSpiritual =
                conductors.any((c) => c.name == hb) ? hb : null;
            final cp = data['closingPrayer'] as String? ?? '';
            _closingPrayer =
                conductors.any((c) => c.name == cp) ? cp : null;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _conductors = conductors;
            _loading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _conductors = conductors;
          _loading = false;
        });
      }
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
        presiding: _presiding,
        conducting: _conducting ?? '',
        openingPrayer: _openingPrayer ?? '',
        handbookSpiritual: _handbookSpiritual ?? '',
        agendaItems: _agendaItems,
        callingsAndReleases: '',
        closingPrayer: _closingPrayer ?? '',
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final conductorNames = _conductors.map((c) => c.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bishopric Meeting'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        actions: [
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
            _datePicker(),
            _header('Leadership'),
            LockedFieldWidget(label: 'Presiding', value: _presiding),
            _dropdownField(
              label: 'Conducting *',
              value: _conducting,
              items: conductorNames,
              onChanged: (v) => setState(() => _conducting = v),
              validator: (v) => v == null ? 'Select a conductor' : null,
            ),
            _header('Opening'),
            _dropdownField(
              label: 'Opening Prayer',
              value: _openingPrayer,
              items: conductorNames,
              onChanged: (v) => setState(() => _openingPrayer = v),
            ),
            _dropdownField(
              label: 'Handbook / Spiritual Thought',
              value: _handbookSpiritual,
              items: conductorNames,
              onChanged: (v) => setState(() => _handbookSpiritual = v),
            ),
            _header('Agenda Items'),
            AgendaItemEditor(
              items: _agendaItems,
              onChanged: (items) => setState(() => _agendaItems = items),
            ),
            _header('Closing'),
            _dropdownField(
              label: 'Closing Prayer',
              value: _closingPrayer,
              items: conductorNames,
              onChanged: (v) => setState(() => _closingPrayer = v),
            ),
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFFC62828),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Divider(height: 8),
          ],
        ),
      );

  Widget _datePicker() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meeting Date *',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(),
              child: Text(DateFormat('MMMM d, yyyy').format(_meetingDate)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          isExpanded: true,
          decoration: const InputDecoration(),
          hint: const Text('Select…'),
          items: items
              .map((n) => DropdownMenuItem(value: n, child: Text(n)))
              .toList(),
          onChanged: onChanged,
          validator: validator,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
