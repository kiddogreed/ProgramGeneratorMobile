// screens/sacrament/sacrament_form_screen.dart
// Full form for creating/editing a Sacrament Meeting program.
// Mirrors the Spring Boot sacrament.html template.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database_helper.dart';
import '../../models/sacrament_program.dart';
import '../../models/musician.dart';
import '../../models/conductor.dart';
import '../../models/speaker.dart';
import '../../utils/rotation_service.dart';
import '../../widgets/labeled_field.dart';
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
  late final TextEditingController _conductingCtrl;
  late final TextEditingController _acknowledgeCtrl;
  late final TextEditingController _openingHymnCtrl;
  late final TextEditingController _sacramentHymnCtrl;
  late final TextEditingController _closingHymnCtrl;
  late final TextEditingController _invocationCtrl;
  late final TextEditingController _wardBusinessCtrl;
  late final TextEditingController _stakeBusinessCtrl;
  late final TextEditingController _benedictionCtrl;

  DateTime _meetingDate = DateTime.now();
  String _chorister = '';
  String _pianist = '';
  String _speakersAuxiliary = '';
  List<Speaker> _speakers = [];
  List<String> _announcements = [];

  List<Musician> _choristers = [];
  List<Musician> _pianists = [];
  List<Conductor> _conductors = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final p = widget.initial ?? SacramentProgram();
    _stakeNameCtrl = TextEditingController(text: p.stakeName);
    _wardNameCtrl = TextEditingController(text: p.wardName);
    _presidingCtrl = TextEditingController(text: p.presiding);
    _conductingCtrl = TextEditingController(text: p.conducting);
    _acknowledgeCtrl = TextEditingController(text: p.acknowledgement);
    _openingHymnCtrl = TextEditingController(text: p.openingHymn);
    _sacramentHymnCtrl = TextEditingController(text: p.sacramentHymn);
    _closingHymnCtrl = TextEditingController(text: p.closingHymn);
    _invocationCtrl = TextEditingController(text: p.invocation);
    _wardBusinessCtrl = TextEditingController(text: p.wardBusiness);
    _stakeBusinessCtrl = TextEditingController(text: p.stakeBusiness);
    _benedictionCtrl = TextEditingController(text: p.benediction);

    _meetingDate = p.date;
    _chorister = p.chorister;
    _pianist = p.pianist;
    _speakersAuxiliary = p.speakersAuxiliary;
    _speakers = List.from(p.speakers);
    _announcements = List.from(p.announcements);

    _loadDropdowns();
  }

  @override
  void dispose() {
    for (final c in [
      _stakeNameCtrl,
      _wardNameCtrl,
      _presidingCtrl,
      _conductingCtrl,
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

  Future<void> _loadDropdowns() async {
    final choristers = await _db.getMusicians(type: 'chorister');
    final pianists = await _db.getMusicians(type: 'pianist');
    final conductors = await _db.getConductors(programType: 'sacrament');
    if (mounted) {
      setState(() {
        _choristers = choristers;
        _pianists = pianists;
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

  SacramentProgram _buildProgram() => SacramentProgram(
        stakeName: _stakeNameCtrl.text.trim(),
        wardName: _wardNameCtrl.text.trim(),
        date: _meetingDate,
        presiding: _presidingCtrl.text.trim(),
        conducting: _conductingCtrl.text.trim(),
        acknowledgement: _acknowledgeCtrl.text.trim(),
        announcements:
            _announcements.where((a) => a.trim().isNotEmpty).toList(),
        chorister: _chorister,
        pianist: _pianist,
        openingHymn: _openingHymnCtrl.text.trim(),
        sacramentHymn: _sacramentHymnCtrl.text.trim(),
        closingHymn: _closingHymnCtrl.text.trim(),
        invocation: _invocationCtrl.text.trim(),
        wardBusiness: _wardBusinessCtrl.text.trim(),
        stakeBusiness: _stakeBusinessCtrl.text.trim(),
        speakers: _speakers,
        speakersAuxiliary: _speakersAuxiliary,
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

  Future<void> _autoFill() async {
    try {
      final data = await RotationService(_db).autoPopulateSacrament();
      setState(() {
        if (data['date'] != null) {
          _meetingDate = DateTime.tryParse(data['date']!) ?? _meetingDate;
        }
        if (data['wardName'] != null) _wardNameCtrl.text = data['wardName']!;
        if (data['stakeName'] != null) _stakeNameCtrl.text = data['stakeName']!;
        if (data['presiding'] != null) _presidingCtrl.text = data['presiding']!;
        if (data['acknowledgement'] != null) {
          _acknowledgeCtrl.text = data['acknowledgement']!;
        }
        if (data['suggestedSpeakers'] != null) {
          final names = (data['suggestedSpeakers'] as String).split(',');
          _speakers = names
              .where((n) => n.trim().isNotEmpty)
              .map((n) => Speaker(name: n.trim()))
              .toList();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-filled from rotation rules'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto-fill error: $e')),
        );
      }
    }
  }

  void _testPreview() {
    final testProgram = SacramentProgram(
      wardName: 'Pasay 3rd Ward',
      stakeName: 'Pasay Philippines Stake',
      date: DateTime.now(),
      presiding: 'Bishop John Smith',
      conducting: 'Bro. Carlos Reyes',
      chorister: 'Sis. Maria Santos',
      pianist: 'Sis. Ana Cruz',
      openingHymn: '#2 – The Spirit of God',
      sacramentHymn: '#169 – Again, Our Dear Assembling Here',
      closingHymn: '#197 – Lead, Kindly Light',
      invocation: 'Bro. Jorge Dela Cruz',
      speakers: [
        Speaker(name: 'Sis. Elena Reyes', title: 'RS President', topic: 'Faith in Christ'),
        Speaker(name: 'Bro. Mike Santos', title: 'EQ President', topic: 'Service'),
      ],
      speakersAuxiliary: 'Elders Quorum',
      benediction: 'Sis. Liza Gomez',
      acknowledgement:
          'We welcome all visitors. Sacrament meeting is the most important meeting of the week.',
      announcements: [
        'Youth activity this Friday at 6 PM.',
        'Temple trip on the 15th — sign up in the foyer.',
        'Fast Sunday next week.',
      ],
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SacramentPreviewScreen(program: testProgram),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sacrament Meeting'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('Auto-fill', style: TextStyle(color: Colors.white)),
            onPressed: _autoFill,
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
            _sectionHeader('Meeting Details'),
            LabeledField(
              label: 'Stake Name',
              controller: _stakeNameCtrl,
              hint: 'e.g. Pasay Philippines Stake',
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
              label: 'Presiding',
              controller: _presidingCtrl,
              hint: 'e.g. Bishop John Smith',
            ),
            _dropdownField(
              label: 'Conducting',
              value: _conductingCtrl.text.isEmpty ? null : _conductingCtrl.text,
              items: _conductors.map((c) => c.name).toList(),
              onChanged: (v) => setState(() => _conductingCtrl.text = v ?? ''),
              allowCustom: true,
              customController: _conductingCtrl,
            ),
            _sectionHeader('Music'),
            _dropdownField(
              label: 'Chorister',
              value: _chorister.isEmpty ? null : _chorister,
              items: _choristers.map((m) => m.name).toList(),
              onChanged: (v) => setState(() => _chorister = v ?? ''),
            ),
            _dropdownField(
              label: 'Pianist',
              value: _pianist.isEmpty ? null : _pianist,
              items: _pianists.map((m) => m.name).toList(),
              onChanged: (v) => setState(() => _pianist = v ?? ''),
            ),
            LabeledField(
                label: 'Opening Hymn', controller: _openingHymnCtrl),
            LabeledField(
                label: 'Sacrament Hymn', controller: _sacramentHymnCtrl),
            LabeledField(
                label: 'Closing Hymn', controller: _closingHymnCtrl),
            _sectionHeader('Program'),
            LabeledField(
                label: 'Invocation', controller: _invocationCtrl),
            LabeledField(
              label: 'Ward Business',
              controller: _wardBusinessCtrl,
              maxLines: 3,
              maxLength: 400,
              hint: 'Callings, releases, etc.',
            ),
            LabeledField(
              label: 'Stake Business',
              controller: _stakeBusinessCtrl,
              maxLines: 3,
              maxLength: 400,
            ),
            _sectionHeader('Speakers'),
            // Auxiliary dropdown
            _dropdownField(
              label: "Speakers' Auxiliary",
              value: _speakersAuxiliary.isEmpty ? null : _speakersAuxiliary,
              items: const [
                'Bishopric',
                'Elders Quorum',
                'Relief Society',
                'Sunday School',
                'Primary',
                'Ward Mission & Family History',
                'Stake leaders',
              ],
              onChanged: (v) =>
                  setState(() => _speakersAuxiliary = v ?? ''),
            ),
            SpeakerListEditor(
              speakers: _speakers,
              onChanged: (updated) =>
                  setState(() => _speakers = updated),
            ),
            _sectionHeader('Closing'),
            LabeledField(
                label: 'Benediction', controller: _benedictionCtrl),
            _sectionHeader('Acknowledgements'),
            LabeledField(
              label: 'Acknowledgement',
              controller: _acknowledgeCtrl,
              maxLines: 4,
              maxLength: 600,
              hint: 'Optional notes of thanks or recognition',
            ),
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
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _testPreview,
              icon: const Icon(Icons.science),
              label: const Text('Test Preview (fill with sample data)'),
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
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    )),
            const Divider(height: 8),
          ],
        ),
      );

  /// A dropdown that can also accept free-form text when [allowCustom] is true.
  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool allowCustom = false,
    TextEditingController? customController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        if (allowCustom && customController != null)
          // Free-text field with autocomplete suggestions
          Autocomplete<String>(
            initialValue: TextEditingValue(text: customController.text),
            optionsBuilder: (v) => items
                .where((i) =>
                    i.toLowerCase().contains(v.text.toLowerCase()))
                .toList(),
            onSelected: (s) {
              customController.text = s;
              onChanged(s);
            },
            fieldViewBuilder: (ctx, ctrl, node, onFieldSubmitted) =>
                TextFormField(
              controller: ctrl,
              focusNode: node,
              decoration: const InputDecoration(),
              onChanged: (v) {
                customController.text = v;
                onChanged(v);
              },
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: (value != null && items.contains(value)) ? value : null,
            items: items
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(),
            hint: const Text('Select…'),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
