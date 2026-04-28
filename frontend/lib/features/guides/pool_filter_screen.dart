import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class PoolFilterScreen extends StatelessWidget {
  const PoolFilterScreen({
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
          'Filtro de Piscina',
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          _buildInfoCard(
            title: '1. Programación Diaria',
            subtitle: 'Modo FILTRACIÓN - Mantiene el agua libre de partículas.',
            icon: Icons.access_time,
            iconColor: AppColors.primary,
            children: [
              _buildSubsection(
                title: 'Temporada de Verano',
                description: 'Uso intenso y calor.',
                items: [
                  {'label': 'Tiempo', 'value': 'Entre 8 y 12 horas diarias.'},
                  {
                    'label': 'Consejo',
                    'value':
                        'Evita 12 horas seguidas. Mejor dividir en bloques (ej. 6h mañana y 6h tarde) para evitar estancamiento.'
                  },
                ],
                icon: Icons.wb_sunny_outlined,
                color: AppColors.statusWarning,
              ),
              const Divider(color: AppColors.border, height: 24),
              _buildSubsection(
                title: 'Temporada de Invierno',
                description: 'Mantenimiento preventivo.',
                items: [
                  {'label': 'Tiempo', 'value': 'Entre 2 y 4 horas diarias.'},
                  {
                    'label': 'Objetivo',
                    'value':
                        'Evitar proliferación de algas o larvas, aunque la piscina no se use.'
                  },
                ],
                icon: Icons.ac_unit,
                color: AppColors.primaryLight,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: '2. Modos de la Válvula',
            subtitle: 'Cuándo usar las funciones adicionales al filtro.',
            icon: Icons.settings_input_component_outlined,
            iconColor: AppColors.accent,
            children: [
              _buildModeItem(
                title: 'Modo RECIRCULACIÓN',
                subtitle: 'Sin pasar por el filtro.',
                whenToUse: 'Al añadir químicos potentes (cloro choque, algicida).',
                why:
                    'Mezcla el producto rápidamente (30-60 min) sin saturar la arena.',
                icon: Icons.autorenew,
              ),
              const SizedBox(height: 12),
              _buildModeItem(
                title: 'Modo DESAGÜE / VACIADO',
                subtitle: 'Waste / Drenaje directo a la calle.',
                whenToUse: 'Para aspirar fondo muy sucio (tierra o algas muertas).',
                why:
                    'Evita saturar el filtro en 5 minutos en modo filtración.',
                icon: Icons.water_drop_outlined,
              ),
              const SizedBox(height: 12),
              _buildModeItem(
                title: 'Modo LAVADO y ENJUAGUE',
                subtitle: 'Backwash / Rinse',
                whenToUse: 'Una vez a la semana en verano.',
                why:
                    'Si los chorros de retorno pierden fuerza, es señal de filtro saturado. Ayuda a limpiar la arena para recuperar presión.',
                icon: Icons.cleaning_services_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGoldenRulesCard(),
          const SizedBox(height: 40),
        ],
      );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
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
                child: Icon(icon, color: iconColor),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubsection({
    required String title,
    required String description,
    required List<Map<String, String>> items,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.syne(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item['label']!.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item['value']!,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildModeItem({
    required String title,
    required String subtitle,
    required String whenToUse,
    required String why,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.syne(
                  color: AppColors.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          _buildBulletPoint('Cuándo:', whenToUse),
          const SizedBox(height: 4),
          _buildBulletPoint('Por qué:', why),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0, right: 6.0),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: text,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoldenRulesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.statusDanger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusDanger.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.statusDanger),
              const SizedBox(width: 10),
              Text(
                '3. Reglas de Oro',
                style: GoogleFonts.syne(
                  color: AppColors.statusDanger,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRuleRow(
            icon: Icons.do_not_touch,
            text:
                'NUNCA muevas la palanca de la válvula con la bomba encendida. Podrías romper las juntas y generar filtraciones.',
          ),
          const SizedBox(height: 12),
          _buildRuleRow(
            icon: Icons.water_drop,
            text:
                'El agua siempre a la mitad de la boca del skimmer. Si está más baja, la bomba succionará aire y podría quemarse.',
          ),
          const SizedBox(height: 12),
          _buildRuleRow(
            icon: Icons.delete_outline,
            text:
                'Pre-filtro: Una vez por semana, apaga todo y limpia la canastilla de la bomba. Sin ella limpia, el filtro no tiene fuerza.',
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.statusDanger.withValues(alpha: 0.8), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
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
}
