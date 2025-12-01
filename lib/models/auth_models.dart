class AuthRequest {
  final String email;
  final String password;

  AuthRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class AuthResultDto {
  final int userId;
  final String accessToken;

  AuthResultDto({required this.userId, required this.accessToken});

  factory AuthResultDto.fromJson(Map<String, dynamic> json) {
    return AuthResultDto(
      userId: json['userId'] is int ? json['userId'] : int.parse(json['userId'].toString()),
      accessToken: json['accessToken'],
    );
  }
}

class UserProfile {
  final int id;
  final String email;
  
  UserProfile({required this.id, required this.email});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
    );
  }
}