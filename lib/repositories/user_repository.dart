import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserRepository {
  final ApiService _api;

  UserRepository(this._api);

  Future<User> getUserById(int id) async {
    final response = await _api.get('${ApiConfig.usersUrl}/$id');
    return User.fromJson(response);
  }

  Future<void> createUser(CreateUserRequest request) async {
    await _api.post(ApiConfig.usersUrl, request.toJson());
  }

  Future<void> deleteUser(int id) async {
    await _api.delete('${ApiConfig.usersUrl}/$id');
  }

  Future<void> updateCredentials(int id, String email, String password) async {
    await _api.put(
      '${ApiConfig.usersUrl}/$id/credentials', 
      CreateUserRequest(email: email, password: password).toJson()
    );
  }

  Future<void> updateRole(int id, UserRole newRole) async {
    await _api.put(
      '${ApiConfig.usersUrl}/$id/role',
      UpdateRoleRequest(role: newRole).toJson()
    );
  }
}