enum UserRoleType {
  user,
  employee,
  admin
}

extension UserRoleTypeExtension on UserRoleType {
  String get name {
    switch (this) {
      case UserRoleType.user:
        return 'user';
      case UserRoleType.employee:
        return 'employee';
      case UserRoleType.admin:
        return 'admin';
      default:
        return 'user';
    }
  }
  
  static UserRoleType fromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRoleType.admin;
      case 'employee':
        return UserRoleType.employee;
      case 'user':
      default:
        return UserRoleType.user;
    }
  }
  
  bool get isAdmin => this == UserRoleType.admin;
}
