import 'package:flutter/material.dart';

class ResultSection extends StatelessWidget {
  final String title;
  final String content;

  const ResultSection({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            content,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: cs.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
