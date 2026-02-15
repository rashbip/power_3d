import 'package:flutter_test/flutter_test.dart';
import 'package:power3d/power3d.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Power3D widget smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Power3D())));

    // Verify that the Power3D widget is present.
    expect(find.byType(Power3D), findsOneWidget);
  });
}
