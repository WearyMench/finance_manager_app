import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';

/// Servicio centralizado para manejar el cambio de usuario
/// Asegura que todos los datos se limpien correctamente cuando cambia el usuario
class UserChangeService {
  /// Limpia todos los datos del usuario anterior
  /// Debe llamarse antes de establecer un nuevo usuario
  static Future<void> clearPreviousUserData(BuildContext context) async {
    try {
      // Obtener los providers
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      // Limpiar datos del AuthProvider
      await authProvider.clearUserData();

      // Limpiar datos del TransactionProvider
      transactionProvider.clearUserDataOnUserChange();

      print('✅ Datos del usuario anterior limpiados correctamente');
    } catch (e) {
      print('❌ Error limpiando datos del usuario anterior: $e');
    }
  }

  /// Establece un nuevo usuario después de limpiar los datos anteriores
  static Future<void> setNewUser(BuildContext context, dynamic user) async {
    try {
      // Limpiar datos del usuario anterior
      await clearPreviousUserData(context);

      // El AuthProvider ya maneja la lógica de establecer el nuevo usuario
      print('✅ Nuevo usuario establecido correctamente');
    } catch (e) {
      print('❌ Error estableciendo nuevo usuario: $e');
    }
  }
}
