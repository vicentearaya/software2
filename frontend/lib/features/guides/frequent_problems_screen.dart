import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FrequentProblemsScreen extends StatelessWidget {
  const FrequentProblemsScreen({
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
          'Problemas Frecuentes',
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
        _buildProblemAccordion(
          title: '1. Crecimiento de algas o Agua verde',
          icon: Icons.grass_rounded,
          iconColor: const Color(0xFF2ECC71),
          causes:
              'Niveles bajos de cloro residual, pH desbalanceado (usualmente muy alto) y falta de circulación de agua.',
          identification:
              'El agua adquiere un tono verde translúcido o turbio, las paredes se sienten resbaladizas al tacto.',
          solutions: [
            'Ajustar el pH a niveles óptimos (entre 7.2 - 7.6).',
            'Realizar una supercloración, aumentar el nivel de cloro 5 veces del nivel normal por 24 horas.',
            'Cepillar paredes y piso vigorosamente.',
            'Con filtro: Filtrar continuamente por 24 horas.',
            'Sin filtro: Usar clarificador y succionar manualmente al fondo una vez decantado.',
          ],
          prevention:
              'Mantener niveles constantes de cloro y realizar limpiezas semanales. En piscinas de cemento, el cepillado es más crítico debido a los poros.',
        ),
        const SizedBox(height: 14),
        _buildProblemAccordion(
          title: '2. Agua Turbia',
          icon: Icons.cloud_outlined,
          iconColor: const Color(0xFF95A5A6),
          causes:
              'Filtración ineficiente, altos niveles de dureza cálcica o desequilibrio químico inicial después de un llenado.',
          identification: 'El agua se ve "opaca" o como si tuviera neblina.',
          solutions: [
            'Limpiar o lavar el filtro.',
            'Aplicar un floculante o clarificador para agrupar las partículas pequeñas.',
            'Esperar a que los sedimentos caigan al fondo.',
            'Aspirar los residuos hacia el desagüe.',
          ],
          prevention:
              'En piscinas de fibra de vidrio y cemento, es vital no exceder la dureza cálcica.',
        ),
        const SizedBox(height: 14),
        _buildProblemAccordion(
          title: '3. Irritación de Ojos y Piel',
          icon: Icons.visibility_off_outlined,
          iconColor: AppColors.statusDanger,
          causes:
              'Formación de cloraminas (cloro combinado con sudor, orina o aceites).',
          identification:
              'Olor penetrante a "químico", irritación en los ojos y picazón en la piel de los bañistas.',
          solutions: [
            'Medir el cloro libre vs. el cloro total.',
            'Realizar un tratamiento de choque para "quemar" las cloraminas.',
            'Aumentar la ventilación si la piscina es techada.',
          ],
          prevention:
              'Exigir ducha previa a los usuarios y mantener un nivel de cloro libre adecuado.',
        ),
        const SizedBox(height: 14),
        _buildProblemAccordion(
          title: '4. Corrosión de Metales y Desgaste',
          icon: Icons.hardware_outlined,
          iconColor: const Color(0xFFE67E22),
          causes: 'pH muy bajo (acidez) y alcalinidad total baja.',
          identification:
              'Manchas de óxido en escaleras o focos, desgaste prematuro en la pintura o el revestimiento de cemento. En fibra de vidrio, puede causar grietas microscópicas.',
          solutions: [
            'Aumentar la alcalinidad total inmediatamente (bicarbonato de sodio).',
            'Ajustar el pH hacia arriba utilizando carbonato de sodio.',
          ],
          prevention: 'No dejar nunca que el pH baje de 7.0.',
        ),
        const SizedBox(height: 14),
        _buildProblemAccordion(
          title: '5. Espuma en la Superficie',
          icon: Icons.waves_rounded,
          iconColor: Colors.white70,
          causes:
              'Residuos Orgánicos (cremas, aceites, desodorantes). Baja Dureza Cálcica (agua "blanda"). TDS Alto (Agua vieja).',
          identification:
              'Burbujas blancas que no estallan rápidamente y se acumulan en las esquinas de la piscina, con una consistencia similar a la espuma de afeitar.',
          solutions: [
            'Antiespumante: Aplicar un producto "defoam" para una solución estética inmediata.',
            'Tratamiento de Choque: Realizar una supercloración para oxidar residuos orgánicos.',
            'Limpieza de Filtro: Lavar el filtro para eliminar partículas atrapadas.',
            'Ajuste de Calcio: Si la dureza es menor a 150ppm, añadir incrementador.',
          ],
          prevention:
              'Ducharse antes de entrar. Usar alguicidas "No Espumígenos". Mantener la dureza cálcica (200-400 ppm).',
        ),
        const SizedBox(height: 14),
        _buildProblemAccordion(
          title: '6. Agua Café, Marrón o Rojiza',
          icon: Icons.local_cafe_outlined,
          iconColor: const Color(0xFF8B4513),
          causes:
              'Presencia de Hierro oxidado, corrosión de equipos (bomba, filtro), agua de pozo sin filtrar o altos niveles de Manganeso.',
          identification:
              'El agua se ve transparente (no turbia) pero de un color similar al té o al café.',
          solutions: [
            'Secuestrante de Metales: Añadir producto quelante para atrapar metales.',
            'Filtración Intensiva: Mantener el filtro 24/7. Usar clarificador.',
            'Lavado de Filtro: Limpiar el filtro con frecuencia para quitar óxido.',
            'Ajuste de pH: Mantener el pH estable en 7.4.',
          ],
          prevention:
              'No usar agua de pozo sin pre-filtro de metales. Mantener el pH por encima de 7.2.',
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProblemAccordion({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String causes,
    required String identification,
    required List<String> solutions,
    required String prevention,
  }) {
    return _ProblemCard(
      title: title,
      icon: icon,
      iconColor: iconColor,
      causes: causes,
      identification: identification,
      solutions: solutions,
      prevention: prevention,
    );
  }
}

// ─────────────────────────────────────────────
// Tarjeta de problema con hover y animaciones
// ─────────────────────────────────────────────
class _ProblemCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String causes;
  final String identification;
  final List<String> solutions;
  final String prevention;

  const _ProblemCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.causes,
    required this.identification,
    required this.solutions,
    required this.prevention,
  });

  @override
  State<_ProblemCard> createState() => _ProblemCardState();
}

