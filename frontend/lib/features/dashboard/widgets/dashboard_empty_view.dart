import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class DashboardEmptyView extends StatelessWidget {
  const DashboardEmptyView({super.key, required this.onAddPool});

  final VoidCallback onAddPool;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.pool_outlined,
                    size: 52,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Sin piscina registrada',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Agrega tu piscina para comenzar a\nmonitorear el estado del agua.',
                  style: GoogleFonts.interTight(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: onAddPool,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Agregar piscina',
                    style: GoogleFonts.syne(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
