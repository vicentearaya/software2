class PoolData {
  final String nombre;
  final double largo;
  final double ancho;
  final double profundidad;
  final bool esInterior;
  final bool tieneFiltro;

  const PoolData({
    required this.nombre,
    required this.largo,
    required this.ancho,
    required this.profundidad,
    required this.esInterior,
    required this.tieneFiltro,
  });

  double get volumenLitros => largo * ancho * profundidad * 1000;

  double get volumenM3 => largo * ancho * profundidad;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'largo': largo,
        'ancho': ancho,
        'profundidad': profundidad,
        'esInterior': esInterior,
        'tieneFiltro': tieneFiltro,
      };

  factory PoolData.fromJson(Map<String, dynamic> json) => PoolData(
        nombre: json['nombre'] as String,
        largo: (json['largo'] as num).toDouble(),
        ancho: (json['ancho'] as num).toDouble(),
        profundidad: (json['profundidad'] as num).toDouble(),
        esInterior: json['esInterior'] as bool,
        tieneFiltro: json['tieneFiltro'] as bool,
      );
}
