// widgets/speaker_cycle_badge.dart
// Colored badge that shows the speaker type label for the current Sunday.
// Displayed above the Speakers section on the Sacrament form.

import 'package:flutter/material.dart';

class SpeakerCycleBadge extends StatelessWidget {
  final String label;

  const SpeakerCycleBadge({super.key, required this.label});

  static Color _colorForLabel(String label) {
    if (label.contains('Testimony')) return const Color(0xFF1B5E20);
    if (label.contains('Stake')) return const Color(0xFF0D47A1);
    if (label.contains('Relief Society')) return const Color(0xFF4A148C);
    if (label.contains('Elders Quorum')) return const Color(0xFF1565C0);
    if (label.contains('Ward Mission')) return const Color(0xFF1A237E);
    if (label.contains('Sunday School')) return const Color(0xFFE65100);
    if (label.contains('Primary')) return const Color(0xFFBF360C);
    if (label.contains('Youth')) return const Color(0xFF880E4F);
    if (label.contains('Bishopric')) return const Color(0xFF37474F);
    return const Color(0xFF2C5282);
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForLabel(label);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Chip(
          backgroundColor: color,
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          avatar: const Icon(Icons.info_outline, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
