import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  employee
}

class UserFirebase {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  UserFirebase({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory UserFirebase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserFirebase(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: _stringToUserRole(data['role'] ?? 'employee'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  static UserRole _stringToUserRole(String roleStr) {
    switch (roleStr) {
      case 'admin':
        return UserRole.admin;
      case 'employee':
      default:
        return UserRole.employee;
    }
  }

  bool get isAdmin => role == UserRole.admin;
  
  UserFirebase copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserFirebase(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
