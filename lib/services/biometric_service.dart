import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'secure_storage_service.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage = SecureStorageService();

  // Verificar si la biometría está disponible
  Future<bool> isBiometricAvailable() async {
    try {
      // En Windows, local_auth no funciona
      if (Platform.isWindows) {
        return false;
      }

      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Obtener tipos de biometría disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Autenticar con biometría
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      // En Windows, simular falla de autenticación
      if (Platform.isWindows) {
        return false;
      }

      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason ?? 'Autentica para acceder a tu cuenta',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  // Guardar credenciales de forma segura
  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _secureStorage.init();

      // Encriptar las credenciales
      final encryptedEmail = _encryptData(email);
      final encryptedPassword = _encryptData(password);

      await _secureStorage.write('biometric_email', encryptedEmail);
      await _secureStorage.write('biometric_password', encryptedPassword);
      // Guardar biometric_enabled sin encriptar para facilitar la lectura
      await _secureStorage.writePlain('biometric_enabled', 'true');
    } catch (e) {
      throw Exception('Error guardando credenciales: $e');
    }
  }

  // Obtener credenciales guardadas
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      await _secureStorage.init();

      final String? biometricEnabled = await _secureStorage.readPlain(
        'biometric_enabled',
      );
      if (biometricEnabled != 'true') return null;

      final String? encryptedEmail = await _secureStorage.read(
        'biometric_email',
      );
      final String? encryptedPassword = await _secureStorage.read(
        'biometric_password',
      );

      if (encryptedEmail == null || encryptedPassword == null) return null;

      final email = _decryptData(encryptedEmail);
      final password = _decryptData(encryptedPassword);
      return {'email': email, 'password': password};
    } catch (e) {
      return null;
    }
  }

  // Limpiar credenciales guardadas
  Future<void> clearSavedCredentials() async {
    try {
      await _secureStorage.init();
      await _secureStorage.delete('biometric_email');
      await _secureStorage.delete('biometric_password');
      await _secureStorage.delete('biometric_enabled');
      // También limpiar la versión plain
      await _secureStorage.deletePlain('biometric_enabled');
    } catch (e) {
      throw Exception('Error limpiando credenciales: $e');
    }
  }

  // Verificar si la biometría está habilitada
  Future<bool> isBiometricEnabled() async {
    try {
      await _secureStorage.init();
      final String? enabled = await _secureStorage.readPlain(
        'biometric_enabled',
      );
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  // Verificar si la biometría está habilitada (síncrono)
  bool isBiometricEnabledSync() {
    try {
      // En Windows, local_auth no funciona, retornar false
      if (Platform.isWindows) {
        return false;
      }
      // Para otras plataformas, verificar el estado real
      // Esta función se usa solo para UI, el estado real se verifica con isBiometricEnabled()
      return false; // Se actualizará cuando se llame isBiometricEnabled()
    } catch (e) {
      return false;
    }
  }

  // Habilitar/deshabilitar biometría
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.init();
      if (enabled) {
        await _secureStorage.writePlain('biometric_enabled', 'true');
      } else {
        await clearSavedCredentials();
      }
    } catch (e) {
      throw Exception('Error configurando biometría: $e');
    }
  }

  // Encriptar datos (método simple para este caso)
  String _encryptData(String data) {
    final bytes = utf8.encode(data);
    // Usar un hash simple basado en la longitud y contenido
    final hash = (data.length * 31 + data.codeUnitAt(0) * 17) % 100000;
    return base64.encode(bytes) + hash.toString().padLeft(5, '0');
  }

  // Desencriptar datos
  String _decryptData(String encryptedData) {
    try {
      // Método simple de desencriptación
      final decoded = base64.decode(
        encryptedData.substring(0, encryptedData.length - 5),
      );
      return utf8.decode(decoded);
    } catch (e) {
      throw Exception('Error desencriptando datos');
    }
  }

  // Obtener mensaje de error amigable
  String getErrorMessage(String error) {
    switch (error.toLowerCase()) {
      case 'notavailable':
        return 'La autenticación biométrica no está disponible en este dispositivo';
      case 'notenrolled':
        return 'No hay huellas dactilares o Face ID configurados';
      case 'lockedout':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'permanentlylockedout':
        return 'La autenticación biométrica está bloqueada permanentemente';
      case 'userCancel':
        return 'Autenticación cancelada';
      case 'systemcancel':
        return 'Autenticación cancelada por el sistema';
      case 'passcodeNotSet':
        return 'No hay código de acceso configurado';
      case 'fingerprintNotEnrolled':
        return 'No hay huellas dactilares registradas';
      case 'faceIdNotEnrolled':
        return 'Face ID no está configurado';
      default:
        return 'Error de autenticación biométrica';
    }
  }
}
