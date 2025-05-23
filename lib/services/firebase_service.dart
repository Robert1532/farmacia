import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  factory FirebaseService() => _instance;
  
  FirebaseService._internal();
  
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  // Colecciones
  CollectionReference get usersCollection => firestore.collection('users');
  CollectionReference get medicationsCollection => firestore.collection('medications');
  CollectionReference get shelvesCollection => firestore.collection('shelves');
  CollectionReference get salesCollection => firestore.collection('sales');
  CollectionReference get saleItemsCollection => firestore.collection('sale_items');
  
  // Inicialización
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Configurar persistencia para modo offline
      await firestore.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
      
      print('Firebase inicializado correctamente');
    } catch (e) {
      print('Error al inicializar Firebase: $e');
      rethrow;
    }
  }
  
  // Autenticación
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error al iniciar sesión: $e');
      rethrow;
    }
  }
  
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error al crear usuario: $e');
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
      rethrow;
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error al enviar correo de recuperación: $e');
      rethrow;
    }
  }
  
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');
      
      // Reautenticar usuario
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Cambiar contraseña
      await user.updatePassword(newPassword);
    } catch (e) {
      print('Error al cambiar contraseña: $e');
      rethrow;
    }
  }
  
  // Verificar si el usuario actual es administrador
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = auth.currentUser;
      if (user == null) return false;
      
      final userDoc = await usersCollection.doc(user.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['role'] == 'admin';
    } catch (e) {
      print('Error al verificar rol de usuario: $e');
      return false;
    }
  }
  
  // Obtener datos del usuario actual
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = auth.currentUser;
      if (user == null) return null;
      
      final userDoc = await usersCollection.doc(user.uid).get();
      if (!userDoc.exists) return null;
      
      return userDoc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  // Generar ID único
  String generateId() {
    return firestore.collection('_').doc().id;
  }
}
