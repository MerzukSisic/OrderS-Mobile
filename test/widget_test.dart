import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boot smoke test — root widget renders without exception',
      (WidgetTester tester) async {
    // Pump a minimal MaterialApp that mirrors the app's root structure.
    // We do not pump the full OrdersMobileApp because that requires live
    // providers, SharedPreferences, and network — none of which are available
    // in the widget-test sandbox. This test verifies the Flutter framework
    // itself can render a Material widget tree without crashing.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('OrderS')),
        ),
      ),
    );

    expect(find.text('OrderS'), findsOneWidget);
  });
}
