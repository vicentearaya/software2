class AppStrings {
  AppStrings._();

  static const String appName = 'CleanPool';

  // Bienvenida (landing)
  static const String welcomeHeadline = 'Bienvenido';
  static const String welcomeTitle = 'Monitorea tu piscina con confianza';

  static const String welcomeAppIntro =
      'CleanPool te ayuda a cuidar el agua de tu piscina con lecturas, '
      'alertas y recomendaciones claras — sin ser experto en química.';

  static const String welcomeFunctionsTitle = '¿Qué puedes hacer?';

  static const List<String> welcomeFunctions = <String>[
    'Ver el estado del agua (pH, cloro y temperatura) en el dashboard.',
    'Recibir recomendaciones según la aptitud del agua y calcular tratamientos.',
    'Vincular un sensor IoT y consultar si el dispositivo está en línea.',
    'Gestionar el inventario de productos químicos y registrar su uso.',
    'Consultar guías para problemas frecuentes (turbiedad, algas, filtro).',
    'Revisar el historial de mantenciones desde tu perfil.',
  ];

  static const String welcomeSolvesTitle = '¿Qué problemas resuelve?';

  static const List<String> welcomeSolves = <String>[
    'Evita tratar el agua a ciegas o en el momento equivocado.',
    'Reduce desbalances químicos que causan irritación o agua turbia.',
    'Centraliza inventario y mantenciones en un solo lugar.',
  ];

  // Tarjetas educativas — pH
  static const String welcomePhTitle = 'pH del agua';
  static const String welcomePhWhat =
      'Indica si el agua es ácida o alcalina. En piscinas se busca un rango '
      'cercano al neutro para que el cloro actúe bien y la piel no se irrite.';
  static const String welcomePhMeasure =
      'Se mide con tiras reactivas, kit líquido de prueba o sensor digital. '
      'La escala va de 0 a 14.';
  static const String welcomePhIndicates =
      'Ideal: 7,2 – 7,6. Por debajo: agua ácida (irritación, corrosión). '
      'Por encima: agua alcalina (turbiedad, cloro menos eficaz).';

  // Tarjetas educativas — cloro
  static const String welcomeChlorineTitle = 'Cloro libre';
  static const String welcomeChlorineWhat =
      'Desinfectante principal: elimina bacterias, virus y algas. '
      'El “cloro libre” es el que aún puede desinfectar.';
  static const String welcomeChlorineMeasure =
      'Se mide en ppm (partes por millón) o mg/L con tiras o kit de prueba, '
      'o con un sensor acoplado al dispositivo.';
  static const String welcomeChlorineIndicates =
      'Ideal: 1 – 3 ppm. Bajo: riesgo microbiológico y agua verde. '
      'Alto: olor fuerte e irritación en ojos y piel.';

  static const String welcomeCardWhat = 'Qué es';
  static const String welcomeCardMeasure = 'Cómo se mide';
  static const String welcomeCardIndicates = 'Qué indica';

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
