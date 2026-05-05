import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'frequent_problems_screen.dart';
import 'pool_filter_screen.dart';
import 'pool_cleaning_screen.dart';

enum GuideType { frequentProblems, poolFilter, poolCleaning }

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  static const String _selectedGuideStorageKey = 'selected_guide';
  GuideType? _selectedGuide;
  bool _didRestoreState = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRestoreState) {
      return;
    }

    final dynamic storedGuide = PageStorage.of(context).readState(
      context,
      identifier: _selectedGuideStorageKey,
    );

    if (storedGuide is String) {
      _selectedGuide = _guideFromValue(storedGuide);
    }
    _didRestoreState = true;
  }

  void _onGuidePressed(GuideType guide) {
    final GuideType? nextGuide = _selectedGuide == guide ? null : guide;
    setState(() {
      _selectedGuide = nextGuide;
    });
    PageStorage.of(context).writeState(
      context,
      nextGuide?.name,
      identifier: _selectedGuideStorageKey,
    );
  }

  GuideType? _guideFromValue(String value) {
    for (final GuideType type in GuideType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }

  Widget _buildGuideContent() {
    switch (_selectedGuide) {
      case GuideType.frequentProblems:
        return const FrequentProblemsScreen(embedded: true);
      case GuideType.poolFilter:
        return const PoolFilterScreen(embedded: true);
      case GuideType.poolCleaning:
        return const PoolCleaningScreen(embedded: true);
      case null:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Selecciona una guía para ver su contenido aquí.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }

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
            _buildGuideCard(
              context,
              title: 'Problemas Frecuentes',
              description: 'Soluciones paso a paso a los problemas de agua más comunes.',
              icon: Icons.water_drop_outlined,
              color: AppColors.statusWarning,
              isSelected: _selectedGuide == GuideType.frequentProblems,
              onTap: () => _onGuidePressed(GuideType.frequentProblems),
            ),
            const SizedBox(height: 20),
            _buildGuideCard(
              context,
              title: 'Filtro de piscina',
              description: 'Entiende cómo mantener y limpiar el sistema de filtrado.',
              icon: Icons.filter_alt_outlined,
              color: AppColors.primary,
              isSelected: _selectedGuide == GuideType.poolFilter,
              onTap: () => _onGuidePressed(GuideType.poolFilter),
            ),
            const SizedBox(height: 20),
            _buildGuideCard(
              context,
              title: 'Limpieza piscina',
              description: 'Técnicas y rutinas para la limpieza de tu piscina.',
              icon: Icons.cleaning_services_outlined,
              color: AppColors.statusGood,
              isSelected: _selectedGuide == GuideType.poolCleaning,
              onTap: () => _onGuidePressed(GuideType.poolCleaning),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildGuideContent(),
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
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.65) : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
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
              isSelected ? Icons.expand_less : Icons.expand_more,
              color: isSelected ? color : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
