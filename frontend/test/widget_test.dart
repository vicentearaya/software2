import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cleanpool_app/main.dart';

void main() {
  testWidgets('App starts without crashing smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CleanPoolApp());

    // Verify it builds without error.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
