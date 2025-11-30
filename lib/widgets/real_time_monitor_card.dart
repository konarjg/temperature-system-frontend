import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math'; 
import '../config/app_colors.dart';
import '../config/mock_data.dart';

class RealTimeMonitorCard extends StatelessWidget {
  final String sensorName;
  final double currentTemp;
  final List<ChartDataPoint> data;

  const RealTimeMonitorCard({
    super.key,
    required this.sensorName,
    required this.currentTemp,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Real-Time Monitor",
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            Text(
              sensorName,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "${currentTemp.toStringAsFixed(1)}°C",
          style: const TextStyle(
            color: AppColors.primaryOrange,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: LineChart(
            LineChartData(
              // Tooltip Configuration
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  // Changed from getTooltipColor to tooltipBgColor for compatibility
                  tooltipBgColor: AppColors.cardSurface, 
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      return LineTooltipItem(
                        '${barSpot.y.toStringAsFixed(1)}°C',
                        const TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                verticalInterval: 5,
                horizontalInterval: 20,
                getDrawingVerticalLine: (value) => FlLine(
                  color: AppColors.gridLine.withOpacity(0.5),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.gridLine.withOpacity(0.5),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= data.length) return const SizedBox.shrink();
                      
                      String label = DateFormat('mm:ss').format(data[index].time);
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              // Dynamic Y-Axis Scaling
              minY: (data.map((e) => e.value).reduce(min) - 5).clamp(0, 100),
              maxY: (data.map((e) => e.value).reduce(max) + 5).clamp(0, 100),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.primaryOrange,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primaryOrange.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}