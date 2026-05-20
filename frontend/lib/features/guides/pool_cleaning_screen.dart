import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class PoolCleaningScreen extends StatelessWidget {
  const PoolCleaningScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return _buildContent();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Limpieza de Piscina',
          style: GoogleFonts.syne(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      children: [
        _buildHerramientasSection(),
        const SizedBox(height: 14),
        _buildFrecuenciaSection(),
        const SizedBox(height: 14),
        _buildPasoAPasoSection(),
        const SizedBox(height: 14),
        _buildProTipsSection(),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Sección 1: Herramientas ──────────────────
  Widget _buildHerramientasSection() {
    final herramientas = [
      {
        'Herramienta': 'Saca-hojas (Red)',
        'Función': 'Recoger residuos flotantes.',
        'Uso': 'Hojas, insectos, flores.',
        'Icon': Icons.content_cut_rounded,
      },
      {
        'Herramienta': 'Cepillo de pared',
        'Función': 'Desprender algas y suciedad.',
        'Uso': 'Paredes, escalones y esquinas.',
        'Icon': Icons.brush_outlined,
      },
      {
        'Herramienta': 'Limpiafondos',
        'Función': 'Aspirar la suciedad del suelo.',
        'Uso': 'Arena, tierra, algas muertas.',
        'Icon': Icons.air_rounded,
      },
      {
        'Herramienta': 'Manguera flotante',
        'Función': 'Conectar limpiafondos a succión.',
        'Uso': 'Aspiración.',
        'Icon': Icons.cable_rounded,
      },
    ];

    return _buildCardContainer(
      title: '1. Herramientas Básicas',
      icon: Icons.construction_outlined,
      iconColor: const Color(0xFFE67E22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Se acoplan al mango telescópico para llegar a cualquier punto de la piscina.',
            style: GoogleFonts.interTight(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ...herramientas.map((h) => _ToolCard(
                name: h['Herramienta'] as String,
                function: h['Función'] as String,
                usage: h['Uso'] as String,
                icon: h['Icon'] as IconData,
                color: const Color(0xFFE67E22),
              )),
        ],
      ),
    );
  }

  // ── Sección 2: Frecuencia ────────────────────
  Widget _buildFrecuenciaSection() {
    final frecuencias = [
      {'Tarea': 'Recoger hojas', 'Verano': 'Diario', 'Resto': '2 veces / sem'},
      {'Tarea': 'Limpiar skimmer', 'Verano': 'Diario', 'Resto': 'Semanal'},
      {
        'Tarea': 'Cepillar paredes',
        'Verano': '1-2 veces / sem',
        'Resto': 'Cada 15 días'
      },
      {
        'Tarea': 'Aspirar fondo',
        'Verano': '1 vez / sem',
        'Resto': '1 vez / mes'
      },
      {
        'Tarea': 'Medir pH/Cloro',
        'Verano': 'Cada 2 días',
        'Resto': 'Semanal'
      },
    ];

    return _buildCardContainer(
      title: '2. Frecuencia de Limpieza',
      icon: Icons.calendar_month_outlined,
      iconColor: AppColors.primary,
      child: Column(
        children: [
          // Header de la tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'TAREA',
                    style: GoogleFonts.syne(
                      color: AppColors.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'VERANO',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.syne(
                      color: AppColors.statusWarning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'INVIERNO',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.syne(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...frecuencias.asMap().entries.map((entry) {
            final f = entry.value;
            final isEven = entry.key.isEven;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isEven
                    ? AppColors.surfaceElevated.withOpacity(0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      f['Tarea']!,
                      style: GoogleFonts.interTight(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f['Verano']!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.interTight(
                        color: AppColors.statusWarning,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f['Resto']!,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.interTight(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Sección 3: Paso a Paso ───────────────────
  Widget _buildPasoAPasoSection() {
    return _buildCardContainer(
      title: '3. El Paso a Paso',
      icon: Icons.format_list_numbered_rounded,
      iconColor: AppColors.accent,
      child: Column(
        children: [
          _buildStepItem(
            stepNumber: '1',
            title: 'Superficie y Skimmer',
            content:
                'Usa el saca-hojas para retirar todo lo que flote en el espejo de agua. Vacía el canastillo del skimmer para que la bomba no pierda fuerza de succión.',
          ),
          _buildStepConnector(),
          _buildStepItem(
            stepNumber: '2',
            title: 'Cepillado (Fundamental)',
            content:
                'Pasa el cepillo por paredes y borde de flotación. Esto desprende micro-algas para que el filtro las atrape o el limpiafondos las succione.',
          ),
          _buildStepConnector(),
          _buildStepItem(
            stepNumber: '3',
            title: 'Aspirar Fondo (Manguera)',
            content:
                '1. Conecta la manguera al limpiafondos y mételo al agua.\n2. Pon el otro extremo en un chorro de retorno hasta que deje de salir aire.\n3. Conéctalo a la boquilla de aspiración.\n4. Mueve lento y lineal para no levantar mugre.',
          ),
          _buildStepConnector(),
          _buildStepItem(
            stepNumber: '4',
            title: 'Limpiar Pre-filtro de Bomba',
            content:
                'Apaga la bomba, abre la tapa transparente y limpia el canastillo de hojas y suciedad atrapada.',
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 2,
          height: 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accent.withOpacity(0.3),
                AppColors.accent.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accent.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: GoogleFonts.syne(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: GoogleFonts.interTight(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sección 4: Pro Tips ──────────────────────
  Widget _buildProTipsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.statusGood.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statusGood.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.statusGood.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusGood.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_outline_rounded,
                    color: AppColors.statusGood, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                '4. Pro Tips',
                style: GoogleFonts.syne(
                  color: AppColors.statusGood,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProTipItem(
            title: '¿Mucha tierra?',
            content:
                'No aspires en modo Filtración, hazlo en modo Desagüe (Waste) para que la suciedad vaya directo a la calle.',
          ),
          const SizedBox(height: 12),
          _buildProTipItem(
            title: 'El orden importa',
            content:
                'Primero limpia la superficie, luego cepilla las paredes y al final aspira el fondo (la mugre caerá hacia abajo).',
          ),
          const SizedBox(height: 12),
          _buildProTipItem(
            title: 'Química final',
            content:
                'Mide niveles siempre que termines de limpiar y de usar agua nueva. pH ideal debe ser entre 7.2 y 7.6.',
          ),
        ],
      ),
    );
  }

  Widget _buildProTipItem({required String title, required String content}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.statusGood.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.check_rounded,
              color: AppColors.statusGood, size: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.syne(
                  color: AppColors.statusGood,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                content,
                style: GoogleFonts.interTight(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Card Container base ──────────────────────
  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withOpacity(0.2),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tarjeta de herramienta con hover
// ─────────────────────────────────────────────
class _ToolCard extends StatefulWidget {
  final String name;
  final String function;
  final String usage;
  final IconData icon;
  final Color color;

  const _ToolCard({
    required this.name,
    required this.function,
    required this.usage,
    required this.icon,
    required this.color,
  });

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.color.withOpacity(0.04)
              : AppColors.surfaceElevated.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? widget.color.withOpacity(0.25)
                : AppColors.border.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.color.withOpacity(0.2),
                ),
              ),
              child: Icon(widget.icon, color: widget.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.function,
                    style: GoogleFonts.interTight(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    'Uso: ${widget.usage}',
                    style: GoogleFonts.interTight(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
