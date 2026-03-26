/// lib/shared/widgets/recommendation_card_example.dart
///
/// Ejemplo de uso del RecommendationCard.
/// Útil para testing y demostración.

import 'package:flutter/material.dart';
import '../../models/recommendation.dart';
import 'recommendation_card.dart';

class RecommendationCardExample extends StatefulWidget {
  const RecommendationCardExample({Key? key}) : super(key: key);

  @override
  State<RecommendationCardExample> createState() =>
      _RecommendationCardExampleState();
}

class _RecommendationCardExampleState extends State<RecommendationCardExample> {
  /// Lista de recomendaciones de ejemplo
  late List<RecommendationData> recommendations;

  @override
  void initState() {
    super.initState();
    recommendations = [
      // Ejemplo 1: Carbonato de Sodio (pH bajo)
      RecommendationData(
        quimico: 'Carbonato de Sodio (Soda Ash)',
        formato: 'polvo',
        dosisGramos: 2200.0,
        instruccion:
            'Disolver 2200g de Carbonato de Sodio en agua antes de aplicar. Mezclar bien en un balde. Distribuir uniformemente por toda la piscina con la bomba de circulación activa.',
        precauciones: 'Usar guantes. Evitar inhalación de polvo. Usar gafas de protección.',
      ),
      // Ejemplo 2: Bisulfato de Sodio (pH alto)
      RecommendationData(
        quimico: 'Bisulfato de Sodio (pH Down)',
        formato: 'polvo',
        dosisGramos: 4500.0,
        instruccion:
            'Disolver 4500g de Bisulfato en agua. Aplicar lentamente alrededor del perímetro de la piscina. Esperara 30 minutos antes de re-verificar pH.',
        precauciones:
            'Ácido débil. Usar guantes y gafas. No mezclar con otros químicos.',
      ),
      // Ejemplo 3: Cloro granulado (cloro bajo)
      RecommendationData(
        quimico: 'Cloro granulado (Hipoclorito de Calcio 65%)',
        formato: 'gránulos',
        dosisGramos: 115384.6,
        instruccion:
            'Agregar gradualmente al skimmer de la piscina, 10-15 minutos por kg. Activar circulación en modo alto. Esperar 2-4 horas antes de entrar.',
        precauciones:
            'Producto cáustico. NO mezclar con otros químicos. Mantener en lugar seco. Usar guantes siempre.',
      ),
    ];
  }

  /// Elimina una recomendación de la lista
  void _removeRecommendation(int index) {
    setState(() {
      recommendations.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recomendación descartada'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            // Podría re-agregar la recomendación si se guarda antes
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recomendaciones de Tratamiento'),
        centerTitle: true,
      ),
      body: recommendations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Todos los tratamientos aplicados',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'La piscina está en condiciones óptimas',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final recommendation = recommendations[index];
                return RecommendationCard(
                  recommendation: recommendation,
                  onApplied: () {
                    print('✓ Tratamiento aplicado: ${recommendation.quimico}');
                    // Aquí iría la lógica para registrar que se aplicó
                    // (por ej. enviar al backend, guardar en local storage, etc.)
                  },
                  onDismiss: () {
                    _removeRecommendation(index);
                  },
                );
              },
            ),
    );
  }
}
