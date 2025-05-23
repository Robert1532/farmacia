import 'package:shared_preferences/shared_preferences.dart';

class CurrencyFormatter {
  static String _currencySymbol = 'Bs';
  static bool _showDecimals = true;
  static bool _symbolBefore = true;
  
  // Inicializar desde SharedPreferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString('currencySymbol') ?? 'Bs';
    _showDecimals = prefs.getBool('showDecimals') ?? true;
    _symbolBefore = prefs.getBool('symbolBefore') ?? true;
  }
  
  // Guardar configuración en SharedPreferences
  static Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currencySymbol', _currencySymbol);
    await prefs.setBool('showDecimals', _showDecimals);
    await prefs.setBool('symbolBefore', _symbolBefore);
  }
  
  // Formatear valor
  static String format(double value) {
    final valueStr = _showDecimals 
        ? value.toStringAsFixed(2) 
        : value.toStringAsFixed(0);
    
    return _symbolBefore 
        ? '$_currencySymbol$valueStr' 
        : '$valueStr $_currencySymbol';
  }
  
  // Cambiar símbolo de moneda
  static Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    await _saveSettings();
  }
  
  // Mostrar/ocultar decimales
  static Future<void> setShowDecimals(bool show) async {
    _showDecimals = show;
    await _saveSettings();
  }
  
  // Cambiar posición del símbolo
  static Future<void> setSymbolBefore(bool before) async {
    _symbolBefore = before;
    await _saveSettings();
  }
  

  // Getters
  static String get currencySymbol => _currencySymbol;
  static bool get showDecimals => _showDecimals;
  static bool get symbolBefore => _symbolBefore;
}
