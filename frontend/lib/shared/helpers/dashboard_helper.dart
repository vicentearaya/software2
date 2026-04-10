import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/pool_provider.dart';
import '../../shared/services/pool_service.dart';

/// ✅ DashboardHelper: Lógica para inicializar piscinas al cargar el dashboard
class DashboardHelper {
  /// Carga las piscinas del usuario y auto-selecciona la primera
  static Future<void> loadPoolsAndSelectFirst(
    BuildContext context,
    String token,
  ) async {
    try {
      final poolProvider = context.read<PoolProvider>();
      poolProvider.setLoading(true);

      // Cargar piscinas desde el API
      final response = await PoolService().getPools(token);

      if (response['success']) {
        final data = response['data'];
        final List<dynamic> poolsList = data['pools'] ?? [];

        // Convertir a List<Map>
        final pools = poolsList
            .map((pool) => (pool as Map).cast<String, dynamic>())
            .toList();

        // ✅ Auto-selecciona la primera piscina
        poolProvider.setPoolsAndSelectFirst(pools);
      } else {
        poolProvider.setError(
          response['message'] ?? 'Error al cargar piscinas',
        );
      }
    } catch (e) {
      context.read<PoolProvider>().setError('Error: ${e.toString()}');
    } finally {
      context.read<PoolProvider>().setLoading(false);
    }
  }

  /// Carga los detalles de una piscina específica
  static Future<void> loadPoolDetails(
    BuildContext context,
    String poolId,
    String token,
  ) async {
    try {
      final poolProvider = context.read<PoolProvider>();
      poolProvider.setLoading(true);

      final response = await PoolService().getPoolById(poolId, token);

      if (response['success']) {
        final pool = (response['data'] as Map).cast<String, dynamic>();
        poolProvider.selectPool(pool);
      } else {
        poolProvider.setError(
          response['message'] ?? 'Error al cargar detalles',
        );
      }
    } catch (e) {
      context.read<PoolProvider>().setError('Error: ${e.toString()}');
    } finally {
      context.read<PoolProvider>().setLoading(false);
    }
  }
}
