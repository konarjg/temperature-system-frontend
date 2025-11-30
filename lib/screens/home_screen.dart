import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/mock_data.dart';
import '../widgets/main_temperature_chart.dart';
import '../widgets/real_time_monitor_card.dart';
import '../widgets/sensor_dropdown.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _aggSensorId = MockData.sensors[0].id;
  String _granularity = "Daily";
  String _rtSensorId = MockData.sensors[1].id;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AGGREGATED HISTORY
          const Text(
            "Average Temperature History",
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SensorDropdown(
            selectedId: _aggSensorId,
            onChanged: (val) => setState(() => _aggSensorId = val!),
          ),
          const SizedBox(height: 10),
          _buildSegmentControl(),
          const SizedBox(height: 15),
          Container(
            height: 320, 
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            // Updated to pass granularity
            child: MainTemperatureChart(
              data: MockData.getChartData(_aggSensorId, _granularity),
              granularity: _granularity,
            ),
          ),

          const SizedBox(height: 30),

          // REAL TIME MONITOR
          SensorDropdown(
            selectedId: _rtSensorId,
            onChanged: (val) => setState(() => _rtSensorId = val!),
          ),
          const SizedBox(height: 10),
          Container(
            height: 320, 
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: RealTimeMonitorCard(
              sensorName: MockData.sensors.firstWhere((s) => s.id == _rtSensorId).name,
              currentTemp: MockData.getCurrentTemp(_rtSensorId),
              data: MockData.getRealTimeData(_rtSensorId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentControl() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ["Hourly", "Daily", "Monthly"].map((g) {
          final isSelected = _granularity == g;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _granularity = g),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  g,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}