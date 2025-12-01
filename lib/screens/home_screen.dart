import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/sensor_provider.dart';
import '../providers/measurement_provider.dart';
import '../models/measurement_model.dart';
import '../models/sensor_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedSensorId;
  String _granularity = "Hourly";
  bool _initialFetchDone = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sensorP = Provider.of<SensorProvider>(context, listen: false);
      if (sensorP.sensors.isEmpty && !sensorP.isLoading) {
        sensorP.loadSensors();
      }
    });
  }

  void _refreshData() {
    if (_selectedSensorId != null) {
      final mp = Provider.of<MeasurementProvider>(context, listen: false);
      mp.setActiveSensor(_selectedSensorId!);
      mp.fetchAggregatedHistory(_selectedSensorId!, _granularity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorProvider = Provider.of<SensorProvider>(context);
    final measurementProvider = Provider.of<MeasurementProvider>(context);

    // --- FIX: Validation Logic ---
    // If sensors are available, ensure _selectedSensorId is valid (exists in the list).
    // If it's invalid (e.g., filtered out), auto-select the first available sensor.
    int? safeSensorId = _selectedSensorId;
    
    if (sensorProvider.sensors.isNotEmpty) {
      bool isValid = safeSensorId != null && sensorProvider.sensors.any((s) => s.id == safeSensorId);
      
      if (!isValid) {
        safeSensorId = sensorProvider.sensors.first.id;
        
        // Schedule state update to persist this change and fetch new data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedSensorId != safeSensorId) {
            setState(() {
              _selectedSensorId = safeSensorId;
              _initialFetchDone = true; 
            });
            _refreshData();
          }
        });
      } else if (!_initialFetchDone && safeSensorId != null) {
         // Handle initial data load if it hasn't happened yet
         WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_initialFetchDone) {
               _refreshData();
               setState(() => _initialFetchDone = true);
            }
         });
      }
    } else {
      safeSensorId = null;
    }
    // ----------------------------

    if (sensorProvider.sensors.isEmpty) {
      return Center(
        child: sensorProvider.isLoading 
          ? const CircularProgressIndicator()
          : const Text("No sensors available.", style: TextStyle(color: AppColors.textSecondary))
      );
    }

    // Use safeSensorId for rendering to prevent crashes
    final currentSensor = sensorProvider.sensors.firstWhere(
      (s) => s.id == safeSensorId, 
      orElse: () => sensorProvider.sensors.first
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSensorDropdown(sensorProvider.sensors, safeSensorId),
          const SizedBox(height: 20),

          // --- REAL TIME CHART SECTION ---
          _RealTimeSection(
             sensorState: currentSensor.state,
          ),
          
          const SizedBox(height: 30),
          
          // --- HISTORY CHART SECTION ---
          const Text("Historical Data", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildGranularityControl(),
          const SizedBox(height: 15),
          Container(
             height: 320,
             decoration: BoxDecoration(
               color: AppColors.cardSurface,
               borderRadius: BorderRadius.circular(20),
             ),
             padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
             child: measurementProvider.isLoading 
               ? const Center(child: CircularProgressIndicator())
               : _buildHistoryChart(measurementProvider.aggregatedHistory),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDropdown(List<SensorModel> sensors, int? currentId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gridLine),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: currentId,
          dropdownColor: AppColors.cardSurface,
          isExpanded: true,
          style: const TextStyle(color: AppColors.textPrimary),
          items: sensors.map((s) => DropdownMenuItem(
            value: s.id,
            child: Text(s.displayName ?? "Sensor ${s.id}"),
          )).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                 _selectedSensorId = val;
                 _initialFetchDone = true;
              });
              _refreshData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildGranularityControl() {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: ["Hourly", "Daily", "Monthly"].map((g) {
          final isSelected = _granularity == g;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _granularity = g);
                _refreshData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(g, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryChart(List<AggregatedMeasurement> data) {
    if (data.isEmpty) return const Center(child: Text("No Data Available", style: TextStyle(color: AppColors.textSecondary)));

    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.averageTemperature)).toList();

    // Auto-scale Y Axis
    double minTemp = 100;
    double maxTemp = 0;
    if (spots.isNotEmpty) {
      for (var spot in spots) {
        if (spot.y < minTemp) minTemp = spot.y;
        if (spot.y > maxTemp) maxTemp = spot.y;
      }
    }
    minTemp = (minTemp - 5).clamp(0, 100);
    maxTemp = (maxTemp + 5).clamp(0, 100);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.gridLine, strokeWidth: 1),
        ),
        minY: minTemp,
        maxY: maxTemp,
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (data.length / 5).ceilToDouble(),
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                final date = data[index].period;
                String txt = "";
                if (_granularity == 'Hourly') txt = DateFormat('HH:mm').format(date);
                else if (_granularity == 'Daily') txt = DateFormat('MM/dd').format(date);
                else txt = DateFormat('MMM').format(date);
                return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(txt, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primaryBlue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.primaryBlue.withOpacity(0.3), AppColors.primaryBlue.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
      ),
    );
  }
}

class _RealTimeSection extends StatelessWidget {
  final SensorState sensorState;

  const _RealTimeSection({required this.sensorState});

  @override
  Widget build(BuildContext context) {
    return Consumer<MeasurementProvider>(
      builder: (context, provider, child) {
        final currentTemp = provider.realTimeData.isNotEmpty 
            ? provider.realTimeData.last.temperature 
            : 0.0;
        
        return Container(
          height: 320,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Real-Time Monitor", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sensorState == SensorState.Operational ? Colors.green.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sensorState == SensorState.Operational ? "ONLINE" : "OFFLINE",
                      style: TextStyle(
                        color: sensorState == SensorState.Operational ? Colors.green : AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "${currentTemp.toStringAsFixed(1)}°C",
                style: const TextStyle(color: AppColors.primaryOrange, fontSize: 36, fontWeight: FontWeight.bold),
              ),
              Expanded(child: _buildChart(provider.realTimeData)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(List<MeasurementModel> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.temperature)).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 19, 
        minY: (data.map((e) => e.temperature).reduce((a, b) => a < b ? a : b) - 2).clamp(0, 100),
        maxY: (data.map((e) => e.temperature).reduce((a, b) => a > b ? a : b) + 2).clamp(0, 100),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primaryOrange,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.primaryOrange.withOpacity(0.15)),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300), 
      curve: Curves.easeInOut,
    );
  }
}