// screens/sacrament/sacrament_form_screen.dart
// Full form for creating/editing a Sacrament Meeting program.
// Fields and auto-populate logic follow FLUTTER_APP_REFERENCE.md §6.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database_helper.dart';
import '../../models/sacrament_program.dart';
import '../../models/musician.dart';
import '../../models/conductor.dart';
import '../../models/auxiliary.dart';
import '../../models/speaker.dart';
import '../../utils/rotation_service.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/speaker_cycle_badge.dart';
import '../../widgets/speaker_list_editor.dart';
import '../../widgets/announcements_editor.dart';
import 'sacrament_preview_screen.dart';

class SacramentFormScreen extends StatefulWidget {
  /// Pass an existing program to load/edit from history.
  final SacramentProgram? initial;

  const SacramentFormScreen({super.key, this.initial});

  @override
  State<SacramentFormScreen> createState() => _SacramentFormScreenState();
}

class _SacramentFormScreenState extends State<SacramentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  // Controllers
  late final TextEditingController _stakeNameCtrl;
  late final TextEditingController _wardNameCtrl;
  late final TextEditingController _presidingCtrl;
  late final TextEditingController _acknowledgeCtrl;
  late final TextEditingController _openingHymnCtrl;
  late final TextEditingController _sacramentHymnCtrl;
  late final TextEditingController _closingHymnCtrl;
  late final TextEditingController _invocationCtrl;
  late final TextEditingController _wardBusinessCtrl;
  late final TextEditingController _stakeBusinessCtrl;
  late final TextEditingController _benedictionCtrl;

  DateTime _meetingDate = DateTime.now();
  String? _conducting;         // selected conductor name
  String? _chorister;
  String? _pianist;
  String? _speakersAuxiliary;
  List<Speaker> _speakers = [];
  List<String> _announcements = [];
  String _speakerTypeLabel = '';

  List<Musician> _choristers = [];
  List<Musician> _pianists = [];
  List<Conductor> _conductors = [];
  List<Auxiliary> _auxiliaries = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _stakeNameCtrl = TextEditingController(text: p?.stakeName ?? '');
    _wardNameCtrl = TextEditingController(text: p?.wardName ?? '');
    _presidingCtrl = TextEditingController(text: p?.presiding ?? '');
    _acknowledgeCtrl = TextEditingController(text: p?.acknowledgement ?? '');
    _openingHymnCtrl = TextEditingController(text: p?.openingHymn ?? '');
    _sacramentHymnCtrl = TextEditingController(text: p?.sacramentHymn ?? '');
    _closingHymnCtrl = TextEditingController(text: p?.closingHymn ?? '');
    _invocationCtrl = TextEditingController(text: p?.invocation ?? '');
    _wardBusinessCtrl = TextEditingController(text: p?.wardBusiness ?? '');
    _stakeBusinessCtrl = TextEditingController(text: p?.stakeBusiness ?? '');
    _benedictionCtrl = TextEditingController(text: p?.benediction ?? '');

    if (p != null) {
      _meetingDate = p.date;
      _conducting = p.conducting.isEmpty ? null : p.conducting;
      _chorister = p.chorister.isEmpty ? null : p.chorister;
      _pianist = p.pianist.isEmpty ? null : p.pianist;
      _speakersAuxiliary =
          p.speakersAuxiliary.isEmpty ? null : p.speakersAuxiliary;
      _speakers = List.from(p.speakers);
      _announcements = List.from(p.announcements);
    }

    _loadAll();
  }

  @override
  void dispose() {
    for (final c in [
      _stakeNameCtrl,
      _wardNameCtrl,
      _presidingCtrl,
      _acknowledgeCtrl,
      _openingHymnCtrl,
      _sacramentHymnCtrl,
      _closingHymnCtrl,
      _invocationCtrl,
      _wardBusinessCtrl,
      _stakeBusinessCtrl,
      _benedictionCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAll() async {
    final choristers = await _db.getMusicians(type: 'chorister');
    final pianists = await _db.getMusicians(type: 'pianist');
    final conductors = await _db.getConductors(programType: 'sacrament');
    final auxiliaries = await _db.getAuxiliaries();

    // Auto-populate only when creating (not loading from history)
    if (widget.initial == null) {
      try {
        final data =
            await RotationService(_db).autoPopulateSacrament();
        if (mounted) {
          setState(() {
            _choristers = choristers;
            _pianists = pianists;
            _conductors = conductors;
            _auxiliaries = auxiliaries;

            if (data['date'] != null) {
              _meetingDate =
                  DateTime.tryParse(data['date'] as String) ?? _meetingDate;
            }
            if (data['wardName'] != null) {
              _wardNameCtrl.text = data['wardName'] as String;
            }
            if (data['stakeName'] != null) {
              _stakeNameCtrl.text = data['stakeName'] as String;
            }
            if (data['presiding'] != null &&
                (data['presiding'] as String).isNotEmpty) {
              _presidingCtrl.text = data['presiding'] as String;
            }
            if (data['acknowledgement'] != null) {
              _acknowledgeCtrl.text = data['acknowledgement'] as String;
            }
            if (data['conducting'] != null &&
                (data['conducting'] as String).isNotEmpty) {
              final name = data['conducting'] as String;
              _conducting = conductors.any((c) => c.name == name) ? name : null;
            }
            _speakerTypeLabel =
                data['speakerTypeLabel'] as String? ?? '';
            // Auto-fill the speakers' auxiliary from the cycle
            final autoAux = data['speakerAuxiliary'] as String?;
            if (_speakersAuxiliary == null && autoAux != null) {
              final auxNames = auxiliaries.map((a) => a.name).toList();
              if (auxNames.contains(autoAux)) _speakersAuxiliary = autoAux;
            }
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _choristers = choristers;
            _pianists = pianists;
            _conductors = conductors;
            _auxiliaries = auxiliaries;
            _loading = false;
          });
        }
      }
    } else {
      // Loading from history — just populate dropdowns
      if (mounted) {
        setState(() {
          _choristers = choristers;
          _pianists = pianists;
          _conductors = conductors;
          _auxiliaries = auxiliaries;
          _loading = false;
        });
        // Compute badge label only — do NOT overwrite saved auxiliary
        _loadSpeakerTypeLabelForDate(_meetingDate, updateAuxiliary: false);
      }
    }
  }

  Future<void> _loadSpeakerTypeLabelForDate(DateTime date,
      {bool updateAuxiliary = true}) async {
    try {
      final cfg = await _db.getWardConfig();
      final label = RotationService.getSpeakerTypeLabel(date, cfg);
      final autoAux = RotationService.speakerLabelToAuxiliary(label);
      if (mounted) {
        setState(() {
          _speakerTypeLabel = label;
          if (updateAuxiliary) {
            final auxNames = _auxiliaries.map((a) => a.name).toList();
            if (autoAux != null && auxNames.contains(autoAux)) {
              _speakersAuxiliary = autoAux;
            } else if (autoAux == null) {
              _speakersAuxiliary = null;
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _meetingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _meetingDate = picked);
      _loadSpeakerTypeLabelForDate(picked);
    }
  }

  SacramentProgram _buildProgram() => SacramentProgram(
        stakeName: _stakeNameCtrl.text.trim(),
        wardName: _wardNameCtrl.text.trim(),
        date: _meetingDate,
        presiding: _presidingCtrl.text.trim(),
        conducting: _conducting ?? '',
        acknowledgement: _acknowledgeCtrl.text.trim(),
        announcements:
            _announcements.where((a) => a.trim().isNotEmpty).toList(),
        chorister: _chorister ?? '',
        pianist: _pianist ?? '',
        openingHymn: _openingHymnCtrl.text.trim(),
        sacramentHymn: _sacramentHymnCtrl.text.trim(),
        closingHymn: _closingHymnCtrl.text.trim(),
        invocation: _invocationCtrl.text.trim(),
        wardBusiness: _wardBusinessCtrl.text.trim(),
        stakeBusiness: _stakeBusinessCtrl.text.trim(),
        speakers: _speakers,
        speakersAuxiliary: _speakersAuxiliary ?? '',
        benediction: _benedictionCtrl.text.trim(),
      );

  void _preview() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SacramentPreviewScreen(program: _buildProgram()),
      ),
    );
  }

  void _clear() {
    setState(() {
      _stakeNameCtrl.clear();
      _wardNameCtrl.clear();
      _presidingCtrl.clear();
      _acknowledgeCtrl.clear();
      _openingHymnCtrl.clear();
      _sacramentHymnCtrl.clear();
      _closingHymnCtrl.clear();
      _invocationCtrl.clear();
      _wardBusinessCtrl.clear();
      _stakeBusinessCtrl.clear();
      _benedictionCtrl.clear();
      _meetingDate = RotationService.nextSacramentDate();
      _conducting = null;
      _chorister = null;
      _pianist = null;
      _speakersAuxiliary = null;
      _speakers = [];
      _announcements = [];
    });
    _loadAll();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final conductorNames = _conductors.map((c) => c.name).toList();
    final choristerNames = _choristers.map((m) => m.name).toList();
    final pianistNames = _pianists.map((m) => m.name).toList();
    final auxiliaryNames = _auxiliaries.map((a) => a.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sacrament Meeting'),
        backgroundColor: const Color(0xFF2C5282),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear',
            onPressed: _clear,
          ),
          IconButton(
            icon: const Icon(Icons.preview),
            tooltip: 'Preview',
            onPressed: _preview,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Meeting Details ──────────────────────────────────────
            _sectionHeader('Meeting Details'),
            LabeledField(
              label: 'Stake Name',
              controller: _stakeNameCtrl,
              hint: 'e.g. Pasay Philippine Stake',
            ),
            LabeledField(
              label: 'Ward Name *',
              controller: _wardNameCtrl,
              hint: 'e.g. Pasay 3rd Ward',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ward name is required'
                  : null,
            ),
            // Date picker
            _datePicker(),
            LabeledField(
              label: 'Presiding',
              controller: _presidingCtrl,
              hint: 'e.g. Bishop Sherwin Tan',
            ),
            // Conducting — DropdownButtonFormField from sacrament conductors
            _dropdownField(
              label: 'Conducting',
              value: (_conducting != null &&
                      conductorNames.contains(_conducting))
                  ? _conducting
                  : null,
              items: conductorNames,
              hint: 'Select conductor…',
              onChanged: (v) => setState(() => _conducting = v),
            ),

            // ── Music ────────────────────────────────────────────────
            _sectionHeader('Music'),
            _dropdownField(
              label: 'Chorister',
              value: (_chorister != null && choristerNames.contains(_chorister))
                  ? _chorister
                  : null,
              items: choristerNames,
              hint: 'Select chorister…',
              onChanged: (v) => setState(() => _chorister = v),
            ),
            _dropdownField(
              label: 'Pianist',
              value: (_pianist != null && pianistNames.contains(_pianist))
                  ? _pianist
                  : null,
              items: pianistNames,
              hint: 'Select pianist…',
              onChanged: (v) => setState(() => _pianist = v),
            ),
            LabeledField(
                label: 'Opening Hymn',
                controller: _openingHymnCtrl,
                hint: 'e.g. #2 The Spirit of God'),
            LabeledField(
                label: 'Sacrament Hymn',
                controller: _sacramentHymnCtrl,
                hint: 'e.g. #169 Again, Our Dear…'),
            LabeledField(
                label: 'Closing Hymn',
                controller: _closingHymnCtrl,
                hint: 'e.g. #220 Lead, Kindly Light'),

            // ── Program ─────────────────────────────────────────────
            _sectionHeader('Program'),
            LabeledField(
                label: 'Invocation', controller: _invocationCtrl),
            LabeledField(
              label: 'Ward Business',
              controller: _wardBusinessCtrl,
              maxLines: 5,
              maxLength: 600,
              keyboardType: TextInputType.multiline,
              hint: 'e.g. release: secretary\nsustain: president',
            ),
            LabeledField(
              label: 'Stake Business',
              controller: _stakeBusinessCtrl,
              maxLines: 3,
              maxLength: 400,
            ),

            // ── Speakers ─────────────────────────────────────────────
            _sectionHeader('Speakers'),
            if (_speakerTypeLabel.isNotEmpty)
              SpeakerCycleBadge(label: _speakerTypeLabel),
            SpeakerListEditor(
              speakers: _speakers,
              onChanged: (updated) =>
                  setState(() => _speakers = updated),
            ),
            _dropdownField(
              label: "Speakers' Auxiliary",
              value: (_speakersAuxiliary != null &&
                      auxiliaryNames.contains(_speakersAuxiliary))
                  ? _speakersAuxiliary
                  : null,
              items: auxiliaryNames,
              hint: 'Select auxiliary…',
              onChanged: (v) => setState(() => _speakersAuxiliary = v),
            ),

            // ── Closing ──────────────────────────────────────────────
            _sectionHeader('Closing'),
            LabeledField(
                label: 'Benediction', controller: _benedictionCtrl),

            // ── Acknowledgements ──────────────────────────────────────
            _sectionHeader('Acknowledgements'),
            LabeledField(
              label: 'Acknowledgement',
              controller: _acknowledgeCtrl,
              maxLines: 4,
              maxLength: 600,
              hint: 'Auto-filled from template',
            ),

            // ── Announcements ─────────────────────────────────────────
            _sectionHeader('Announcements'),
            AnnouncementsEditor(
              announcements: _announcements,
              onChanged: (updated) =>
                  setState(() => _announcements = updated),
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _preview,
              icon: const Icon(Icons.preview),
              label: const Text('Preview & Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5282),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF2C5282),
                      fontWeight: FontWeight.w700,
                    )),
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
              child: Text(DateFormat('MMMM d, yyyy').format(_meetingDate),
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String hint = 'Select…',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: (value != null && items.contains(value)) ? value : null,
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(),
          hint: Text(hint),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

