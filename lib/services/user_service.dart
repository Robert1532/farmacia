import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_firebase.dart';
import '../models/user_role.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();
  
  // Obtener el rol del usuario actual
  Future<UserRoleType> getCurrentUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return UserRoleType.user;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return UserRoleType.user;
      
      final roleString = doc.data()?['role'] as String?;
      return UserRoleTypeExtension.fromString(roleString);
    } catch (e) {
      // Use a logging framework instead of print in production
      // print('Error al obtener el rol del usuario: $e');
      return UserRoleType.user;
    }
  }
  
  // Verificar si el usuario actual es administrador
  Future<bool> isCurrentUserAdmin() async {
    final role = await getCurrentUserRole();
    return role == UserRoleType.admin;
  }
  
  // Asignar rol a un usuario (solo para administradores)
  Future<bool> assignRole(String userId, UserRoleType role) async {
    try {
      // Verificar si el usuario actual es administrador
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('No tienes permisos para realizar esta acción');
      }
      
      // Asignar el rol
      await _firestore.collection('users').doc(userId).update({
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      // Use a logging framework instead of print in production
      // print('Error al asignar rol: $e');
      return false;
    }
  }
  
  // Crear el primer administrador (solo se debe usar una vez)
  Future<bool> createFirstAdmin(String userId) async {
    try {
      // Verificar si ya existe algún administrador
      final adminQuery = await _firestore.collection('users')
          .where('role', isEqualTo: UserRoleType.admin.name)
          .limit(1)
          .get();
      
      if (adminQuery.docs.isNotEmpty) {
        throw Exception('Ya existe un administrador en el sistema');
      }
      
      // Asignar rol de administrador
      await _firestore.collection('users').doc(userId).update({
        'role': UserRoleType.admin.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      // Use a logging framework instead of print in production
      // print('Error al crear el primer administrador: $e');
      return false;
    }
  }
  
  // Obtener todos los usuarios (solo para administradores)
  Future<List<UserFirebase>> getAllUsers() async {
    try {
      // Verificar si el usuario actual es administrador
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('No tienes permisos para realizar esta acción');
      }
      
      // Obtener todos los usuarios
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .map((doc) => UserFirebase.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Use a logging framework instead of print in production
      // print('Error al obtener usuarios: $e');
      return [];
    }
  }
}
