import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: Color(0xFF555555),
        fontFamily: 'monospace',
      ),
    );
  }
}
