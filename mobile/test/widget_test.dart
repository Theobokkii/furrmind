import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furrmind/widgets/confidence_bar.dart';

void main() {
  testWidgets('ConfidenceBar renders percentage correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConfidenceBar(confidence: 0.85))),
    );

    expect(find.text('85%'), findsOneWidget);
  });
}
