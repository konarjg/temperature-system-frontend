enum UserRole {
  Unverified,
  Viewer,
  Admin
}

class User {
  final int id;
  final String email;
  final UserRole role;

  User({
    required this.id,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      email: json['email'] ?? '',
      role: _parseRole(json['role']),
    );
  }

  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.Unverified;
    final str = role.toString();
    if (str == 'Admin' || str == '2') return UserRole.Admin;
    if (str == 'Viewer' || str == '1') return UserRole.Viewer;
    return UserRole.Unverified;
  }
}

class CreateUserRequest {
  final String email;
  final String password;

  CreateUserRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class UpdateRoleRequest {
  final UserRole role;

  UpdateRoleRequest({required this.role});

  Map<String, dynamic> toJson() => {
    'role': role.name, // "Admin", "Viewer", etc.
  };
}