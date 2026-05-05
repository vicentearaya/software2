import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/maintenance_service.dart';
import '../../models/maintenance.dart';
import '../auth/login_screen.dart';

// ---------------------------------------------------------------------------
// Enum que representa los filtros de tiempo disponibles para el historial.
// ---------------------------------------------------------------------------
enum _HistoryFilter {
  all,
  last30Days,
  lastWeek,
  last3Days,
}

extension _HistoryFilterLabel on _HistoryFilter {
  String get label {
    switch (this) {
      case _HistoryFilter.all:
        return 'Todos';
      case _HistoryFilter.last30Days:
        return 'Últimos 30 días';
      case _HistoryFilter.lastWeek:
        return 'Última semana';
      case _HistoryFilter.last3Days:
        return 'Últimos 3 días';
    }
  }
}

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
  String? _error;

  // Filtro activo; por defecto muestra todos los registros.
  _HistoryFilter _activeFilter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ---------------------------------------------------------------------------
  // Devuelve la sublista de _history que cumple el filtro seleccionado.
  // El cálculo es client-side sobre los datos ya cargados.
  // ---------------------------------------------------------------------------
  List<Maintenance> get _filteredHistory {
    if (_activeFilter == _HistoryFilter.all) return _history;

    final now = DateTime.now();
    final Duration cutoff;

    switch (_activeFilter) {
      case _HistoryFilter.last30Days:
        cutoff = const Duration(days: 30);
        break;
      case _HistoryFilter.lastWeek:
        cutoff = const Duration(days: 7);
        break;
      case _HistoryFilter.last3Days:
        cutoff = const Duration(days: 3);
        break;
      case _HistoryFilter.all:
        return _history;
    }

    final threshold = now.subtract(cutoff);
    return _history.where((m) => m.fecha.isAfter(threshold)).toList();
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

      if (token != null) {
        final result = await _maintenanceService.getMaintenanceHistory(token);
        if (result['success']) {
          if (mounted) {
            setState(() {
              _history = result['data'];
              _user = user;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _error = result['message'];
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Sesión expirada';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error inesperado al cargar datos';
          _isLoading = false;
        });
      }
    }
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
              _buildHeader(),
              const SizedBox(height: 32),
              const Text(
                'Historial de Mantenciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 16),
              _buildHistoryList(),
              const SizedBox(height: 40),
              _buildLogoutButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Fila de chips para seleccionar el filtro de tiempo.
  // Solo se muestra cuando los datos ya fueron cargados correctamente.
  // ---------------------------------------------------------------------------
  Widget _buildFilterChips() {
    if (_isLoading || _error != null) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _HistoryFilter.values.map((filter) {
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) {
                if (_activeFilter != filter) {
                  setState(() => _activeFilter = filter);
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, size: 35, color: AppColors.primary),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?['name'] ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _user?['email'] ?? 'Sin correo',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  '@${_user?['username'] ?? 'usuario'}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.statusDanger, size: 40),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loadData,
              child: const Text('Reintentar', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    final displayed = _filteredHistory;

    if (_history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: const Column(
          children: [
            Icon(Icons.history, color: AppColors.textMuted, size: 48),
            SizedBox(height: 16),
            Text(
              'Aún no registras mantenciones.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (displayed.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            const Icon(Icons.filter_list_off, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'Sin registros para "${_activeFilter.label}".',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayed.length,
      itemBuilder: (context, index) {
        final item = displayed[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF1E2D40),
              child: Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 20),
            ),
            title: Text(
              'Piscina: ${item.idPiscina}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  item.productosResumen,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (item.ph != null || item.cloro != null || item.temperatura != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.parametrosResumen,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${item.fecha.day}/${item.fecha.month}/${item.fecha.year} ${item.fecha.hour}:${item.fecha.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await _authService.logout();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }
}
