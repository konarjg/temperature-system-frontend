import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/api_config.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final UserRepository _userRepository;
  final SignalRService _signalRService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool get isAdmin => _currentUser?.role == UserRole.Admin;

  AuthProvider(this._apiService, this._userRepository, this._signalRService);

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'jwt_token');
    
    if (token != null && !JwtDecoder.isExpired(token)) {
      _isAuthenticated = true;
      _signalRService.start();
      final userIdStr = await _storage.read(key: 'user_id');
      if (userIdStr != null) {
         await _fetchUserProfile(int.parse(userIdStr));
      }
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConfig.authLogin, 
        AuthRequest(email: email, password: password).toJson()
      );
      
      final result = AuthResultDto.fromJson(response);

      await _storage.write(key: 'jwt_token', value: result.accessToken);
      await _storage.write(key: 'user_id', value: result.userId.toString());
      
      _signalRService.start();

      await _fetchUserProfile(result.userId);

      _isAuthenticated = true;
      return true;
    } catch (e) {
      debugPrint("Login failed: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _userRepository.createUser(CreateUserRequest(email: email, password: password));
      await login(email, password);
      
      return true; 
    } catch (e) {
      debugPrint("Registration failed: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMyCredentials(String email, String password) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _userRepository.updateCredentials(_currentUser!.id, email, password);
      await _fetchUserProfile(_currentUser!.id);
      return true;
    } catch (e) {
      debugPrint("Update credentials failed: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMyAccount() async {
    if (_currentUser == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _userRepository.deleteUser(_currentUser!.id);
      await logout();
      return true;
    } catch (e) {
      debugPrint("Delete account failed: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchUserProfile(int userId) async {
    try {
      _currentUser = await _userRepository.getUserById(userId);
    } catch (e) {
      debugPrint("Failed to load user profile: $e");
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.delete(ApiConfig.authLogout);
    } catch (_) {}
    
    await _apiService.clearTokens();
    await _signalRService.stop();
    
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}