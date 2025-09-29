import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> write(String key, String value) async {
    await _ensureInitialized();
    // No encriptar aquí, ya viene encriptado desde BiometricService
    await _prefs!.setString('secure_$key', value);
  }

  // Escribir sin encriptar (para flags booleanos)
  Future<void> writePlain(String key, String value) async {
    await _ensureInitialized();
    await _prefs!.setString('plain_$key', value);
  }

  Future<String?> read(String key) async {
    await _ensureInitialized();
    final value = _prefs!.getString('secure_$key');
    if (value == null) return null;
    // No desencriptar aquí, ya viene desencriptado desde BiometricService
    return value;
  }

  // Leer sin desencriptar (para flags booleanos)
  Future<String?> readPlain(String key) async {
    await _ensureInitialized();
    return _prefs!.getString('plain_$key');
  }

  Future<void> delete(String key) async {
    await _ensureInitialized();
    await _prefs!.remove('secure_$key');
  }

  // Eliminar clave plain
  Future<void> deletePlain(String key) async {
    await _ensureInitialized();
    await _prefs!.remove('plain_$key');
  }

  Future<void> deleteAll() async {
    await _ensureInitialized();
    final keys = _prefs!.getKeys().where((key) => key.startsWith('secure_'));
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
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
      final decoded = base64.decode(
        encryptedData.substring(0, encryptedData.length - 5),
      );
      return utf8.decode(decoded);
    } catch (e) {
      throw Exception('Error desencriptando datos');
    }
  }
}
