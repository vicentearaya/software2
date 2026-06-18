import 'package:flutter_test/flutter_test.dart';
import 'package:cleanpool_app/features/dashboard/pool_data.dart';

void main() {
  group('PoolData Volume Calculations', () {
    test('rectangular pool volume calculation', () {
      const pool = PoolData(
        nombre: 'Rectangular Test',
        largo: 8.0,
        ancho: 4.0,
        profundidad: 1.5,
        esInterior: false,
        tieneFiltro: true,
        forma: 'rectangular',
      );

      expect(pool.volumenM3, 8.0 * 4.0 * 1.5); // 48.0 m³
      expect(pool.volumenLitros, 48000.0); // 48,000 L
    });

    test('circular pool volume calculation', () {
      const pool = PoolData(
        nombre: 'Circular Test',
        largo: 0.0,
        ancho: 4.0, // diameter
        profundidad: 1.5,
        esInterior: false,
        tieneFiltro: true,
        forma: 'circular',
      );

      // pi * r^2 * depth = pi * 2^2 * 1.5 = pi * 6 approx 18.8495
      final expectedM3 = 3.141592653589793 * 2.0 * 2.0 * 1.5;
      expect(pool.volumenM3, closeTo(expectedM3, 0.0001));
      expect(pool.volumenLitros, closeTo(expectedM3 * 1000, 0.1));
    });

    test('oval pool volume calculation', () {
      const pool = PoolData(
        nombre: 'Oval Test',
        largo: 8.0, // max length
        ancho: 4.0, // max width
        profundidad: 1.5,
        esInterior: false,
        tieneFiltro: true,
        forma: 'oval',
      );

      // pi * (largo/2) * (ancho/2) * depth = pi * 4 * 2 * 1.5 = pi * 12 approx 37.6991
      final expectedM3 = 3.141592653589793 * 4.0 * 2.0 * 1.5;
      expect(pool.volumenM3, closeTo(expectedM3, 0.0001));
    });

    test('known volume pool volume calculation', () {
      const pool = PoolData(
        nombre: 'Known Volume Test',
        largo: 0.0,
        ancho: 0.0,
        profundidad: 0.0,
        esInterior: false,
        tieneFiltro: true,
        forma: 'volumen_conocido',
        volumen: 25.5,
      );

      expect(pool.volumenM3, 25.5);
      expect(pool.volumenLitros, 25500.0);
    });
  });

  group('PoolData JSON Serialization and Migration', () {
    test('fromJson migration with dimensions (no shape in json)', () {
      final json = {
        'nombre': 'Legacy Rectangular',
        'largo': 6.0,
        'ancho': 3.0,
        'profundidad': 1.2,
        'esInterior': true,
        'tieneFiltro': false,
      };

      final pool = PoolData.fromJson(json);
      expect(pool.forma, 'rectangular');
      expect(pool.volumenM3, 6.0 * 3.0 * 1.2);
    });

    test('fromJson migration with zero dimensions (no shape in json)', () {
      final json = {
        'nombre': 'Legacy Known Volume',
        'largo': 0.0,
        'ancho': 0.0,
        'profundidad': 0.0,
        'volumen': 15.0,
        'tipo': 'exterior',
        'filtro': true,
      };

      final pool = PoolData.fromJson(json);
      expect(pool.forma, 'volumen_conocido');
      expect(pool.volumenM3, 15.0);
      expect(pool.esInterior, false);
      expect(pool.tieneFiltro, true);
    });

    test('toJson and fromJson full roundtrip', () {
      const pool = PoolData(
        nombre: 'Roundtrip Oval',
        largo: 7.0,
        ancho: 3.5,
        profundidad: 1.4,
        esInterior: true,
        tieneFiltro: true,
        forma: 'oval',
      );

      final json = pool.toJson();
      final pool2 = PoolData.fromJson(json);

      expect(pool2.nombre, pool.nombre);
      expect(pool2.largo, pool.largo);
      expect(pool2.ancho, pool.ancho);
      expect(pool2.profundidad, pool.profundidad);
      expect(pool2.esInterior, pool.esInterior);
      expect(pool2.tieneFiltro, pool.tieneFiltro);
      expect(pool2.forma, pool.forma);
      expect(pool2.volumenM3, pool.volumenM3);
    });
  });
}
