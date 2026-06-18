import 'package:flutter/material.dart';
import '../formatters.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? verdictLabel;
  final String? verdictColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.verdictLabel,
    this.verdictColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = Color(verdictColorInt(verdictColor));
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        border: Border.all(color: c.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF555555), letterSpacing: 1.2, fontFamily: 'monospace')),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w700, color: c, height: 1)),
          if (verdictLabel != null) ...[
            const SizedBox(height: 5),
            Text(verdictLabel!, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: c, letterSpacing: 0.5)),
          ],
        ],
      ),
    );
  }
}
