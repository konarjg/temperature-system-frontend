import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_colors.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/sensor_list_screen.dart';
import 'screens/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    SensorListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text("IoT Dashboard", style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
        actions: [
           Padding(
             padding: const EdgeInsets.only(right: 20.0),
             child: IconButton(
               icon: const Icon(Icons.logout, color: AppColors.textSecondary),
               onPressed: () {
                 Provider.of<AuthProvider>(context, listen: false).logout();
               },
             ),
           )
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardSurface, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textSecondary,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined), 
              activeIcon: Icon(Icons.list_alt), 
              label: "History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_input_antenna), 
              activeIcon: Icon(Icons.settings_input_antenna_outlined),
              label: "Sensors",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), 
              activeIcon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}