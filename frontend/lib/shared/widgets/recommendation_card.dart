/// lib/shared/widgets/recommendation_card.dart
///
/// Widget reutilizable para mostrar tarjetas de recomendación química.
/// Muestra: químico, dosis, instrucciones y precauciones.
/// Incluye botón "Aplicado" que oculta temporalmente la tarjeta.

import 'package:flutter/material.dart';
import '../../models/recommendation.dart';

class RecommendationCard extends StatefulWidget {
  /// Datos de la recomendación a mostrar
  final RecommendationData recommendation;

  /// Callback opcional cuando el usuario presiona "Aplicado"
  final VoidCallback? onApplied;

  /// Callback opcional para eliminar permanentemente
  final VoidCallback? onDismiss;

  const RecommendationCard({
    Key? key,
    required this.recommendation,
    this.onApplied,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard>
    with SingleTickerProviderStateMixin {
  /// Controla si la tarjeta está visible
  late bool _isVisible = true;

  /// Controlador de animación para el desvanecimiento
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Oculta la tarjeta con animación
  void _hideCard() {
    _animationController.forward().then((_) {
      setState(() => _isVisible = false);
    });
  }

  /// Maneja el clic del botón "Aplicado"
  void _handleApplied() {
    _hideCard();
    widget.onApplied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Si la tarjeta fue ocultada, retorna un SizedBox vacío
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 24.0,
          vertical: 12.0,
        ),
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              // Gradiente sutil de fondo
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.95),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========== ENCABEZADO: Nombre del Químico + Formato ==========
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icono representativo
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(
                          _getIconForChemical(widget.recommendation.quimico),
                          color: theme.colorScheme.primary,
                          size: 24.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      // Nombre del químico y formato
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.recommendation.quimico,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.recommendation.formato.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Formato: ${widget.recommendation.formato}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // ========== DOSIS: Destacada en Negrita y Tamaño Mayor ==========
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 10.0,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderLeft: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 4.0,
                      ),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          widget.recommendation.dosisGramos.toStringAsFixed(1),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          'gramos',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // ========== INSTRUCCIONES ==========
                  if (widget.recommendation.instruccion.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instrucciones',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          widget.recommendation.instruccion,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                      ],
                    ),

                  // ========== PRECAUCIONES (con ícono de advertencia) ==========
                  if (widget.recommendation.precauciones.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber[700],
                            size: 20.0,
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Text(
                              widget.recommendation.precauciones,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber[900],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16.0),

                  // ========== BOTONES DE ACCIÓN ==========
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Botón secundario (opcional): Descartar
                      if (widget.onDismiss != null)
                        OutlinedButton(
                          onPressed: widget.onDismiss,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface
                                .withOpacity(0.6),
                          ),
                          child: const Text('Descartar'),
                        ),
                      if (widget.onDismiss != null) const SizedBox(width: 8.0),
                      // Botón principal: Aplicado
                      ElevatedButton.icon(
                        onPressed: _handleApplied,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Aplicado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 12.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Retorna un ícono basado en el nome del químico
  IconData _getIconForChemical(String quimico) {
    final lower = quimico.toLowerCase();

    if (lower.contains('cloro')) {
      return Icons.local_drink_rounded; // 💧
    } else if (lower.contains('ph')) {
      return Icons.science_rounded; // 🧪
    } else if (lower.contains('carbonato') || lower.contains('soda')) {
      return Icons.bubble_chart_rounded; // 🫧
    } else if (lower.contains('bisulfato')) {
      return Icons.warning_rounded; // ⚠️
    } else {
      return Icons.water_drop_rounded; // 💧 default
    }
  }
}
