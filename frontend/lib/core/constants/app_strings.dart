class AppStrings {
  AppStrings._();

  static const String appName = 'CleanPool';

  // Bienvenida (landing)
  static const String welcomeHeadline = 'Bienvenido';
  static const String welcomeTitle = 'Monitorea tu piscina con confianza';

  /// Párrafos del cuerpo (orden de lectura).
  static const List<String> welcomeBodyParagraphs = <String>[
    'CleanPool es una app diseñada para que cualquier persona pueda gestionar, '
        'mantener y cuidar su piscina de forma fácil y segura.',
    'Permite registrar lecturas de pH, cloro y temperatura del agua en tiempo casi real, '
        'entregando recomendaciones claras según el estado de la piscina. Así puedes saber cuándo '
        'ajustar químicos, limpiar, revisar el sistema de filtrado o tomar medidas preventivas.',
    'Además, CleanPool ayuda a organizar el inventario de productos, registrar mantenciones y '
        'consultar guías para resolver problemas frecuentes como agua turbia, algas o desbalances químicos.',
    'Con CleanPool, el mantenimiento de tu piscina deja de ser complicado y se vuelve simple, '
        'ordenado y eficiente.',
  ];

  static const String welcomeRegister = 'Registrarse';

  // Auth
  static const String login = 'Iniciar sesión';
  static const String register = 'Crear cuenta';
  static const String username = 'Nombre de usuario';
  static const String email = 'Correo electrónico';
  static const String password = 'Contraseña';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  static const String noAccount = '¿No tienes cuenta? ';
  static const String hasAccount = '¿Ya tienes cuenta? ';

  // Navbar
  static const String navDevice = 'Dispositivo';
  static const String navDashboard = 'Dashboard';
  static const String navProfile = 'Perfil';

  // Device
  static const String pairDevice = 'Vincular dispositivo';
  static const String noPairedDevice = 'Sin dispositivo vinculado';

  // Pool Registration
  static const String registerPool = 'Registrar piscina';
  static const String poolName = 'Nombre de la piscina';
  static const String poolVolume = 'Volumen (litros)';
  static const String poolType = 'Tipo de piscina';
  static const String poolLocation = 'Ubicación geográfica';
  static const String poolCreatedSuccess = 'Piscina registrada exitosamente';

  // General
  static const String loading = 'Cargando...';
  static const String error = 'Ocurrió un error';
  static const String retry = 'Reintentar';
}
