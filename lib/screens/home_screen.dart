// screens/home_screen.dart
// Main landing screen — Programs + History + Management + Rules.

import 'package:flutter/material.dart';
import 'sacrament/sacrament_form_screen.dart';
import 'bishopric/bishopric_form_screen.dart';
import 'ward_council/ward_council_form_screen.dart';
import 'history/history_screen.dart';
import 'admin/musician_admin_screen.dart';
import 'admin/conductor_admin_screen.dart';
import 'admin/hymn_admin_screen.dart';
import 'admin/handbook_admin_screen.dart';
import 'admin/auxiliary_admin_screen.dart';
import 'admin/seed_defaults_screen.dart';
import 'rules/rules_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Church Program Generator'),
        backgroundColor: const Color(0xFF1B4F8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              color: const Color(0xFF1B4F8A),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/P3_LOGO.png',
                      height: 64,
                      width: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a Program',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a meeting type below',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const _SectionLabel(label: 'Programs'),
            const SizedBox(height: 8),

            // Program type tiles
            _NavTile(
              icon: Icons.menu_book,
              title: 'Sacrament Meeting',
              subtitle: 'Sunday sacrament program with hymns & speakers',
              color: const Color(0xFF2E7D32),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SacramentFormScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _NavTile(
              icon: Icons.groups,
              title: 'Ward Council',
              subtitle: 'Agenda for ward council meeting',
              color: const Color(0xFF6A1B9A),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const WardCouncilFormScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _NavTile(
              icon: Icons.business_center,
              title: 'Bishopric Meeting',
              subtitle: 'Agenda for bishopric meeting',
              color: const Color(0xFFC62828),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BishopricFormScreen()),
              ),
            ),

            const SizedBox(height: 20),
            const _SectionLabel(label: 'History & Management'),
            const SizedBox(height: 8),

            _NavTile(
              icon: Icons.history,
              title: 'Program History',
              subtitle: 'View, load, or delete saved programs',
              color: const Color(0xFF37474F),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _NavTile(
              icon: Icons.music_note,
              title: 'Musician Management',
              subtitle: 'Add / edit choristers and pianists',
              color: const Color(0xFF00695C),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MusicianAdminScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _NavTile(
              icon: Icons.person,
              title: 'Conductor Management',
              subtitle: 'Add / edit conductors per meeting type',
              color: const Color(0xFF4527A0),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ConductorAdminScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _NavTile(
              icon: Icons.groups,
              title: 'Auxiliary Management',
              subtitle: 'Add / edit / remove auxiliaries',
              color: const Color(0xFF00838F),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AuxiliaryAdminScreen()),
              ),
            ),

            const SizedBox(height: 20),
            const _SectionLabel(label: 'Hymns & Speakers'),
            const SizedBox(height: 8),

            _NavTile(
              icon: Icons.music_note,
              title: 'Hymns',
              subtitle: 'Add / edit hymns used in sacrament meeting',
              color: const Color(0xFF1565C0),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HymnAdminScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _NavTile(
              icon: Icons.menu_book,
              title: 'Handbook Readings',
              subtitle: 'Manage ward council handbook reading list',
              color: const Color(0xFF6A1B9A),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HandbookAdminScreen()),
              ),
            ),

            const SizedBox(height: 20),
            const _SectionLabel(label: 'Setup'),
            const SizedBox(height: 8),

            _NavTile(
              icon: Icons.upload_outlined,
              title: 'Default Data Setup',
              subtitle: 'Pre-load ward members, bishopric, musicians & auxiliaries',
              color: const Color(0xFF37474F),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SeedDefaultsScreen()),
              ),
            ),

            const SizedBox(height: 20),
            const _SectionLabel(label: 'Automation Rules'),
            const SizedBox(height: 8),

            _NavTile(
              icon: Icons.tune,
              title: 'Automation Rules',
              subtitle:
                  'Ward settings, schedules, rotation & acknowledgement',
              color: const Color(0xFFE65100),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RulesScreen()),
              ),
            ),

            const SizedBox(height: 24),

            // Footer / app info
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Divider(color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    '© 2025–2026 Pasay 3rd Ward',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    'Church Program Generator • All rights reserved',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Developed by Russel D.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A subtle section divider label.
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              color: Colors.grey[600],
            ),
      );
}

/// Tappable navigation card.
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
                    Text(subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
