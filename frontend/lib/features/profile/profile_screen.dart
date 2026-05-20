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

  String get _userInitials {
    final rawName = (_user?['name'] as String?)?.trim();
    if (rawName == null || rawName.isEmpty) return 'U';

    final parts = rawName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

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

  DateTime? get _lastMaintenanceDate {
    if (_history.isEmpty) return null;
    final sorted = List<Maintenance>.from(_history)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return sorted.first.fecha;
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
              const SizedBox(height: 14),
              _buildSummaryCards(),
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
    final name = (_user?['name'] as String?)?.trim();
    final email = (_user?['email'] as String?)?.trim();
    final username = (_user?['username'] as String?)?.trim();
    final normalizedUsername = username == null
        ? null
        : username.replaceAll('@', '').trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null || name.isEmpty ? 'Usuario' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email == null || email.isEmpty ? 'Sin correo registrado' : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.alternate_email_rounded,
                              color: AppColors.primary, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            normalizedUsername == null ||
                                    normalizedUsername.isEmpty
                                ? 'usuario'
                                : normalizedUsername,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatHistoryDate(DateTime date) {
    const months = <String>[
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (target == today) {
      return 'Hoy, $hour:$minute';
    }

    if (target == today.subtract(const Duration(days: 1))) {
      return 'Ayer, $hour:$minute';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    return '$day $month $year, $hour:$minute';
  }

  Widget _buildSummaryCards() {
    final total = _history.length;
    final lastDate = _lastMaintenanceDate;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total',
            value: '$total',
            subtitle: total == 1 ? 'registro' : 'registros',
            icon: Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Ultima',
            value: lastDate == null ? '--' : _formatHistoryDate(lastDate),
            subtitle: 'actualizacion',
            icon: Icons.schedule_rounded,
            isDate: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    bool isDate = false,
  }) {
    final isCompactMetric = !isDate;

    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (isCompactMetric)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
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
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.idPiscina,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.productosResumen,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    if (item.ph != null || item.cloro != null || item.temperatura != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          item.parametrosResumen,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatHistoryDate(item.fecha),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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

