// Widget tests for FinGoals

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/main.dart';

void main() {
  testWidgets('FinGoals app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const FinGoalsApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
