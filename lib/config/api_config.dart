class ApiConfig {
  // Configuración de la API
  static const String _devUrl = 'http://localhost:5000/api';
  static const String _prodUrl =
      'https://expenses.lynimo.com/api'; // URL de producción

  // Cambia esto a 'production' cuando quieras compilar para producción
  static const String _environment = 'production';

  static String get baseUrl {
    switch (_environment) {
      case 'production':
        return _prodUrl;
      case 'development':
      default:
        return _devUrl;
    }
  }

  // URLs específicas para diferentes entornos
  static const Map<String, String> environments = {
    'development': 'http://localhost:5000/api',
    'production': 'https://expenses.lynimo.com/api',
    // Puedes agregar más entornos aquí
    'staging': 'https://staging-expenses.lynimo.com/api',
  };

  // Método para cambiar el entorno dinámicamente
  static String getUrlForEnvironment(String environment) {
    return environments[environment] ?? _devUrl;
  }
}
