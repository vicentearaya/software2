import 'dart:math' as math;

class PoolVolumeCalculator {
  static const double pi = math.pi;

  /// Calculates the pool volume in cubic meters (m³) based on shape and dimensions.
  static double calculateVolume({
    required String forma,
    required Map<String, double> dimensiones,
  }) {
    if (forma == 'volumen_conocido') {
      return dimensiones['volumen'] ?? 0.0;
    } else if (forma == 'circular') {
      final diametro = dimensiones['diametro'] ?? 0.0;
      final profundidad = dimensiones['profundidad'] ?? 0.0;
      final radio = diametro / 2.0;
      return pi * radio * radio * profundidad;
    } else if (forma == 'oval') {
      final ejeLargo = dimensiones['eje_largo'] ?? 0.0;
      final ejeCorto = dimensiones['eje_corto'] ?? 0.0;
      final profundidad = dimensiones['profundidad'] ?? 0.0;
      return pi * (ejeLargo / 2.0) * (ejeCorto / 2.0) * profundidad;
    } else if (forma == 'rectangular') {
      final largo = dimensiones['largo'] ?? 0.0;
      final ancho = dimensiones['ancho'] ?? 0.0;
      final profundidad = dimensiones['profundidad'] ?? 0.0;
      return largo * ancho * profundidad;
    } else {
      throw ArgumentError('Forma no soportada: $forma');
    }
  }
}
