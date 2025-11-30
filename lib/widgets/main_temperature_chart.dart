import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../config/app_colors.dart';
import '../config/mock_data.dart';

class MainTemperatureChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final String granularity;

  const MainTemperatureChart({
    super.key, 
    required this.data,
    required this.granularity,
  });

  @override
  Widget build(BuildContext context) {
    // Convert ChartDataPoint to FlSpot for the chart engine
    // We use the index as the X value
    List<FlSpot> spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.gridLine,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          
          // --- BOTTOM TITLES (TIMESTAMPS) ---
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getInterval(), // Dynamic interval based on granularity
              getTitlesWidget: (value, meta) {
                 int index = value.toInt();
                 if (index < 0 || index >= data.length) return const SizedBox.shrink();
                 
                 DateTime time = data[index].time;
                 String label = _formatDate(time);

                 return Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Text(
                     label, 
                     style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)
                   ),
                 );
              },
            ),
          ),
          
          // --- LEFT TITLES (TEMP) ---
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  "${value.toInt()}°C",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100, // Fixed scale for consistency
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primaryBlue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.3),
                  AppColors.primaryBlue.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to determine label spacing
  double _getInterval() {
    if (granularity == 'Hourly') return 4; // Show every 4th hour
    if (granularity == 'Daily') return 1;  // Show every day
    return 2; // Show every 2nd month
  }

  // Helper to format the date string
  String _formatDate(DateTime date) {
    if (granularity == 'Hourly') return DateFormat('HH:mm').format(date);
    if (granularity == 'Daily') return DateFormat('EEE').format(date); // Mon, Tue
    if (granularity == 'Monthly') return DateFormat('MMM').format(date); // Jan, Feb
    return '';
  }
}