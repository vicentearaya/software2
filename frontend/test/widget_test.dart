import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cleanpool_app/core/constants/app_strings.dart';
import 'package:cleanpool_app/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await RiveNative.init();
  });

  testWidgets('App starts without crashing smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const CleanPoolApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text(AppStrings.welcomeHeadline), findsOneWidget);
  });
}
