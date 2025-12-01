import 'dart:math';

class MeasurementModel {
  final String id;
  final String sensorId;
  final String sensorName;
  final double temperature;
  final DateTime timestamp;

  const MeasurementModel(this.id, this.sensorId, this.sensorName, this.temperature, this.timestamp);
}

class SensorModel {
  final String id;
  final String name;
  final String address;
  final bool isOnline;

  const SensorModel(this.id, this.name, this.address, this.isOnline);
}

// Simple class to hold chart data with its corresponding time
class ChartDataPoint {
  final double value;
  final DateTime time;
  
  ChartDataPoint(this.value, this.time);
}

class MockData {
  // --- SENSORS ---
  static const List<SensorModel> sensors = [
    SensorModel("1", "H-VAC Unit 3", "28-000005e2fdc3", true),
    SensorModel("2", "Furnace B-12", "28-000004a1b2c3", true),
    SensorModel("3", "Basement Server", "28-00000991d2d1", false),
    SensorModel("4", "Attic Fan", "28-0000011234aa", true),
  ];

  // --- DYNAMIC CHART DATA ---
  static List<ChartDataPoint> getChartData(String sensorId, String granularity) {
    final Random r = Random(sensorId.hashCode); 
    double baseTemp = 20.0 + r.nextInt(15);
    
    int points;
    Duration interval;
    DateTime endTime = DateTime.now();
    DateTime startTime;

    if (granularity == 'Hourly') {
      points = 24;
      interval = const Duration(hours: 1);
      startTime = endTime.subtract(const Duration(hours: 24));
    } else if (granularity == 'Daily') {
      points = 7;
      interval = const Duration(days: 1);
      startTime = endTime.subtract(const Duration(days: 7));
    } else { // Monthly
      points = 12; // Last 12 months
      // Rough approximation for monthly interval logic
      interval = const Duration(days: 30); 
      startTime = endTime.subtract(const Duration(days: 360));
    }
    
    return List.generate(points, (index) {
      double noise = r.nextDouble() * 10 - 5;
      if (granularity == 'Hourly') noise *= 2; 
      
      DateTime time;
      if (granularity == 'Monthly') {
         // Special handling to ensure months are correct (simplified)
         time = DateTime(endTime.year, endTime.month - (points - 1 - index), 1);
      } else {
         time = startTime.add(interval * index);
      }

      return ChartDataPoint((baseTemp + noise).clamp(0, 100), time);
    });
  }

  // --- REAL TIME DATA ---
  static List<ChartDataPoint> getRealTimeData(String sensorId) {
    final Random r = Random(sensorId.hashCode + 100); 
    double baseTemp = 30.0 + r.nextInt(20);
    DateTime now = DateTime.now();
    
    // 20 points, 5 seconds apart
    return List.generate(20, (index) {
      // Index 0 is oldest, 19 is newest
      DateTime time = now.subtract(Duration(seconds: (19 - index) * 5));
      return ChartDataPoint(
        baseTemp + (r.nextDouble() * 5 - 2.5),
        time
      );
    });
  }

  static double getCurrentTemp(String sensorId) {
    final Random r = Random(sensorId.hashCode);
    return 20.0 + r.nextInt(30) + r.nextDouble();
  }

  // --- HISTORY LIST ---
  static List<MeasurementModel> getHistory() {
    return List.generate(40, (index) {
      final sensor = sensors[index % sensors.length];
      return MeasurementModel(
        "$index",
        sensor.id,
        sensor.name,
        20.0 + (index * 1.5) % 30, 
        DateTime.now().subtract(Duration(hours: index)),
      );
    });
  }
}