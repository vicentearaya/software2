import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FrequentProblemsScreen extends StatelessWidget {
  const FrequentProblemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          _buildProblemAccordion(
            title: '1. Crecimiento de algas o Agua verde',
            icon: Icons.eco_outlined,
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
          const SizedBox(height: 16),
          _buildProblemAccordion(
            title: '2. Agua Turbia',
            icon: Icons.opacity_outlined,
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
          const SizedBox(height: 16),
          _buildProblemAccordion(
            title: '3. Irritación de Ojos y Piel',
            icon: Icons.remove_red_eye_outlined,
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
          const SizedBox(height: 16),
          _buildProblemAccordion(
            title: '4. Corrosión de Metales y Desgaste',
            icon: Icons.handyman_outlined,
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
          const SizedBox(height: 16),
          _buildProblemAccordion(
            title: '5. Espuma en la Superficie',
            icon: Icons.bubble_chart_outlined,
            iconColor: Colors.white,
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
          const SizedBox(height: 16),
          _buildProblemAccordion(
            title: '6. Agua Café, Marrón o Rojiza',
            icon: Icons.coffee_outlined,
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
          const SizedBox(height: 40),
        ],
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: AppColors.primary,
          iconColor: AppColors.accent,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: GoogleFonts.syne(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          childrenPadding:
              const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.border, height: 20),
            _buildSectionLabel('Causas Comunes', Icons.warning_amber_rounded, AppColors.statusWarning),
            _buildBodyText(causes),
            const SizedBox(height: 15),
            _buildSectionLabel('Cómo identificarlo', Icons.search, AppColors.primaryLight),
            _buildBodyText(identification),
            const SizedBox(height: 15),
            _buildSectionLabel('Solución Paso a Paso', Icons.check_circle_outline, AppColors.accent),
            const SizedBox(height: 6),
            ...solutions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2, right: 10),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: _buildBodyText(entry.value)),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusGood.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.statusGood.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: AppColors.statusGood, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'CÓMO PREVENIRLO',
                        style: GoogleFonts.syne(
                          color: AppColors.statusGood,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prevention,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
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

  Widget _buildSectionLabel(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.syne(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }
}
