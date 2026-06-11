import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/app_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/maintenance.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/maintenance_service.dart';
import '../../shared/services/pdf_service.dart';
import 'profile_filter_chips.dart';
import 'profile_header_widgets.dart';
import 'profile_helpers.dart';
import 'profile_history_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final MaintenanceService _maintenanceService = MaintenanceService();

  List<Maintenance> _history = [];
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  String? _error;
  HistoryFilter _activeFilter = HistoryFilter.all;

  List<Maintenance> get _filteredHistory => filterHistory(
        history: _history,
        filter: _activeFilter,
        now: DateTime.now(),
      );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authService.getUser();
      final token = await _authService.getToken();

      if (token == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Sesión expirada';
          _isLoading = false;
        });
        return;
      }

      final result = await _maintenanceService.getMaintenanceHistory(token);
      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _history = result['data'];
          _user = user;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Error inesperado al cargar datos';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportarPDF() async {
    if (_isLoading || _isGeneratingPdf) return;

    setState(() => _isGeneratingPdf = true);
    try {
      final userName =
          (_user?['username'] as String?) ?? (_user?['name'] as String?) ?? 'usuario';
      await PdfService.exportMaintenanceHistory(
        records: _history,
        userName: userName,
      );
    } catch (_) {
      if (!mounted) return;
      AppUtils.showSnackBar(
        context,
        'Error al generar PDF. Intenta de nuevo.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.welcome,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeaderCard(user: _user, initials: userInitials(_user)),
              const SizedBox(height: 14),
              ProfileSummaryCards(history: _history, formatDate: formatHistoryDate),
              const SizedBox(height: 32),
              _buildHistoryHeader(context),
              const SizedBox(height: 12),
              if (!_isLoading && _error == null)
                ProfileFilterChips(
                  activeFilter: _activeFilter,
                  onSelected: (filter) {
                    if (_activeFilter != filter) {
                      setState(() => _activeFilter = filter);
                    }
                  },
                ),
              const SizedBox(height: 16),
              ProfileHistoryList(
                isLoading: _isLoading,
                error: _error,
                history: _history,
                filteredHistory: _filteredHistory,
                activeFilter: _activeFilter,
                formatDate: formatHistoryDate,
                onRetry: _loadData,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusDanger.withOpacity(0.1),
                    foregroundColor: AppColors.statusDanger,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.statusDanger, width: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Encabezado del historial: en móvil apila título y botón; en ancho los pone en fila.
  Widget _buildHistoryHeader(BuildContext context) {
    const titulo = Text(
      'Historial de Mantenciones',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );

    if (ResponsiveUtils.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titulo,
          const SizedBox(height: 12),
          _buildExportButton(fullWidth: true),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: titulo),
        _buildExportButton(fullWidth: false),
      ],
    );
  }

  /// Botón "Exportar PDF" con estado de carga y guardas.
  Widget _buildExportButton({required bool fullWidth}) {
    return ElevatedButton.icon(
      onPressed: (_isLoading || _isGeneratingPdf) ? null : _exportarPDF,
      icon: _isGeneratingPdf
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.picture_as_pdf_rounded, size: 18),
      label: Text(
        _isGeneratingPdf ? 'Generando...' : 'Exportar PDF',
        style: GoogleFonts.syne(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(fullWidth ? double.infinity : 0, fullWidth ? 48 : 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
