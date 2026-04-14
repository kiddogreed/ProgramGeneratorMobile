// screens/ward_council/ward_council_form_screen.dart
// Full form for creating/editing a Ward Council program.
// Fields and auto-populate logic follow FLUTTER_APP_REFERENCE.md §8.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database_helper.dart';
import '../../models/ward_council_program.dart';
import '../../models/conductor.dart';
import '../../models/auxiliary.dart';
import '../../models/agenda_item.dart';
import '../../utils/rotation_service.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/locked_field_widget.dart';
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
  late final TextEditingController _welfareCtrl;

  // Locked / auto-populated
  String _presiding = '';

  // Dropdown selections (conductors = bishopric, prayers = auxiliaries)
  String? _conducting;
  String? _openingPrayer;
  String? _handbookReading;
  String? _closingPrayer;

  DateTime _meetingDate = DateTime.now();
  List<AgendaItem> _agendaItems = [];
  List<Conductor> _conductors = [];
  List<Auxiliary> _auxiliaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _wardNameCtrl = TextEditingController(text: p?.wardName ?? '');
    _welfareCtrl = TextEditingController(text: p?.welfare ?? '');

    if (p != null) {
      _meetingDate = p.meetingDate;
      _presiding = p.presiding;
      _conducting = p.conducting.isEmpty ? null : p.conducting;
      _openingPrayer = p.openingPrayer.isEmpty ? null : p.openingPrayer;
      _handbookReading = p.handbookReading.isEmpty ? null : p.handbookReading;
      _closingPrayer = p.closingPrayer.isEmpty ? null : p.closingPrayer;
      _agendaItems = List.from(p.agendaItems);
    }

    _loadAll();
  }

  @override
  void dispose() {
    _wardNameCtrl.dispose();
    _welfareCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    // Ward Council uses bishopric conductors for Conducting (spec §8)
    final conductors = await _db.getConductors(programType: 'bishopric');
    final auxiliaries = await _db.getAuxiliaries();

    if (widget.initial == null) {
      // Auto-populate on new form: advances conductor immediately (per spec)
      try {
        final data = await RotationService(_db).autoPopulateWardCouncil();
        if (mounted) {
          setState(() {
            _conductors = conductors;
            _auxiliaries = auxiliaries;
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
                auxiliaries.any((a) => a.name == op) ? op : null;
            final hr = data['handbookReading'] as String? ?? '';
            _handbookReading =
                auxiliaries.any((a) => a.name == hr) ? hr : null;
            final cp = data['closingPrayer'] as String? ?? '';
            _closingPrayer =
                auxiliaries.any((a) => a.name == cp) ? cp : null;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _conductors = conductors;
            _auxiliaries = auxiliaries;
            _loading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _conductors = conductors;
          _auxiliaries = auxiliaries;
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

  WardCouncilProgram _buildProgram() => WardCouncilProgram(
        wardName: _wardNameCtrl.text.trim(),
        meetingDate: _meetingDate,
        presiding: _presiding,
        conducting: _conducting ?? '',
        openingPrayer: _openingPrayer ?? '',
        handbookReading: _handbookReading ?? '',
        agendaItems: _agendaItems,
        welfare: _welfareCtrl.text.trim(),
        closingPrayer: _closingPrayer ?? '',
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final conductorNames = _conductors.map((c) => c.name).toList();
    final auxNames = _auxiliaries.map((a) => a.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ward Council'),
        backgroundColor: const Color(0xFF6A1B9A),
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
              items: auxNames,
              onChanged: (v) => setState(() => _openingPrayer = v),
            ),
            _dropdownField(
              label: 'Handbook Reading',
              value: _handbookReading,
              items: auxNames,
              onChanged: (v) => setState(() => _handbookReading = v),
            ),
            _header('Agenda Items'),
            AgendaItemEditor(
              items: _agendaItems,
              onChanged: (items) => setState(() => _agendaItems = items),
            ),
            _header('Closing'),
            LabeledField(
              label: 'Welfare',
              controller: _welfareCtrl,
              maxLines: 3,
              maxLength: 500,
            ),
            _dropdownField(
              label: 'Closing Prayer',
              value: _closingPrayer,
              items: auxNames,
              onChanged: (v) => setState(() => _closingPrayer = v),
            ),
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF6A1B9A),
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
          value: safeValue,
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
