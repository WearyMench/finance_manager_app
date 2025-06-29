// Paleta de colores para la app Gestor de Gastos
import 'package:flutter/material.dart';

class AppColors {
  // Colores principales - Modo claro
  static const Color primaryLight = Color(0xFF2196F3);
  static const Color secondaryLight = Color(0xFF03DAC6);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFB00020);

  // Colores principales - Modo oscuro (MEJORADOS)
  static const Color primaryDark = Color(
    0xFF64B5F6,
  ); // Azul más claro y vibrante
  static const Color secondaryDark = Color(0xFF81C784); // Verde más suave
  static const Color primaryVariantDark = Color(
    0xFF1976D2,
  ); // Azul más profundo
  static const Color backgroundDark = Color(0xFF121212); // Negro puro
  static const Color surfaceDark = Color(0xFF1E1E1E); // Gris muy oscuro
  static const Color cardDark = Color(0xFF2D2D2D); // Gris oscuro para tarjetas
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Blanco puro
  static const Color textSecondaryDark = Color(0xFFB3B3B3); // Gris claro
  static const Color borderDark = Color(0xFF424242); // Gris medio para bordes

  // Nuevos colores para modo oscuro
  static const Color inputBackgroundDark = Color(
    0xFF2A2A2A,
  ); // Fondo para inputs
  static const Color inputBorderDark = Color(0xFF555555); // Bordes para inputs
  static const Color dialogBackgroundDark = Color(
    0xFF2D2D2D,
  ); // Fondo para diálogos
  static const Color dividerDark = Color(0xFF424242); // Divisores

  // Colores de categorías (MEJORADOS para modo oscuro)
  static const Color categoryOrange = Color(0xFFFF9800);
  static const Color categoryBlue = Color(0xFF2196F3);
  static const Color categoryPurple = Color(0xFF9C27B0);
  static const Color categoryGreen = Color(0xFF4CAF50);
  static const Color categoryPink = Color(0xFFE91E63);
  static const Color categoryTeal = Color(0xFF009688);
  static const Color categoryIndigo = Color(0xFF3F51B5);
  static const Color categoryAmber = Color(0xFFFFC107);
  static const Color categoryGrey = Color(0xFF9E9E9E);

  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Métodos para obtener colores dinámicos basados en el tema
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? primaryLight
        : primaryDark;
  }

  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? secondaryLight
        : secondaryDark;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? backgroundLight
        : backgroundDark;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? surfaceLight
        : surfaceDark;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? cardLight
        : cardDark;
  }

  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textPrimaryLight
        : textPrimaryDark;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textSecondaryLight
        : textSecondaryDark;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? borderLight
        : borderDark;
  }

  static Color getErrorColor(BuildContext context) {
    return error;
  }

  // Nuevos métodos para inputs y formularios
  static Color getInputBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? surfaceLight
        : inputBackgroundDark;
  }

  static Color getInputBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? borderLight
        : inputBorderDark;
  }

  static Color getDialogBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? surfaceLight
        : dialogBackgroundDark;
  }

  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? borderLight
        : dividerDark;
  }

  // Colores con opacidad
  static Color getWhiteWithOpacity(double opacity) {
    return Colors.white.withOpacity(opacity);
  }

  static Color getBlackWithOpacity(double opacity) {
    return Colors.black.withOpacity(opacity);
  }

  static Color getGreyWithOpacity(double opacity) {
    return Colors.grey.withOpacity(opacity);
  }

  // Colores de categorías con opacidad
  static Color getCategoryColorWithOpacity(String category, double opacity) {
    final baseColor = getCategoryColor(category);
    return baseColor.withOpacity(opacity);
  }

  // Método para obtener color de categoría
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'comida':
      case 'alimentación':
        return categoryOrange;
      case 'transporte':
      case 'gasolina':
        return categoryBlue;
      case 'entretenimiento':
      case 'ocio':
        return categoryPurple;
      case 'salud':
      case 'médico':
        return categoryGreen;
      case 'ropa':
      case 'vestimenta':
        return categoryPink;
      case 'servicios':
      case 'utilities':
        return categoryTeal;
      case 'educación':
      case 'estudios':
        return categoryIndigo;
      case 'otros':
      case 'misceláneos':
        return categoryAmber;
      default:
        return categoryGrey;
    }
  }

  // Lista de colores para gráficos
  static List<Color> getChartColors() {
    return [
      categoryOrange,
      categoryBlue,
      categoryPurple,
      categoryGreen,
      categoryPink,
      categoryTeal,
      categoryIndigo,
      categoryAmber,
    ];
  }

  // Colores de estado con contexto
  static Color getSuccessColor(BuildContext context) {
    return success;
  }

  static Color getWarningColor(BuildContext context) {
    return warning;
  }

  static Color getDangerColor(BuildContext context) {
    return danger;
  }

  static Color getInfoColor(BuildContext context) {
    return info;
  }

  // Colores de gradiente
  static List<Color> getPrimaryGradient(BuildContext context) {
    final primary = getPrimaryColor(context);
    return [primary, primary.withOpacity(0.8)];
  }

  static List<Color> getSuccessGradient(BuildContext context) {
    return [success, success.withOpacity(0.8)];
  }

  static List<Color> getInfoGradient(BuildContext context) {
    return [info, info.withOpacity(0.8)];
  }

  // Colores para recurrencia
  static Color getRecurrenceColor(String option) {
    switch (option.toLowerCase()) {
      case 'semanal':
        return categoryBlue;
      case 'quincenal':
        return categoryPurple;
      case 'mensual':
        return categoryGreen;
      case 'anual':
        return categoryOrange;
      default:
        return categoryGrey;
    }
  }
}
