import 'package:cleanpool_app/features/dashboard/widgets/pool_water_status_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildPanel(Map<String, dynamic> statusData) {
    return MaterialApp(
      home: Scaffold(
        body: PoolWaterStatusPanel(
          loading: false,
          manualOverride: statusData,
        ),
      ),
    );
  }

  testWidgets('muestra solo el aviso de pH aplicable en advertencia',
      (tester) async {
    await tester.pumpWidget(
      buildPanel({
        'estado': 'ADVERTENCIA',
        'parametros': {
          'ph': {'valor': 7.0, 'estado': 'BAJO'},
          'cloro': {'valor': 2.0, 'estado': 'OPTIMO'},
        },
      }),
    );

    expect(find.text('pH bajo'), findsOneWidget);
    expect(find.text('Cloro bajo'), findsNothing);
    expect(find.text('Cloro alto'), findsNothing);
  });

  testWidgets('muestra avisos críticos para pH y cloro cuando no es apta',
      (tester) async {
    await tester.pumpWidget(
      buildPanel({
        'estado': 'NO APTA',
        'parametros': {
          'ph': {'valor': 8.5, 'estado': 'ALTO'},
          'cloro': {'valor': 0.2, 'estado': 'BAJO'},
        },
      }),
    );

    expect(find.text('pH críticamente alto'), findsOneWidget);
    expect(find.text('Cloro críticamente bajo'), findsOneWidget);
  });

  testWidgets('no muestra avisos para estados distintos a advertencia o no apta',
      (tester) async {
    await tester.pumpWidget(
      buildPanel({
        'estado': 'REVISION',
        'parametros': {
          'ph': {'valor': 6.5, 'estado': 'BAJO'},
        },
      }),
    );

    expect(find.text('pH críticamente bajo'), findsNothing);
  });
}
