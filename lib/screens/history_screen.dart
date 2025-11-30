import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/mock_data.dart';
import '../widgets/measurement_card.dart';
import '../widgets/sensor_dropdown.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filterId = "all"; // Default to show all

  @override
  Widget build(BuildContext context) {
    // Filter the list based on selection
    final allMeasurements = MockData.getHistory();
    final displayedMeasurements = _filterId == "all"
        ? allMeasurements
        : allMeasurements.where((m) => m.sensorId == _filterId).toList();

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
                "Measurement History",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Filter Dropdown
          SensorDropdown(
            selectedId: _filterId,
            showAllOption: true,
            onChanged: (val) => setState(() => _filterId = val!),
          ),
          
          const SizedBox(height: 15),
          
          // List
          Expanded(
            child: displayedMeasurements.isEmpty 
              ? const Center(child: Text("No measurements found", style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  itemCount: displayedMeasurements.length,
                  itemBuilder: (context, index) {
                    return MeasurementCard(measurement: displayedMeasurements[index]);
                  },
                ),
          ),
        ],
      ),
    );
  }
}