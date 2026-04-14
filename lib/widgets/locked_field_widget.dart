// widgets/locked_field_widget.dart
// A read-only field styled with a blue tint and lock icon.
// Used for the Presiding field in Bishopric and Ward Council forms.

import 'package:flutter/material.dart';

class LockedFieldWidget extends StatelessWidget {
  final String label;
  final String value;

  const LockedFieldWidget({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: value.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
              Icon(Icons.lock, size: 16, color: Colors.blue.shade400),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
