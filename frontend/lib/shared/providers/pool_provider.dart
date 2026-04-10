import 'package:flutter/material.dart';

/// ✅ PoolProvider: Gestor de estado global para piscinas
/// 
/// Mantiene:
/// - selectedPool: Piscina actualmente seleccionada
/// - pools: Lista de todas las piscinas del usuario
/// - isLoading: Estado de carga
class PoolProvider extends ChangeNotifier {
  Map<String, dynamic>? _selectedPool;
  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get selectedPool => _selectedPool;
  List<Map<String, dynamic>> get pools => _pools;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// ✅ Auto-selecciona la primera piscina al cargar
  void setPoolsAndSelectFirst(List<Map<String, dynamic>> pools) {
    _pools = pools;
    if (pools.isNotEmpty) {
      _selectedPool = pools.first;
      _error = null;
    } else {
      _selectedPool = null;
      _error = 'No hay piscinas disponibles';
    }
    notifyListeners();
  }

  /// Actualiza la piscina seleccionada
  void selectPool(Map<String, dynamic> pool) {
    _selectedPool = pool;
    _error = null;
    notifyListeners();
  }

  /// Selecciona piscina por pool_id
  void selectPoolById(String poolId) {
    try {
      _selectedPool = _pools.firstWhere(
        (pool) => pool['pool_id'] == poolId,
        orElse: () => throw Exception('Pool no encontrado'),
      );
      _error = null;
    } catch (e) {
      _error = 'Piscina no encontrada';
    }
    notifyListeners();
  }

  /// Actualiza la lista de piscinas
  void setPools(List<Map<String, dynamic>> pools) {
    _pools = pools;
    notifyListeners();
  }

  /// Establece estado de carga
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Establece error
  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Limpia el error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Limpia todo (para logout)
  void clear() {
    _selectedPool = null;
    _pools = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
