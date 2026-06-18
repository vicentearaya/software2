import 'dart:math' as math;

class PoolData {
  final String nombre;
  final double largo;
  final double ancho;
  final double profundidad;
  final bool esInterior;
  final bool tieneFiltro;
  final String forma; // rectangular, circular, oval, volumen_conocido
  final double? volumen; // para volumen_conocido

  const PoolData({
    required this.nombre,
    required this.largo,
    required this.ancho,
    required this.profundidad,
    required this.esInterior,
    required this.tieneFiltro,
    this.forma = 'rectangular',
    this.volumen,
  });

  double get volumenM3 {
    if (forma == 'volumen_conocido') {
      return volumen ?? 0.0;
    } else if (forma == 'circular') {
      final r = ancho / 2;
      return math.pi * r * r * profundidad;
    } else if (forma == 'oval') {
      return math.pi * (largo / 2) * (ancho / 2) * profundidad;
    } else {
      // rectangular
      return largo * ancho * profundidad;
    }
  }

  double get volumenLitros => volumenM3 * 1000;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'largo': largo,
        'ancho': ancho,
        'profundidad': profundidad,
        'esInterior': esInterior,
        'tieneFiltro': tieneFiltro,
        'forma': forma,
        'volumen': volumen,
      };

  factory PoolData.fromJson(Map<String, dynamic> json) {
    final largo = (json['largo'] as num?)?.toDouble() ?? 0.0;
    final ancho = (json['ancho'] as num?)?.toDouble() ?? 0.0;
    final profundidad = (json['profundidad'] as num?)?.toDouble() ?? 0.0;

    String forma = 'rectangular';
    if (json['forma'] != null) {
      forma = json['forma'] as String;
    } else {
      if (largo > 0 || ancho > 0 || profundidad > 0) {
        forma = 'rectangular';
      } else {
        forma = 'volumen_conocido';
      }
    }

    return PoolData(
      nombre: json['nombre'] as String? ?? '',
      largo: largo,
      ancho: ancho,
      profundidad: profundidad,
      esInterior: json['esInterior'] as bool? ?? json['tipo'] == 'interior',
      tieneFiltro: json['tieneFiltro'] as bool? ?? json['filtro'] as bool? ?? true,
      forma: forma,
      volumen: (json['volumen'] as num?)?.toDouble() ?? (json['volumen_m3'] as num?)?.toDouble(),
    );
  }
}

