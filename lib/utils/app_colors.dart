import 'package:flutter/material.dart';

class AppColors {
  // Colores principales - Nueva paleta de verdes pastel
  static const Color primaryColor = Color(0xFFA8D8B9); // Verde menta pastel
  static const Color primary = Color(0xFFA8D8B9); // Verde menta pastel
  static const Color secondaryColor = Color(0xFFD1E8D5); // Verde claro pastel
  static const Color accentColor = Color(0xFF6BAF92); // Verde medio pastel
  static const Color highlightColor = Color(0xFFFFB74D); // Naranja pastel
  static const Color backgroundColor = Color(0xFFF1F8F2); // Fondo verde muy claro
  static const Color textColor = Color(0xFF2E5941); // Verde oscuro para texto
  
  // Colores de estado
  static const Color expiringSoon = Color(0xFFFFB74D); // Naranja pastel
  static const Color expiringMonth = Color(0xFFFFD54F); // Amarillo pastel
  static const Color expiringTwoMonths = Color(0xFFFFE082); // Amarillo claro pastel
  static const Color expiringThreeMonths = Color(0xFFA5D6A7); // Verde claro pastel
  static const Color success = Color(0xFF81C784); // Verde pastel
  static const Color warning = Color(0xFFFFB74D); // Naranja pastel
  static const Color error = Color(0xFFE57373); // Rojo pastel
  static const Color danger = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Colores adicionales
  static const Color shadowColor = Color(0x1A000000); // Sombra
  static const Color dividerColor = Color(0xFFE0E0E0); // Divisor
  static const Color cardColor = Colors.white; // Fondo de tarjetas
  static const Color disabledColor = Color(0xFFBDBDBD); // Color deshabilitado
  static const Color surfaceColor = Color(0xFFF5F5F5);

  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textLightColor = Color(0xFFBDBDBD);
  
  // Colores de borde
  static const Color borderColor = Color(0xFFE0E0E0);
  
  // Colores para modo oscuro
  static const Color darkPrimary = Color(0xFF388E3C);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFEEEEEE);

  
  // Colores de fondo
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  // Colores de borde
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFE0E0E0);
  
  // Colores de sombra
  static const Color shadow = Color(0x1F000000);
  
  // Colores de overlay
  static const Color overlay = Color(0x80000000);
  
  // Colores para gráficos
  static const List<Color> chartColors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF009688),
    Color(0xFFFF9800),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];
   // Colores para caducidad
  static const Color expired = Color(0xFFE53935);
  static const Color expiringInMonth = Color(0xFFFF9800);
  static const Color expiringInTwoMonths = Color(0xFFFFEB3B);
  static const Color expiringInThreeMonths = Color(0xFF8BC34A);
  
   static Color getExpirationColor(bool isExpired, bool isExpiringSoon, bool isExpiringInMonth, bool isExpiringInTwoMonths, bool isExpiringInThreeMonths) {
    if (isExpired) {
      return expired;
    } else if (isExpiringSoon) {
      return expiringSoon;
    } else if (isExpiringInMonth) {
      return expiringInMonth;
    } else if (isExpiringInTwoMonths) {
      return expiringInTwoMonths;
    } else if (isExpiringInThreeMonths) {
      return expiringInThreeMonths;
    } else {
      return success;
    }
  }

  static const Color secondary = Color(0xFF03A9F4);
  static const Color accent = Color(0xFF00BCD4);

  // Colores de fondo
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF303030);
}
