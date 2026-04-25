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

  Maintenance({
    required this.idPiscina,
    required this.productos,
    required this.cantidades,
    required this.fecha,
    required this.username,
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
    );
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
