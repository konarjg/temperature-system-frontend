import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/mock_data.dart';
import '../widgets/sensor_card.dart';

class SensorListScreen extends StatelessWidget {
  const SensorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Sensors",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {}, // Add sensor action
                icon: const Icon(Icons.add_circle, color: AppColors.primaryBlue, size: 28),
              )
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: MockData.sensors.length,
              itemBuilder: (context, index) {
                return SensorCard(sensor: MockData.sensors[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}