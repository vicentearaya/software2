import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/pool_service.dart';
import 'pool_data.dart';
import 'widgets/add_pool_screen.dart';
import 'widgets/dashboard_empty_view.dart';
import 'widgets/manual_treatment_card.dart';
import 'widgets/pool_inspector_widgets.dart';
import 'widgets/pool_water_status_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _deviceId = 'cleanpool-001';
  List<Map<String, dynamic>> _pools = [];
  Map<String, dynamic>? _selectedPool;
  bool _loading = true;
  bool _loadingStatus = false;
  Map<String, dynamic>? _poolStatus;
  Map<String, dynamic>? _manualStatusOverride;
  Map<String, dynamic>? _deviceBinding;
  bool _bindingActionLoading = false;
  bool _showAptitudCard = false;

  final _authService = AuthService();
  final _poolService = PoolService();

  @override
  void initState() {
    super.initState();
    _loadPools();
  }

  Future<void> _loadPoolStatus({bool showLoader = true}) async {
    if (_selectedPool == null || _selectedPool!['id'] == null) {
      if (mounted) setState(() => _loadingStatus = false);
      return;
    }
    if (showLoader && mounted) setState(() => _loadingStatus = true);
    final token = await _authService.getToken();
    final result = await _poolService.getPoolStatus(
      _selectedPool!['id'] as String,
      token: token,
    );
    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _poolStatus = result['data'] as Map<String, dynamic>?;
          if (showLoader) {
            _loadingStatus = false;
          }
        });
      }
    } else {
      if (showLoader && mounted) setState(() => _loadingStatus = false);
    }
  }

  Future<void> _loadDeviceBinding({bool silent = false}) async {
    final token = await _authService.getToken();
    if (token == null) {
      if (mounted) {
        setState(() => _deviceBinding = null);
      }
      return;
    }

    final bindingResult = await _poolService.getDeviceBinding(
      deviceId: _deviceId,
      token: token,
    );
    if (!mounted) return;

    if (bindingResult['success'] != true) {
      if (!silent) {
        setState(() => _deviceBinding = null);
      }
      return;
    }

    final baseBinding = Map<String, dynamic>.from(
      bindingResult['data'] as Map<String, dynamic>,
    );
    baseBinding['is_online'] = false;

    setState(() {
      _deviceBinding = baseBinding;
    });

    final statusResult = await _poolService.getDeviceStatus(
      deviceId: _deviceId,
      token: token,
    );
    if (!mounted) return;

    if (statusResult['success'] == true) {
      setState(() {
        _deviceBinding = {
          ...baseBinding,
          ...(statusResult['data'] as Map<String, dynamic>),
        };
      });
    }
  }

  Future<void> _loadPools({String? selectId}) async {
    if (mounted) setState(() => _loading = true);

    final token = await _authService.getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _pools = [];
          _selectedPool = null;
          _showAptitudCard = false;
        });
      }
      return;
    }

    final result = await _poolService.getPools(token);
    if (result['success'] == true) {
      final List<dynamic> fetched = result['data'] as List<dynamic>;
      _pools = fetched.map((e) => e as Map<String, dynamic>).toList();

      if (_pools.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastId = selectId ?? prefs.getString('last_pool_id');

        _selectedPool = _pools.firstWhere(
          (p) => p['id'] == lastId,
          orElse: () => _pools.first,
        );

        await prefs.setString('last_pool_id', _selectedPool!['id'] as String);
        _showAptitudCard = false;
        _manualStatusOverride = null;
      } else {
        _selectedPool = null;
        _showAptitudCard = false;
        _manualStatusOverride = null;
      }
    }

    if (mounted) {
      setState(() => _loading = false);
      _loadPoolStatus();
      _loadDeviceBinding(silent: true);
    }
  }

  Future<void> _onPullRefresh() async {
    final id = _selectedPool?['id'] as String?;
    await _loadPools(selectId: id);
  }

  Future<void> _savePool(PoolData pool) async {
    final token = await _authService.getToken();
    if (token == null) return;

    final payload = {
      'nombre': pool.nombre,
      'volumen': pool.volumenM3,
      'tipo': pool.esInterior ? 'interior' : 'exterior',
      'ubicacion': '',
      'largo': pool.largo,
      'ancho': pool.ancho,
      'profundidad': pool.profundidad,
      'filtro': pool.tieneFiltro,
    };

    Map<String, dynamic> result;
    if (_selectedPool != null && _selectedPool!['nombre'] == pool.nombre) {
      result = await _poolService.updatePool(
        _selectedPool!['id'] as String,
        payload,
        token,
      );
    } else {
      result = await _poolService.createPool(payload, token);
    }

    if (result['success'] == true) {
      final newPool = result['data'] as Map<String, dynamic>;
      await _loadPools(selectId: newPool['id'] as String?);
    }
  }

  Future<void> _deletePool() async {
    if (_selectedPool == null) return;

    final token = await _authService.getToken();
    if (token == null) return;

    final res = await _poolService.deletePool(_selectedPool!['id'] as String, token);
    if (res['success'] == true) {
      await _loadPools();
      await _loadDeviceBinding(silent: true);
    } else {
      if (mounted) {
        AppUtils.showSnackBar(
          context,
          res['message'] as String? ?? 'Ocurrió un error.',
          isError: true,
        );
      }
    }
  }

  Future<void> _bindDeviceToSelectedPool() async {
    if (_selectedPool == null || _selectedPool!['id'] == null) return;

    final token = await _authService.getToken();
    if (token == null) {
      if (mounted) {
        AppUtils.showSnackBar(
          context,
          'Debes iniciar sesión para vincular dispositivo.',
          isError: true,
        );
      }
      return;
    }

    if (_deviceBinding?['pool_id'] != null &&
        _deviceBinding!['pool_id'] != _selectedPool!['id']) {
      AppUtils.showSnackBar(
        context,
        'Primero debes desvincular el dispositivo de la piscina actual.',
        isError: true,
      );
      return;
    }

    setState(() => _bindingActionLoading = true);
    final result = await _poolService.bindDeviceToPool(
      deviceId: _deviceId,
      poolId: _selectedPool!['id'] as String,
      token: token,
    );

    if (!mounted) return;
    setState(() => _bindingActionLoading = false);
    if (result['success'] == true) {
      setState(() {
        _deviceBinding = {
          ...?_deviceBinding,
          'device_id': _deviceId,
          'pool_id': _selectedPool!['id'],
          'is_online': _deviceBinding?['is_online'] == true,
        };
      });
      AppUtils.showSnackBar(
        context,
        'Dispositivo vinculado a ${_selectedPool!['nombre']}.',
      );
      await _loadDeviceBinding(silent: true);
    } else {
      AppUtils.showSnackBar(
        context,
        result['message'] as String? ?? 'No se pudo vincular el dispositivo.',
        isError: true,
      );
    }
  }

  Future<void> _unbindDeviceFromSelectedPool() async {
    if (_selectedPool == null || _selectedPool!['id'] == null) return;
    final token = await _authService.getToken();
    if (token == null) return;

    setState(() => _bindingActionLoading = true);
    final result = await _poolService.unbindDeviceFromPool(
      deviceId: _deviceId,
      poolId: _selectedPool!['id'] as String,
      token: token,
    );
    if (!mounted) return;
    setState(() => _bindingActionLoading = false);

    if (result['success'] == true) {
      setState(() => _deviceBinding = null);
      AppUtils.showSnackBar(
        context,
        'Dispositivo desvinculado de esta piscina.',
      );
      await _loadDeviceBinding(silent: true);
    } else {
      AppUtils.showSnackBar(
        context,
        result['message'] as String? ?? 'No se pudo desvincular el dispositivo.',
        isError: true,
      );
    }
  }

  void _openAddPoolForm() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => AddPoolScreen(
          onSave: _savePool,
          initialData: _selectedPool != null
              ? PoolData(
                  nombre: _selectedPool!['nombre'] ?? '',
                  largo: (_selectedPool!['largo'] as num?)?.toDouble() ?? 0,
                  ancho: (_selectedPool!['ancho'] as num?)?.toDouble() ?? 0,
                  profundidad:
                      (_selectedPool!['profundidad'] as num?)?.toDouble() ?? 0,
                  esInterior: (_selectedPool!['tipo'] as String?) == 'interior',
                  tieneFiltro: (_selectedPool!['filtro'] as bool?) ?? true,
                )
              : null,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_selectedPool == null) {
      return DashboardEmptyView(onAddPool: _openAddPoolForm);
    }
    return _buildDashboard();
  }

  Widget _buildDashboard() {
    final selectedPoolMap = _selectedPool!;
    final largo = (selectedPoolMap['largo'] as num?)?.toDouble() ?? 0.0;
    final ancho = (selectedPoolMap['ancho'] as num?)?.toDouble() ?? 0.0;
    final prof = (selectedPoolMap['profundidad'] as num?)?.toDouble() ?? 0.0;
    final volumenM3 =
        (selectedPoolMap['volumen'] as num?)?.toDouble() ?? (largo * ancho * prof);
    final litros = volumenM3 * 1000;

    final litrosStr = litros >= 1000
        ? '${(litros / 1000).toStringAsFixed(2)} m³ (${_formatNumber(litros)} L)'
        : '${_formatNumber(litros)} L';

    final pool = PoolData(
      nombre: selectedPoolMap['nombre'] ?? '',
      largo: largo,
      ancho: ancho,
      profundidad: prof,
      esInterior: selectedPoolMap['tipo'] == 'interior',
      tieneFiltro: (selectedPoolMap['filtro'] as bool?) ?? true,
    );
    final String selectedPoolId = selectedPoolMap['id'] as String;
    final String? boundPoolId = _deviceBinding?['pool_id'] as String?;
    final bool isDeviceOnline = _deviceBinding?['is_online'] == true;
    final bool isDeviceBoundToSelectedPool =
        boundPoolId != null && boundPoolId == selectedPoolId;
    final bool isDeviceBoundToAnotherPool =
        boundPoolId != null && boundPoolId != selectedPoolId;
    final Map<String, dynamic>? temperaturaData =
        _poolStatus?['parametros']?['temperatura'] as Map<String, dynamic>?;
    final num? temperaturaValor = temperaturaData?['valor'] as num?;
    final double? temperatureC = temperaturaValor?.toDouble();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onPullRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Dashboard',
                                  style: GoogleFonts.syne(
                                    color: AppColors.textPrimary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (_pools.length < 3)
                                  IconButton(
                                    onPressed: _openAddPoolForm,
                                    icon: const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                    tooltip: 'Agregar piscina',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: AppColors.surface,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 12),
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: AppColors.border,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Text(
                                          'Seleccionar Piscina',
                                          style: GoogleFonts.syne(
                                            color: AppColors.textPrimary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Flexible(
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _pools.length,
                                          itemBuilder: (context, index) {
                                            final p = _pools[index];
                                            final isSelected =
                                                p['id'] == _selectedPool!['id'];
                                            return ListTile(
                                              leading: Icon(
                                                Icons.pool_rounded,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textMuted,
                                              ),
                                              title: Text(
                                                p['nombre'] ?? 'Sin nombre',
                                                style: GoogleFonts.interTight(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : AppColors.textPrimary,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              trailing: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      color: AppColors.primary,
                                                    )
                                                  : null,
                                              onTap: () {
                                                Navigator.pop(context);
                                                _loadPools(selectId: p['id'] as String?);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedPool!['nombre'] ?? '',
                                    style: GoogleFonts.interTight(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: _openAddPoolForm,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Editar'),
                          ),
                          TextButton.icon(
                            onPressed: _confirmDeletePool,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.statusDanger,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: PoolHeroCard(
                    pool: pool,
                    litrosStr: litrosStr,
                    temperatureC:
                        isDeviceBoundToSelectedPool ? temperatureC : null,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      PoolVisualSection(pool: pool),
                      if (isDeviceBoundToSelectedPool && !isDeviceOnline)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Dispositivo vinculado, sin señal reciente.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.interTight(
                              color: AppColors.statusWarning,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: ElevatedButton.icon(
                    onPressed: _bindingActionLoading
                        ? null
                        : isDeviceBoundToSelectedPool
                            ? _unbindDeviceFromSelectedPool
                            : isDeviceBoundToAnotherPool
                                ? null
                                : _bindDeviceToSelectedPool,
                    icon: _bindingActionLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.link_rounded),
                    label: Text(
                      isDeviceBoundToSelectedPool
                          ? 'Desvincular dispositivo de esta piscina'
                          : isDeviceBoundToAnotherPool
                              ? 'Dispositivo vinculado a otra piscina'
                              : 'Vincular dispositivo a esta piscina',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDeviceBoundToSelectedPool
                          ? AppColors.statusDanger
                          : isDeviceBoundToAnotherPool
                              ? AppColors.textMuted
                              : AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: PoolDimensionsStrip(pool: pool),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Text(
                    'Características',
                    style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    DashboardInfoRow(
                      icon: pool.esInterior
                          ? Icons.home_rounded
                          : Icons.wb_sunny_rounded,
                      label: 'Tipo de instalación',
                      value: pool.esInterior ? 'Interior' : 'Exterior',
                      color: pool.esInterior
                          ? AppColors.accent
                          : AppColors.statusWarning,
                    ),
                    const SizedBox(height: 10),
                    DashboardInfoRow(
                      icon: pool.tieneFiltro
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      label: 'Sistema de filtración',
                      value: pool.tieneFiltro ? 'Con filtro' : 'Sin filtro',
                      color: pool.tieneFiltro
                          ? AppColors.statusGood
                          : AppColors.statusDanger,
                    ),
                  ]),
                ),
              ),
              if (_selectedPool != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      children: [
                        if (_showAptitudCard) ...[
                          PoolWaterStatusPanel(
                            loading: _loadingStatus,
                            manualOverride: _manualStatusOverride,
                            poolStatus: _poolStatus,
                          ),
                          const SizedBox(height: 14),
                        ],
                        ManualTreatmentCard(
                          poolId: _selectedPool!['id'] as String?,
                          onCalculated: (ph, cloro) {
                            if (mounted) {
                              setState(() {
                                _showAptitudCard = true;
                                _manualStatusOverride =
                                    _buildManualStatusFromInputs(ph, cloro);
                              });
                            }
                            _loadPoolStatus(showLoader: false);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeletePool() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar piscina',
          style: GoogleFonts.syne(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '¿Seguro que quieres eliminar esta piscina? Se perderán los datos locales.',
          style: GoogleFonts.interTight(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.interTight(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePool();
            },
            child: Text(
              'Eliminar',
              style: GoogleFonts.interTight(
                color: AppColors.statusDanger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  Map<String, dynamic> _buildManualStatusFromInputs(double ph, double cloro) {
    final bool phOptimo = ph >= 7.2 && ph <= 7.8;
    final bool phWarning = !phOptimo && ph >= 6.8 && ph <= 8.2;
    final bool cloroOptimo = cloro >= 1.0 && cloro <= 3.0;
    final bool cloroWarning = !cloroOptimo && cloro >= 0.5 && cloro <= 5.0;

    String phState = 'NORMAL';
    if (!phOptimo) {
      phState = ph < 7.2 ? 'BAJO' : 'ALTO';
    }

    String cloroState = 'NORMAL';
    if (!cloroOptimo) {
      cloroState = cloro < 1.0 ? 'BAJO' : 'ALTO';
    }

    String estadoGlobal;
    if (phOptimo && cloroOptimo) {
      estadoGlobal = 'APTA';
    } else if ((phOptimo || phWarning) && (cloroOptimo || cloroWarning)) {
      estadoGlobal = 'ADVERTENCIA';
    } else {
      estadoGlobal = 'NO APTA';
    }

    return {
      'estado': estadoGlobal,
      'parametros': {
        'ph': {'valor': ph, 'estado': phState, 'fuente': 'manual'},
        'cloro': {'valor': cloro, 'estado': cloroState, 'fuente': 'manual'},
      },
    };
  }
}
