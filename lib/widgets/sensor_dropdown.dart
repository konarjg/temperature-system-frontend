import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/mock_data.dart';

class SensorDropdown extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool showAllOption;

  const SensorDropdown({
    super.key,
    required this.selectedId,
    required this.onChanged,
    this.showAllOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gridLine),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          dropdownColor: AppColors.cardSurface,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          isExpanded: true,
          style: const TextStyle(color: AppColors.textPrimary),
          items: [
            if (showAllOption)
              const DropdownMenuItem(
                value: "all",
                child: Text("All Sensors"),
              ),
            ...MockData.sensors.map((sensor) {
              return DropdownMenuItem(
                value: sensor.id,
                child: Text(sensor.name),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}