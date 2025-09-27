import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _apiService.isAuthenticated;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      if (_apiService.isAuthenticated) {
        final response = await _apiService.getCurrentUser();
        if (response.success && response.data != null) {
          _user = response.data;
          _error = null;
        } else {
          await logout();
        }
      }
    } catch (e) {
      _error = 'Error al inicializar: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

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
    await _apiService.logout();
    _user = null;
    _error = null;
    notifyListeners();
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
}
