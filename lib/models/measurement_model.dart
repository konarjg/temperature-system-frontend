import '../utils/app_parser.dart';

class MeasurementModel {
  final int id;
  final int sensorId;
  final double temperature;
  final DateTime timestamp;

  MeasurementModel({
    required this.id,
    required this.sensorId,
    required this.temperature,
    required this.timestamp,
  });

  // Maps to: public record MeasurementDto(long Id, string Timestamp, long SensorId, float TemperatureCelsius);
  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    return MeasurementModel(
      id: json['id'] ?? 0,
      sensorId: json['sensorId'] ?? 0,
      temperature: AppParser.parseDouble(json['temperatureCelsius']),
      timestamp: AppParser.parseDate(json['timestamp']),
    );
  }
}

class AggregatedMeasurement {
  final DateTime period;
  final double averageTemperature;

  AggregatedMeasurement({required this.period, required this.averageTemperature});

  // Maps to: public record AggregatedMeasurement(DateTime TimeStamp, float AverageTemperatureCelsius);
  factory AggregatedMeasurement.fromJson(Map<String, dynamic> json) {
    return AggregatedMeasurement(
      period: AppParser.parseDate(json['timeStamp']),
      averageTemperature: AppParser.parseDouble(json['averageTemperatureCelsius']),
    );
  }
}

// Specific DTO for SignalR payload: MeasurementNotification(string Timestamp, float TemperatureCelsius);
class MeasurementNotification {
  final String timestampStr;
  final double temperature;

  MeasurementNotification({required this.timestampStr, required this.temperature});

  factory MeasurementNotification.fromJson(Map<String, dynamic> json) {
    return MeasurementNotification(
      timestampStr: json['timestamp'] ?? '',
      temperature: AppParser.parseDouble(json['temperatureCelsius']),
    );
  }
}