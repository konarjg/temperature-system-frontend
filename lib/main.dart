import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_colors.dart';
import 'screens/login_screen.dart';
import 'main_layout.dart';
import 'services/api_service.dart';
import 'services/signalr_service.dart';
import 'repositories/sensor_repository.dart';
import 'repositories/measurement_repository.dart';
import 'repositories/user_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/measurement_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiService = ApiService();
  
  // FIX: This is now uncommented because init() is defined and required for cookies
  await apiService.init(); 

  final signalRService = SignalRService();
  // Note: signalRService does NOT need init(), it starts in AuthProvider.

  final sensorRepo = SensorRepository(apiService);
  final measurementRepo = MeasurementRepository(apiService);
  final userRepo = UserRepository(apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService, userRepo, signalRService)),
        ChangeNotifierProvider(create: (_) => SensorProvider(sensorRepo, signalRService)),
        ChangeNotifierProvider(create: (_) => MeasurementProvider(measurementRepo, signalRService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Temperature IoT',
      theme: ThemeData(
        fontFamily: 'Roboto', 
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isAuthenticated) {
      return const MainLayout();
    } else {
      return const LoginScreen();
    }
  }
}