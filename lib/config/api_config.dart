class ApiConfig {
  static const String baseUrl = 'http://10.247.99.174:8080';
  static const String apiUrl = '$baseUrl/api';

  static const String authLogin = '$apiUrl/auth';
  static const String authRefresh = '$apiUrl/auth/refresh';
  static const String authLogout = '$apiUrl/auth/logout';
  
  static const String usersUrl = '$apiUrl/users';
  static const String sensors = '$apiUrl/sensors';
  static const String measurements = '$apiUrl/measurements';
  
  static const String measurementsHub = '$baseUrl/hub/measurements';
  static const String sensorsHub = '$baseUrl/hub/sensors';
}