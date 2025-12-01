import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/sensor_model.dart';

// Fix 3: Removed Address display for security/cleanup
class SensorCard extends StatelessWidget {
  final SensorModel sensor;
  final VoidCallback? onDelete;

  const SensorCard({super.key, required this.sensor, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isOnline = sensor.state == SensorState.Operational;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline ? Colors.transparent : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : AppColors.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isOnline ? Colors.green : AppColors.error).withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor.displayName ?? "Unknown Sensor",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                // Replaced Address with Status Text
                Text(
                  isOnline ? "Operational" : "Offline / Unavailable",
                  style: TextStyle(
                    color: isOnline ? AppColors.textSecondary : AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}