// ✅ GUÍA: Cómo usar el Estado Global de Piscinas en Flutter
// 
// 1. En el Dashboard, carga las piscinas al iniciar:
// 
//    @override
//    void initState() {
//      super.initState();
//      final token = /* obtener del AuthService */;
//      DashboardHelper.loadPoolsAndSelectFirst(context, token);
//    }
//
// 2. Acceder a la piscina seleccionada en cualquier widget:
//
//    @override
//    Widget build(BuildContext context) {
//      return Consumer<PoolProvider>(
//        builder: (context, poolProvider, _) {
//          final selectedPool = poolProvider.selectedPool;
//          
//          if (selectedPool == null) {
//            return const Text('No hay piscina seleccionada');
//          }
//          
//          return Text('Piscina: ${selectedPool['nombre']}');
//        },
//      );
//    }
//
// 3. Cambiar la piscina seleccionada:
//
//    context.read<PoolProvider>().selectPoolById('POOL_002');
//    // O
//    context.read<PoolProvider>().selectPool(poolMap);
//
// 4. Acceder sin Consumer (menos observable, pero más simple):
//
//    final poolProvider = context.read<PoolProvider>();
//    final currentPool = poolProvider.selectedPool;
//
// 5. En un Dropdown para cambiar de piscina:
//
//    Consumer<PoolProvider>(
//      builder: (context, poolProvider, _) {
//        return DropdownButton(
//          items: poolProvider.pools
//              .map((pool) => DropdownMenuItem(
//                value: pool['pool_id'],
//                child: Text(pool['nombre']),
//              ))
//              .toList(),
//          onChanged: (poolId) {
//            poolProvider.selectPoolById(poolId);
//          },
//        );
//      },
//    )
//
// 6. Al desloguear, limpiar el estado:
//
//    context.read<PoolProvider>().clear();
//
// ============================================================
// MÉTODOS DEL POOLPROVIDER:
// ============================================================
//
// - setPoolsAndSelectFirst(List<Map>) → Carga y auto-selecciona 1era
// - selectPool(Map) → Manualmente selecciona una piscina
// - selectPoolById(String) → Selecciona por pool_id
// - setPools(List<Map>) → Actualiza lista de piscinas
// - setLoading(bool) → Establece estado de carga
// - setError(String) → Establece error
// - clearError() → Limpia el error
// - clear() → Limpia todo (para logout)
//
// ============================================================
// GETTERS DEL POOLPROVIDER:
// ============================================================
//
// - selectedPool: Map<String, dynamic>? → Piscina actualmente seleccionada
// - pools: List<Map<String, dynamic>> → Todas las piscinas del usuario
// - isLoading: bool → ¿Está cargando?
// - error: String? → Mensaje de error (si lo hay)
