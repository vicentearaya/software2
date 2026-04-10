import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class PoolCleaningScreen extends StatelessWidget {
  const PoolCleaningScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          _buildHerramientasSection(),
          const SizedBox(height: 24),
          _buildFrecuenciaSection(),
          const SizedBox(height: 24),
          _buildPasoAPasoSection(),
          const SizedBox(height: 24),
          _buildProTipsSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHerramientasSection() {
    final herramientas = [
      {
        'Herramienta': 'Saca-hojas (Red)',
        'Función': 'Recoger residuos flotantes.',
        'Uso': 'Hojas, insectos, flores.',
        'Icon': Icons.catching_pokemon_outlined,
      },
      {
        'Herramienta': 'Cepillo de pared',
        'Función': 'Desprender algas y suciedad.',
        'Uso': 'Paredes, escalones y esquinas.',
        'Icon': Icons.imagesearch_roller_outlined,
      },
      {
        'Herramienta': 'Limpiafondos',
        'Función': 'Aspirar la suciedad del suelo.',
        'Uso': 'Arena, tierra, algas muertas.',
        'Icon': Icons.cleaning_services_outlined,
      },
      {
        'Herramienta': 'Manguera flotante',
        'Función': 'Conectar limpiafondos a succión.',
        'Uso': 'Aspiración.',
        'Icon': Icons.linear_scale,
      },
    ];

    return _buildCardContainer(
      title: '1. Herramientas Básicas',
      icon: Icons.handyman_outlined,
      iconColor: const Color(0xFFE67E22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Se acoplan al mango telescópico para llegar a cualquier punto de la piscina.',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ...herramientas.map((h) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE67E22).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(h['Icon'] as IconData,
                          color: const Color(0xFFE67E22), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h['Herramienta'] as String,
                            style: GoogleFonts.syne(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Función: ${h['Función']}',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Uso: ${h['Uso']}',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFrecuenciaSection() {
    final frecuencias = [
      {
        'Tarea': 'Recoger hojas',
        'Verano': 'Diario',
        'Resto': '2 veces / sem',
      },
      {
        'Tarea': 'Limpiar skimmer',
        'Verano': 'Diario',
        'Resto': 'Semanal',
      },
      {
        'Tarea': 'Cepillar paredes',
        'Verano': '1-2 veces / sem',
        'Resto': 'Cada 15 días',
      },
      {
        'Tarea': 'Aspirar fondo',
        'Verano': '1 vez / sem',
        'Resto': '1 vez / mes',
      },
      {
        'Tarea': 'Medir pH/Cloro',
        'Verano': 'Cada 2 días',
        'Resto': 'Semanal',
      },
    ];

    return _buildCardContainer(
      title: '2. Frecuencia de Limpieza',
      icon: Icons.calendar_month_outlined,
      iconColor: AppColors.primary,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'TAREA',
                    style: GoogleFonts.syne(
                      color: AppColors.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'VERANO',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.syne(
                      color: AppColors.statusWarning,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'INVIERNO',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.syne(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...frecuencias.map((f) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        f['Tarea']!,
                        style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
                          color: AppColors.statusWarning,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        f['Resto']!,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          color: AppColors.primaryLight,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

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
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 12,
                child: VerticalDivider(
                  color: AppColors.border,
                  thickness: 2,
                ),
              ),
            ),
          ),
          _buildStepItem(
            stepNumber: '2',
            title: 'Cepillado (Fundamental)',
            content:
                'Pasa el cepillo por paredes y borde de flotación. Esto desprende micro-algas para que el filtro las atrape o el limpiafondos las succione.',
          ),
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 12,
                child: VerticalDivider(
                  color: AppColors.border,
                  thickness: 2,
                ),
              ),
            ),
          ),
          _buildStepItem(
            stepNumber: '3',
            title: 'Aspirar Fondo (Manguera)',
            content:
                '1. Conecta la manguera al limpiafondos y mételo al agua.\n2. Pon el otro extremo en un chorro de retorno hasta que deje de salir aire.\n3. Conéctalo a la boquilla de aspiración.\n4. Mueve lento y lineal para no levantar mugre.',
          ),
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 12,
                child: VerticalDivider(
                  color: AppColors.border,
                  thickness: 2,
                ),
              ),
            ),
          ),
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

  Widget _buildStepItem({
    required String stepNumber,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 1),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
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

  Widget _buildProTipsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.statusGood.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusGood.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_outline_rounded,
                  color: AppColors.statusGood, size: 24),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.statusGood, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.syne(
                color: AppColors.statusGood,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 22.0),
          child: Text(
            content,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

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
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
