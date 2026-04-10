import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'frequent_problems_screen.dart';
import 'pool_filter_screen.dart';
import 'pool_cleaning_screen.dart';

class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Guías de Piscinas',
          style: GoogleFonts.syne(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            Text(
              'Aprende a mantener tu piscina en óptimas condiciones.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildGuideCard(
                    context,
                    title: 'Problemas Frecuentes',
                    description: 'Soluciones paso a paso a los problemas de agua más comunes.',
                    icon: Icons.water_drop_outlined,
                    color: AppColors.statusWarning,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FrequentProblemsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildGuideCard(
                    context,
                    title: 'Filtro de piscina',
                    description: 'Entiende cómo mantener y limpiar el sistema de filtrado.',
                    icon: Icons.filter_alt_outlined,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PoolFilterScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildGuideCard(
                    context,
                    title: 'Limpieza piscina',
                    description: 'Técnicas y rutinas para la limpieza de tu piscina.',
                    icon: Icons.cleaning_services_outlined,
                    color: AppColors.statusGood,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PoolCleaningScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
