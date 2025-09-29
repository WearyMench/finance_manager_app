import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../models/api_models.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final BiometricService _biometricService = BiometricService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _biometricEnabled = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _apiService.isAuthenticated;
  bool get biometricEnabled => _biometricEnabled;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Asegurar que el token esté cargado antes de verificar
      await _apiService.ensureTokenLoaded();

      if (_apiService.isAuthenticated) {
        // Primero verificar si el token es válido
        final isTokenValid = await _apiService.isTokenValid();

        if (isTokenValid) {
          // Si el token es válido, obtener los datos del usuario
          final response = await _apiService.getCurrentUser();

          if (response.success && response.data != null) {
            _user = response.data;
            _error = null;
            // Usuario autenticado exitosamente
          } else {
            // Si no se pueden obtener los datos del usuario, hacer logout
            await logout();
          }
        } else {
          // Token inválido o expirado, hacer logout
          await logout();
        }
      }

      // Cargar estado de biometría
      _biometricEnabled = await _biometricService.isBiometricEnabled();
    } catch (e) {
      _error = 'Error al inicializar: $e';
      // En caso de error, no hacer logout automático para evitar problemas de red
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      // Limpiar datos del usuario anterior antes de hacer login
      await _clearUserData();

      // Validación básica antes de hacer la petición
      if (email.trim().isEmpty) {
        _error = 'El email es requerido';
        return false;
      }
      if (password.isEmpty) {
        _error = 'La contraseña es requerida';
        return false;
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
        _error = 'Por favor ingresa un email válido';
        return false;
      }

      final response = await _apiService.login(email.trim(), password);
      if (response.success && response.data != null) {
        _user = response.data!.user;
        _error = null;

        // Guardar credenciales para biometría
        await _biometricService.saveCredentials(
          email: email.trim(),
          password: password,
        );
        notifyListeners();
        return true;
      } else {
        // Manejo específico de errores del servidor
        if (response.message != null) {
          if (response.message!.contains('Invalid credentials') ||
              response.message!.contains('Credenciales inválidas')) {
            _error = 'Email o contraseña incorrectos';
          } else if (response.message!.contains('User not found') ||
              response.message!.contains('Usuario no encontrado')) {
            _error = 'No existe una cuenta con este email';
          } else if (response.message!.contains('Account disabled') ||
              response.message!.contains('Cuenta deshabilitada')) {
            _error = 'Tu cuenta ha sido deshabilitada. Contacta al soporte';
          } else {
            _error = response.message!;
          }
        } else {
          _error = 'Error al iniciar sesión. Inténtalo nuevamente';
        }
        return false;
      }
    } catch (e) {
      // Manejo específico de errores de conexión
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('no address associated with hostname')) {
        _error = 'Sin conexión a internet. Verifica tu red';
      } else if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection timed out')) {
        _error = 'Servidor no disponible. Inténtalo más tarde';
      } else if (e.toString().contains('TimeoutException')) {
        _error = 'La conexión tardó demasiado. Inténtalo nuevamente';
      } else {
        _error = 'Error de conexión. Verifica tu internet';
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String currency = 'USD',
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        currency: currency,
      );

      if (response.success && response.data != null) {
        _user = response.data!.user;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Error al registrarse';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    // Limpiar todos los datos del usuario
    await _clearUserData();
  }

  Future<bool> updateProfile({String? name, String? currency}) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.updateProfile(
        name: name,
        currency: currency,
      );

      if (response.success && response.data != null) {
        _user = response.data;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Error al actualizar el perfil';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (response.success) {
        return true;
      } else {
        _error = response.message ?? 'Error al cambiar la contraseña';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateNotificationSettings({
    bool? budgetReminders,
    bool? weeklySummary,
    bool? savingGoals,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.updateNotificationSettings(
        budgetReminders: budgetReminders,
        weeklySummary: weeklySummary,
        savingGoals: savingGoals,
      );

      if (response.success) {
        // Refresh user data to get updated notification settings
        await initialize();
        return true;
      } else {
        _error = response.message ?? 'Error al actualizar las notificaciones';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAccount({required String password}) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.deleteUserAccount(password: password);

      if (response.success) {
        // Clear local data
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('authToken');

        _user = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Error al eliminar la cuenta';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Verificar periódicamente si el token sigue siendo válido
  Future<void> checkTokenValidity() async {
    if (_user != null && _apiService.isAuthenticated) {
      final isTokenValid = await _apiService.isTokenValid();
      if (!isTokenValid) {
        // Token expirado y no se pudo renovar, hacer logout automático
        await logout();
        _error = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
        notifyListeners();
      }
    }
  }

  // Renovar token manualmente
  Future<bool> refreshToken() async {
    if (!_apiService.isAuthenticated) return false;

    try {
      final refreshed = await _apiService.refreshToken();
      if (refreshed) {
        // Token renovado exitosamente, obtener datos actualizados del usuario
        final response = await _apiService.getCurrentUser();
        if (response.success && response.data != null) {
          _user = response.data;
          _error = null;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Método para verificar la validez del token antes de operaciones críticas
  Future<bool> ensureValidToken() async {
    if (!_apiService.isAuthenticated) return false;

    final isTokenValid = await _apiService.isTokenValid();
    if (!isTokenValid) {
      await logout();
      _error = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
      notifyListeners();
      return false;
    }
    return true;
  }

  // Métodos para biometría
  Future<bool> isBiometricAvailable() async {
    return await _biometricService.isBiometricAvailable();
  }

  Future<bool> isBiometricEnabled() async {
    return await _biometricService.isBiometricEnabled();
  }

  Future<void> enableBiometric(String email, String password) async {
    try {
      await _biometricService.saveCredentials(email: email, password: password);
      _biometricEnabled = true;
      notifyListeners(); // Notificar éxito
    } catch (e) {
      _error = 'Error habilitando biometría: $e';
      notifyListeners();
    }
  }

  Future<void> disableBiometric() async {
    try {
      await _biometricService.clearSavedCredentials();
      _biometricEnabled = false;
      notifyListeners(); // Notificar éxito
    } catch (e) {
      _error = 'Error deshabilitando biometría: $e';
      notifyListeners();
    }
  }

  Future<Map<String, String>?> getBiometricCredentials() async {
    return await _biometricService.getSavedCredentials();
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _biometricService.authenticateWithBiometrics();
    } catch (e) {
      _error = _biometricService.getErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithBiometric() async {
    _setLoading(true);
    _error = null;

    try {
      // Limpiar datos del usuario anterior antes de hacer login biométrico
      await _clearUserData();

      // Verificar disponibilidad primero
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        _error =
            'La autenticación biométrica no está disponible en este dispositivo';
        return false;
      }

      // Verificar si está habilitada
      final isEnabled = await _biometricService.isBiometricEnabled();
      if (!isEnabled) {
        _error =
            'La autenticación biométrica no está configurada. Ve a Configuración para habilitarla.';
        return false;
      }

      // Primero validar la biometría
      final biometricSuccess = await _biometricService
          .authenticateWithBiometrics(
            reason: 'Autentica para acceder a tu cuenta',
          );

      if (!biometricSuccess) {
        _error = 'Autenticación biométrica cancelada o fallida';
        return false;
      }

      // Si la biometría es exitosa, obtener credenciales y hacer login
      final credentials = await _biometricService.getSavedCredentials();
      if (credentials == null) {
        _error =
            'No hay credenciales biométricas guardadas. Ve a Configuración para configurar la biometría.';
        return false;
      }

      // Usar método interno que no guarda credenciales
      final success = await _loginInternal(
        credentials['email']!,
        credentials['password']!,
      );

      return success;
    } catch (e) {
      _error =
          'Error en autenticación biométrica: ${_biometricService.getErrorMessage(e.toString())}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Método interno de login sin guardar credenciales
  Future<bool> _loginInternal(String email, String password) async {
    try {
      // Validación básica antes de hacer la petición
      if (email.trim().isEmpty) {
        _error = 'El email es requerido';
        return false;
      }
      if (password.isEmpty) {
        _error = 'La contraseña es requerida';
        return false;
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
        _error = 'Por favor ingresa un email válido';
        return false;
      }

      final response = await _apiService.login(email.trim(), password);

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _error = null;
        notifyListeners();

        // Pequeño delay para evitar rebuilds muy rápidos
        await Future.delayed(const Duration(milliseconds: 100));

        return true;
      } else {
        // Manejo específico de errores del servidor
        if (response.message != null) {
          if (response.message!.contains('Invalid credentials') ||
              response.message!.contains('Credenciales inválidas')) {
            _error = 'Email o contraseña incorrectos';
          } else if (response.message!.contains('User not found') ||
              response.message!.contains('Usuario no encontrado')) {
            _error = 'No existe una cuenta con este email';
          } else if (response.message!.contains('Account disabled') ||
              response.message!.contains('Cuenta deshabilitada')) {
            _error = 'Tu cuenta ha sido deshabilitada. Contacta al soporte.';
          } else {
            _error = response.message!;
          }
        } else {
          _error =
              'Error de conexión. Verifica tu internet e intenta nuevamente.';
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      // Asegurar que isLoading se establezca en false
      _setLoading(false);
    }
  }

  Future<bool> verifyEmail(String code) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.verifyEmail(code);

      if (response.success && response.data != null) {
        // Limpiar datos del usuario anterior antes de establecer el nuevo usuario
        await _clearUserData();

        _user = response.data!.user;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Código de verificación inválido';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendVerificationCode() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.resendVerificationCode();

      if (response.success) {
        return true;
      } else {
        _error = response.message ?? 'Error al reenviar código de verificación';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.forgotPassword(email);

      if (response.success) {
        return true;
      } else {
        _error = response.message ?? 'Error al enviar código de recuperación';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      if (response.success) {
        return true;
      } else {
        _error = response.message ?? 'Error al restablecer contraseña';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Método privado para limpiar datos del usuario anterior
  Future<void> _clearUserData() async {
    try {
      // Limpiar datos locales del AuthProvider
      _user = null;
      _error = null;
      _isLoading = false;

      // Limpiar token y credenciales almacenadas
      await _apiService.logout();

      // Limpiar credenciales biométricas
      await _biometricService.clearSavedCredentials();

      // Notificar a los listeners que los datos han cambiado
      notifyListeners();
    } catch (e) {
      // No mostrar error si falla la limpieza
      print('Error limpiando datos del usuario: $e');
    }
  }

  // Método público para limpiar datos del usuario (para uso desde UI)
  Future<void> clearUserData() async {
    await _clearUserData();
  }
}
