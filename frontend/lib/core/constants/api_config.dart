class ApiConfig {
  static const String _defaultApiUrl =
      'https://software2-backend-hxe7f4b9dug6dqat.eastus2-01.azurewebsites.net';

  static const String _rawApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: _defaultApiUrl,
  );

  /// URL base del backend, saneada para evitar errores de build/env.
  static String get baseUrl {
    final value = _rawApiUrl.trim();
    if (value.isEmpty) return _defaultApiUrl;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
