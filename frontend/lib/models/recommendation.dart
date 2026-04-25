/// lib/models/recommendation.dart
///
/// Modelo de datos para las recomendaciones químicas del backend.
/// Mapea directamente con la respuesta JSON de calculator.py

class RecommendationData {
  final String quimico;  // "producto" del backend
  final String formato;  // "instrucciones" del backend (cortado)
  final double dosisGramos;  // "cantidad" del backend
  final String instruccion;  // Instrucciones detalladas
  final String precauciones;  // Precauciones de seguridad

  const RecommendationData({
    required this.quimico,
    required this.formato,
    required this.dosisGramos,
    required this.instruccion,
    required this.precauciones,
  });

  /// Factory constructor para parsear desde JSON del backend
  /// Mapea las claves de calculator.py al modelo Dart
  factory RecommendationData.fromJson(Map<String, dynamic> json) {
    return RecommendationData(
      quimico: json['producto'] as String? ?? 'Desconocido',
      formato: json['unidad'] as String? ?? 'gr',  // "gr" (gramos)
      dosisGramos: (json['cantidad'] as num?)?.toDouble() ?? 0.0,  // "cantidad" de calculator.py
      instruccion: json['instrucciones'] as String? ?? '',
      precauciones: json.containsKey('precauciones') 
          ? json['precauciones'] as String? ?? ''
          : _getPrecaucionesDefault(json['producto'] as String? ?? ''),
    );
  }

  /// Obtiene precauciones por defecto según el tipo de químico
  static String _getPrecaucionesDefault(String producto) {
    if (producto.contains('Bisulfato') || producto.contains('pH')) {
      return 'Ácido débil. Usar guantes y gafas de protección. Evitar contacto con piel.';
    } else if (producto.contains('Cloro')) {
      return 'Oxidante fuerte. Mantener alejado de materia orgánica. Usar en área ventilada.';
    } else if (producto.contains('Carbonato')) {
      return 'Irritante. Usar guantes. Aplicar gradualmente en agua.';
    }
    return 'Seguir instrucciones del envase. Usar equipo de protección personal.';
  }

  /// Convierte el modelo a JSON (útil para debugging o persistencia)
  Map<String, dynamic> toJson() {
    return {
      'producto': quimico,
      'cantidad': dosisGramos,
      'unidad': formato,
      'instrucciones': instruccion,
      'precauciones': precauciones,
    };
  }

  /// Método toString para debugging
  @override
  String toString() => 'RecommendationData($quimico, ${dosisGramos}${formato})';
}
