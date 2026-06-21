import 'package:flutter/material.dart';
import '../../core/utils/app_utils.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/pool_service.dart';
import '../dashboard/pool_data.dart';
import '../dashboard/widgets/add_pool_screen.dart';

/// Screen for registering a pool (Deprecated - use [AddPoolScreen] instead).
@deprecated
class RegisterPoolScreen extends StatelessWidget {
  const RegisterPoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AddPoolScreen(
      onSave: (PoolData pool) async {
        final token = await AuthService().getToken();
        if (token == null) {
          if (context.mounted) {
            AppUtils.showSnackBar(context, 'Sesión expirada', isError: true);
          }
          return;
        }

        final payload = {
          'nombre': pool.nombre,
          'volumen': pool.volumenM3,
          'tipo': pool.esInterior ? 'interior' : 'exterior',
          'ubicacion': '',
          'largo': pool.largo,
          'ancho': pool.ancho,
          'profundidad': pool.profundidad,
          'filtro': pool.tieneFiltro,
          'forma': pool.forma,
          'volumen_origen': pool.volumenOrigen,
          'volumen_estimado': pool.volumenEstimado,
          'dimensiones': pool.dimensiones,
        };

        final result = await PoolService().createPool(payload, token);

        if (context.mounted) {
          if (result['success'] == true) {
            AppUtils.showSnackBar(context, 'Piscina creada exitosamente');
            Navigator.pop(context);
          } else {
            AppUtils.showSnackBar(
              context,
              result['message'] ?? 'Error al crear piscina',
              isError: true,
            );
          }
        }
      },
    );
  }
}
