import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static bool _showInUSD = false;
  static double _exchangeRate = 6.96; // Tasa de cambio aproximada Bs a USD
  
  static final NumberFormat _bsFormat = NumberFormat.currency(
    locale: 'es_BO',
    symbol: 'Bs. ',
    decimalDigits: 2,
  );
  
  static final NumberFormat _usdFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  // Constructor para mantener compatibilidad con código existente
  CurrencyFormatter(BuildContext context, {bool isUSD = false}) {
    _showInUSD = isUSD;
  }

  // Getter para la tasa de cambio
  static double get exchangeRate => _exchangeRate;

  // Método para actualizar la tasa de cambio
  static void updateExchangeRate(double newRate) {
    _exchangeRate = newRate;
  }

  // Método estático para formatear moneda
  static String format(double value) {
    if (_showInUSD) {
      // Convertir de Bs a USD
      final usdValue = value / _exchangeRate;
      return _usdFormat.format(usdValue);
    } else {
      return _bsFormat.format(value);
    }
  }

  // Método específico para formatear en Bs
  static String formatBs(double value) {
    return _bsFormat.format(value);
  }

  // Método específico para formatear en USD
  static String formatUSD(double value) {
    final usdValue = value / _exchangeRate;
    return _usdFormat.format(usdValue);
  }

  // Método para cambiar la moneda
  static void toggleCurrency(bool showUSD) {
    _showInUSD = showUSD;
  }
}
