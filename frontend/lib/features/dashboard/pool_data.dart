import '../../core/utils/pool_volume_calculator.dart';

class PoolData {
  final String nombre;
  final double largo;
  final double ancho;
  final double profundidad;
  final bool esInterior;
  final bool tieneFiltro;
  final String forma; // rectangular, circular, oval, volumen_conocido
  final double? volumen; // para volumen_conocido u override manual
  final String volumenOrigen; // calculado | manual
  final double? volumenEstimado; // volumen calculado para auditoría

  const PoolData({
    required this.nombre,
    required this.largo,
    required this.ancho,
    required this.profundidad,
    required this.esInterior,
    required this.tieneFiltro,
    this.forma = 'rectangular',
    this.volumen,
    this.volumenOrigen = 'calculado',
    this.volumenEstimado,
  });

  Map<String, double> get dimensiones {
    if (forma == 'volumen_conocido') {
      return {'volumen': volumen ?? 0.0};
    } else if (forma == 'circular') {
      return {
        'diametro': ancho,
        'profundidad': profundidad,
      };
    } else if (forma == 'oval') {
      return {
        'eje_largo': largo,
        'eje_corto': ancho,
        'profundidad': profundidad,
      };
    } else {
      // rectangular
      return {
        'largo': largo,
        'ancho': ancho,
        'profundidad': profundidad,
      };
    }
  }

  double get volumenM3 {
    if (volumenOrigen == 'manual') {
      return volumen ?? 0.0;
    }
    return PoolVolumeCalculator.calculateVolume(
      forma: forma,
      dimensiones: dimensiones,
    );
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
        'dimensiones': dimensiones,
        'volumen_origen': volumenOrigen,
        'volumen_estimado': volumenEstimado,
      };

  factory PoolData.fromJson(Map<String, dynamic> json) {
    String forma = 'rectangular';
    if (json['forma'] != null) {
      forma = json['forma'] as String;
    }

    double largo = 0.0;
    double ancho = 0.0;
    double profundidad = 0.0;
    double? volumen;

    if (json['dimensiones'] != null && json['dimensiones'] is Map) {
      final dims = Map<String, dynamic>.from(json['dimensiones'] as Map);
      if (forma == 'circular') {
        ancho = (dims['diametro'] as num?)?.toDouble() ?? 0.0;
        profundidad = (dims['profundidad'] as num?)?.toDouble() ?? 0.0;
      } else if (forma == 'oval') {
        largo = (dims['eje_largo'] as num?)?.toDouble() ?? 0.0;
        ancho = (dims['eje_corto'] as num?)?.toDouble() ?? 0.0;
        profundidad = (dims['profundidad'] as num?)?.toDouble() ?? 0.0;
      } else if (forma == 'volumen_conocido') {
        volumen = (dims['volumen'] as num?)?.toDouble();
      } else {
        largo = (dims['largo'] as num?)?.toDouble() ?? 0.0;
        ancho = (dims['ancho'] as num?)?.toDouble() ?? 0.0;
        profundidad = (dims['profundidad'] as num?)?.toDouble() ?? 0.0;
      }
    } else {
      largo = (json['largo'] as num?)?.toDouble() ?? 0.0;
      ancho = (json['ancho'] as num?)?.toDouble() ?? 0.0;
      profundidad = (json['profundidad'] as num?)?.toDouble() ?? 0.0;
      volumen = (json['volumen'] as num?)?.toDouble() ?? (json['volumen_m3'] as num?)?.toDouble();
      
      // Fallback detection of forma if none provided
      if (json['forma'] == null) {
        if (largo > 0 || ancho > 0 || profundidad > 0) {
          forma = 'rectangular';
        } else {
          forma = 'volumen_conocido';
        }
      }
    }

    final volumenOrigen = json['volumen_origen'] as String? ?? json['volumenOrigen'] as String? ?? 'calculado';
    final volumenEstimado = (json['volumen_estimado'] as num?)?.toDouble() ?? (json['volumenEstimado'] as num?)?.toDouble();

    return PoolData(
      nombre: json['nombre'] as String? ?? '',
      largo: largo,
      ancho: ancho,
      profundidad: profundidad,
      esInterior: json['esInterior'] as bool? ?? json['tipo'] == 'interior',
      tieneFiltro: json['tieneFiltro'] as bool? ?? json['filtro'] as bool? ?? true,
      forma: forma,
      volumen: volumen ?? ((forma == 'volumen_conocido' || volumenOrigen == 'manual') ? (json['volumen'] as num?)?.toDouble() : null),
      volumenOrigen: volumenOrigen,
      volumenEstimado: volumenEstimado,
    );
  }
}