class _ProblemCardState extends State<_ProblemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.iconColor.withOpacity(0.3)
                : AppColors.border,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.iconColor.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            collapsedIconColor: AppColors.textMuted,
            iconColor: widget.iconColor,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.iconColor.withOpacity(0.2),
                ),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 20),
            ),
            title: Text(
              widget.title,
              style: GoogleFonts.syne(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            childrenPadding:
                const EdgeInsets.fromLTRB(20, 0, 20, 20),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 1,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.iconColor.withOpacity(0.3),
                      AppColors.border.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
              _buildSectionLabel('Causas Comunes',
                  Icons.warning_amber_rounded, AppColors.statusWarning),
              const SizedBox(height: 6),
              _buildBodyText(widget.causes),
              const SizedBox(height: 18),
              _buildSectionLabel('Cómo identificarlo',
                  Icons.search_rounded, AppColors.primaryLight),
              const SizedBox(height: 6),
              _buildBodyText(widget.identification),
              const SizedBox(height: 18),
              _buildSectionLabel('Solución Paso a Paso',
                  Icons.check_circle_outline_rounded, AppColors.accent),
              const SizedBox(height: 10),
              ...widget.solutions.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.25),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.key + 1}',
                          style: GoogleFonts.interTight(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(child: _buildBodyText(entry.value)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              // Prevención card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusGood.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.statusGood.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.statusGood.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.shield_outlined,
                              color: AppColors.statusGood, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PREVENCIÓN',
                          style: GoogleFonts.syne(
                            color: AppColors.statusGood,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.prevention,
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
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: GoogleFonts.syne(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildBodyText(String text) {
    return Text(
      text,
      style: GoogleFonts.interTight(
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.55,
      ),
    );
  }
}
