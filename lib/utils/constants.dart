import 'package:flutter/material.dart';

class Constants {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  // Durations
  static const Duration autoRefreshInterval = Duration(seconds: 30); // Changed from 5 minutes to 30 seconds
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Notification channels
  static const String notificationChannelId = 'farmacia_channel';
  static const String notificationChannelName = 'Farmacia Notificaciones';
  static const String notificationChannelDescription = 'Notificaciones de la aplicación Farmacia';

  // Messages
  static const String noStockMessage = 'No hay suficiente stock disponible';
  static const String emptyCartMessage = 'Agrega productos al carrito para completar la venta';
  static const String saleCompletedMessage = 'Venta completada con éxito';
  static const String deleteConfirmMessage = '¿Estás seguro de que deseas eliminar este elemento? Esta acción no se puede deshacer.';
  static const String errorMessage = 'Ha ocurrido un error. Por favor, inténtalo de nuevo.';
  static const String successMessage = 'Operación completada con éxito';
  static const String loadingMessage = 'Cargando...';
  static const String noDataMessage = 'No hay datos disponibles';
  static const String sessionExpiredMessage = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';

  // Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String currencySymbol = 'Bs. ';  // Símbolo con espacio para bolivianos
  static const String usdCurrencySymbol = 'USD '; // Símbolo para dólares
  static const int currencyDecimalPlaces = 2;

  // Currency conversion (example rate)
  static const double usdToBolivianosRate = 6.96; // 1 USD = 6.96 Bs (example rate)

  // Limits
  static const int maxSearchResults = 50;
  static const int maxRecentItems = 10;
  static const int maxNotifications = 100;

  // Paths
  static const String assetsPath = 'assets/';
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';

  // Hive boxes
  static const String userBox = 'users';
  static const String medicationBox = 'medications';
  static const String shelfBox = 'shelves';
  static const String saleBox = 'sales';
  static const String settingsBox = 'settings';

  // Hive type IDs
  static const int userTypeId = 1;
  static const int medicationTypeId = 2;
  static const int shelfTypeId = 3;
  static const int saleTypeId = 4;
  static const int saleItemTypeId = 5;

  // Defaults
  static const int defaultPageSize = 20;
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 2.0;

  // Colores de estado - Usando colores pastel más elegantes
  static const Color expiredColor = Color(0xFFE57373); // Rojo pastel
  static const Color warningColor = Color(0xFFFFB74D); // Naranja pastel
  static const Color okColor = Color(0xFF81C784); // Verde pastel

  // Colores principales de la app - Nueva paleta de verdes pastel
  static const Color primaryColor = Color(0xFFA8D8B9); // Verde menta pastel
  static const Color secondaryColor = Color(0xFFD1E8D5); // Verde claro pastel
  static const Color accentColor = Color(0xFF6BAF92); // Verde medio pastel
  static const Color backgroundColor = Color(0xFFF1F8F2); // Fondo verde muy claro
  static const Color textColor = Color(0xFF2E5941); // Verde oscuro para texto
  static const Color shadowColor = Color(0x1A000000); // Sombra
  static const Color dividerColor = Color(0xFFE0E0E0); // Divisor

  // Niveles de inventario
  static const int lowStockThreshold = 5;
  static const int criticalStockThreshold = 2;

  // Configuración de ventas
  static const double taxRate = 0.13; // IVA Bolivia (13%)
  
  // Métodos de pago
  static const List<String> paymentMethods = [
    'Efectivo',
    'Tarjeta de crédito',
    'Tarjeta de débito',
    'Transferencia',
    'QR',
    'Otro',
  ];
  
  // Firebase collections
  static const String usersCollection = 'users';
  static const String medicationsCollection = 'medications';
  static const String shelvesCollection = 'shelves';
  static const String salesCollection = 'sales';
  static const String settingsCollection = 'settings';

  // App
  static const String appName = 'Farmacia App';
  static const String appVersion = '1.0.0';
  
  
  // Expiration periods (in days)
  static const int expirationWarningPeriod = 90; // 3 months
  static const int criticalExpirationPeriod = 30; // 1 month
  static const int urgentExpirationPeriod = 7; // 1 week
}
