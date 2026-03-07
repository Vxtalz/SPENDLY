import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spendly/main.dart';

void main() {
  testWidgets('Spendly app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SpendlyApp());

    // App title in AppBar when AuthPage is shown.
    expect(find.text('Spendly'), findsWidgets);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
