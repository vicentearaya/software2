import 'package:cleanpool_app/features/dashboard/widgets/dashboard_empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DashboardEmptyView muestra CTA y responde al tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardEmptyView(onAddPool: () => tapped = true),
      ),
    );

    expect(find.text('Sin piscina registrada'), findsOneWidget);
    expect(find.text('Agregar piscina'), findsWidgets);

    await tester.tap(find.text('Agregar piscina').last);
    await tester.pump();
    expect(tapped, true);
  });
}
