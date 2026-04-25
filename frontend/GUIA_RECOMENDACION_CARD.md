/// GUÍA DE INTEGRACIÓN — RecommendationCard
///
/// Esta guía explica cómo integrar el Widget RecommendationCard
/// en tu aplicación Flutter CleanPool.

/// ============================================================================
/// 1. ESTRUCTURA DE ARCHIVOS CREADOS
/// ============================================================================
///
/// lib/
///   ├── models/
///   │   └── recommendation.dart          ← Modelo de datos
///   └── shared/widgets/
///       ├── recommendation_card.dart     ← Widget principal
///       └── recommendation_card_example.dart  ← Ejemplo de uso

/// ============================================================================
/// 2. IMPORTACIONES NECESARIAS
/// ============================================================================
///
/// En el archivo donde quieras usar RecommendationCard:
///
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'path/to/models/recommendation.dart';
/// import 'path/to/shared/widgets/recommendation_card.dart';
/// ```

/// ============================================================================
/// 3. CASOS DE USO
/// ============================================================================

/// CASO A: Parsear JSON del backend y mostrar en un ListView
/// ```dart
/// class MyPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     // Asumiendo que tienes una respuesta del backend
///     final jsonFromBackend = {
///       'quimico': 'Carbonato de Sodio (Soda Ash)',
///       'formato': 'polvo',
///       'dosis_gramos': 2200.0,
///       'instruccion': 'Disolver en agua...',
///       'precauciones': 'Usar guantes...',
///     };
///     
///     final recommendation = RecommendationData.fromJson(jsonFromBackend);
///     
///     return RecommendationCard(
///       recommendation: recommendation,
///       onApplied: () {
///         print('Tratamiento aplicado');
///         // Opcional: registrar en backend que fue aplicado
///       },
///       onDismiss: () {
///         print('Recomendación descartada');
///       },
///     );
///   }
/// }
/// ```

/// CASO B: Mostrar múltiples recomendaciones en una lista
/// ```dart
/// class TreatmentsPage extends StatefulWidget {
///   @override
///   State<TreatmentsPage> createState() => _TreatmentsPageState();
/// }
///
/// class _TreatmentsPageState extends State<TreatmentsPage> {
///   late List<RecommendationData> recommendations = [];
///
///   @override
///   void initState() {
///     super.initState();
///     _loadRecommendations();
///   }
///
///   Future<void> _loadRecommendations() async {
///     // Aquí llamarías a tu servicio API
///     // final response = await apiService.getRecommendations(poolId);
///     // final data = (response as List)
///     //   .map((item) => RecommendationData.fromJson(item))
///     //   .toList();
///     // setState(() => recommendations = data);
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ListView.builder(
///       itemCount: recommendations.length,
///       itemBuilder: (context, index) {
///         return RecommendationCard(
///           recommendation: recommendations[index],
///           onApplied: () {
///             // Registrar en backend
///             // await apiService.markAsApplied(recommendations[index].id);
///             // Remover de la lista
///             setState(() => recommendations.removeAt(index));
///           },
///           onDismiss: () {
///             setState(() => recommendations.removeAt(index));
///           },
///         );
///       },
///     );
///   }
/// }
/// ```

/// ============================================================================
/// 4. CARACTERÍSTICAS DEL WIDGET
/// ============================================================================
///
/// ✅ Responsivo: Se adapta a pantallas móviles, tablets y desktop
/// ✅ Animado: Desvanecimiento suave al presionar "Aplicado"
/// ✅ Iconografía Inteligente: Detecta el tipo de químico y muestra icono apropiado
/// ✅ Theme-aware: Usa colores del tema actual (Material Design 3 compatible)
/// ✅ Estado Local: Gestión simple con StatefulWidget (sin Provider/Riverpod necesario)
/// ✅ Precauciones Destacadas: Sección con ícono de advertencia y color ámbar
/// ✅ Accesibilidad: Textos y contrastes adecuados

/// ============================================================================
/// 5. CUSTOMIZACIÓN
/// ============================================================================
///
/// El widget usa Theme.of(context) para colores, así que puedes
/// personalizarlo modificando tu ThemeData principal:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     useMaterial3: true,
///     colorScheme: ColorScheme.fromSeed(
///       seedColor: Colors.blue,
///     ),
///   ),
///   home: MyApp(),
/// )
/// ```

/// ============================================================================
/// 6. MONITOREO DE CAMBIOS DE ESTADO
/// ============================================================================
///
/// El widget oculta la tarjeta localmente al presionar "Aplicado".
/// Si necesitas sincronizar con backend o estado global para Hito 3:
///
/// 1. Captura el evento en onApplied
/// 2. Llama a tu API para registrar la acción
/// 3. Actualiza el estado global (Provider/Riverpod)
/// 4. El ListView se reconstruirá automáticamente
///
/// Ejemplo con Provider (Hito 3):
/// ```dart
/// onApplied: () async {
///   await ref.read(treatmentsProvider.notifier)
///     .markAsApplied(recommendation.id);
///   // ListView se reconstruye automáticamente
/// }
/// ```

/// ============================================================================
/// 7. PRUEBAS
/// ============================================================================
///
/// Para ejecutar el ejemplo:
/// ```bash
/// flutter run --target lib/shared/widgets/recommendation_card_example.dart
/// ```
///
/// O crea una ruta temporal en main.dart:
/// ```dart
/// home: RecommendationCardExample(),  // Durante testing
/// ```

/// ============================================================================
/// 8. PRÓXIMOS PASOS (HITO 3)
/// ============================================================================
///
/// - [ ] Integrar con Provider o Riverpod para estado global
/// - [ ] Agregar persistencia local (sqflite o Hive)
/// - [ ] Conectar con API para registrar acciones de usuario
/// - [ ] Agregar animaciones más complejas (slide, rotate, etc.)
/// - [ ] Tests unitarios y widget tests
