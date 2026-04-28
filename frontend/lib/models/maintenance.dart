/// lib/models/maintenance.dart
///
/// Modelo de datos para los registros de mantenimiento.
/// Mapea con la respuesta de /mantenciones del backend.

class Maintenance {
  final String idPiscina;
  final List<String> productos;
  final List<String> cantidades;
  final DateTime fecha;
  final String username;
  final double? ph;
  final double? cloro;
  final double? temperatura;

  Maintenance({
    required this.idPiscina,
    required this.productos,
    required this.cantidades,
    required this.fecha,
    required this.username,
    this.ph,
    this.cloro,
    this.temperatura,
  });

  /// Factory para parsear desde JSON del backend.
  factory Maintenance.fromJson(Map<String, dynamic> json) {
    return Maintenance(
      idPiscina: json['id_piscina'] as String? ?? 'Desconocido',
      productos: List<String>.from(json['productos'] ?? []),
      cantidades: List<String>.from(json['cantidades'] ?? []),
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : DateTime.now(),
      username: json['username'] as String? ?? '',
      ph: (json['ph'] as num?)?.toDouble(),
      cloro: (json['cloro'] as num?)?.toDouble(),
      temperatura: (json['temperatura'] as num?)?.toDouble(),
    );
  }

  /// Muestra los sensores registrados (ph, cloro, temp) en formato legible.
  String get parametrosResumen {
    final List<String> partes = [];
    if (ph != null) partes.add('pH: ${ph!.toStringAsFixed(1)}');
    if (cloro != null) partes.add('Cl: ${cloro!.toStringAsFixed(1)} ppm');
    if (temperatura != null) partes.add('T: ${temperatura!.toStringAsFixed(1)}°C');
    return partes.isEmpty ? 'Sin lecturas' : partes.join('  •  ');
  }

  /// Método útil para mostrar productos y cantidades juntos.
  String get productosResumen {
    if (productos.isEmpty) return 'Sin productos';
    List<String> combined = [];
    for (int i = 0; i < productos.length; i++) {
      String cant = i < cantidades.length ? cantidades[i] : '';
      combined.add('${productos[i]} ($cant)');
    }
    return combined.join(', ');
  }
}
