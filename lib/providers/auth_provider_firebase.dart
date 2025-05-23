import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_firebase.dart';
import '../services/firebase_service.dart';

class AuthProviderFirebase with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  UserFirebase? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';
  
  UserFirebase? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  
  AuthProviderFirebase() {
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Escuchar cambios en el estado de autenticación
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          await _loadUserData(user.uid);
        } else {
          _currentUser = null;
          notifyListeners();
        }
      });
    } catch (e) {
      _errorMessage = e.toString();
      _currentUser = null;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadUserData(String userId) async {
    try {
      final userDoc = await _firebaseService.usersCollection.doc(userId).get();
      
      if (userDoc.exists) {
        _currentUser = UserFirebase.fromFirestore(userDoc);
      } else {
        _currentUser = null;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _currentUser = null;
      notifyListeners();
    }
  }
  
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      await _firebaseService.signInWithEmailAndPassword(email, password);
      return true;
    } catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _currentUser = null;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> register(String name, String email, String password, {UserRole role = UserRole.employee}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _firebaseService.createUserWithEmailAndPassword(email, password);
      
      // Crear documento de usuario en Firestore
      final user = UserFirebase(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firebaseService.usersCollection.doc(user.id).set(user.toFirestore());
      
      return true;
    } catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateUserProfile({required String name, String? phone}) async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Actualizar solo los campos permitidos
      final userToUpdate = _currentUser!.copyWith(
        name: name,
        phone: phone,
        updatedAt: DateTime.now(),
      );
      
      await _firebaseService.usersCollection.doc(_currentUser!.id).update(userToUpdate.toFirestore());
      
      _currentUser = userToUpdate;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      await _firebaseService.changePassword(currentPassword, newPassword);
      return true;
    } catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      await _firebaseService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firebaseService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Método para verificar si el usuario actual es administrador
  Future<bool> checkAuth() async {
    if (_currentUser == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _loadUserData(user.uid);
      }
    }
    return _currentUser != null;
  }
  
  // Método para obtener todos los usuarios (solo para administradores)
  Future<List<UserFirebase>> getAllUsers() async {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      throw Exception('No tienes permisos para realizar esta acción');
    }
    
    try {
      final querySnapshot = await _firebaseService.usersCollection.get();
      return querySnapshot.docs
          .map((doc) => UserFirebase.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }
  
  // Método para crear un nuevo usuario (solo para administradores)
  Future<bool> createUser(String name, String email, String password, UserRole role) async {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      _errorMessage = 'No tienes permisos para realizar esta acción';
      notifyListeners();
      return false;
    }
    
    return register(name, email, password, role: role);
  }
  
  // Método para actualizar un usuario (solo para administradores)
  Future<bool> updateUser(UserFirebase user) async {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      _errorMessage = 'No tienes permisos para realizar esta acción';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      await _firebaseService.usersCollection.doc(user.id).update(user.toFirestore());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<UserFirebase?> getUserById(String userId) async {
  try {
    final userDoc = await _firebaseService.usersCollection.doc(userId).get();
    
    if (userDoc.exists) {
      return UserFirebase.fromFirestore(userDoc);
    } else {
      return null;
    }
  } catch (e) {
    _errorMessage = e.toString();
    notifyListeners();
    return null;
  }
}
  // Método para eliminar un usuario (solo para administradores)
  Future<bool> deleteUser(String userId) async {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      _errorMessage = 'No tienes permisos para realizar esta acción';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Marcar como inactivo en lugar de eliminar
      await _firebaseService.usersCollection.doc(userId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Método para cerrar sesión (alias para signOut)
  Future<void> logout() async {
    await signOut();
  }
  
  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No existe un usuario con este correo electrónico';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'email-already-in-use':
          return 'Este correo electrónico ya está en uso';
        case 'weak-password':
          return 'La contraseña es demasiado débil';
        case 'invalid-email':
          return 'El correo electrónico no es válido';
        case 'requires-recent-login':
          return 'Esta operación es sensible y requiere autenticación reciente';
        default:
          return error.message ?? 'Error de autenticación desconocido';
      }
    }
    return error.toString();
  }
}
