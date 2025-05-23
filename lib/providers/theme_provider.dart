import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  
  ThemeProvider() {
    _loadThemeMode();
  }

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Load theme mode from Firestore
  Future<void> _loadThemeMode() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          _isDarkMode = doc.data()?['isDarkMode'] ?? false;
        }
      }
    } catch (e) {
      // Si hay un error, usar tema claro por defecto
      _isDarkMode = false;
    }
    notifyListeners();
  }

  // Toggle theme mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .set({
              'isDarkMode': _isDarkMode,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      // Manejar error silenciosamente
    }
  }

  // Set specific theme mode
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    
    _isDarkMode = isDark;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .set({
              'isDarkMode': _isDarkMode,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      // Manejar error silenciosamente
    }
  }
}
