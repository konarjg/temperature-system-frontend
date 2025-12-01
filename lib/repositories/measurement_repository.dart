import '../config/api_config.dart';
import '../models/measurement_model.dart';
import '../services/api_service.dart';

class MeasurementRepository {
  final ApiService _api;

  MeasurementRepository(this._api);

  Future<List<MeasurementModel>> getLatest(int sensorId, int points) async {
    final response = await _api.get('${ApiConfig.measurements}/latest', queryParams: {
      'SensorId': sensorId,
      'Points': points,
    });
    
    if (response is List) {
      return response.map((e) => MeasurementModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<MeasurementModel>> getHistory({
    int? sensorId,
    required DateTime start, 
    required DateTime end, 
    required int pageSize, 
    DateTime? cursor
  }) async {
    final query = {
      'StartDate': start.toUtc().toIso8601String(),
      'EndDate': end.toUtc().toIso8601String(),
      'PageSize': pageSize,
    };

    if (sensorId != null) {
      query['SensorId'] = sensorId;
    }

    if (cursor != null) {
      query['Cursor'] = cursor.toUtc().toIso8601String();
    }

    final response = await _api.get('${ApiConfig.measurements}/history', queryParams: query);

    if (response is List) {
      return response.map((e) => MeasurementModel.fromJson(e)).toList();
    } else if (response is Map && response.containsKey('items')) {
      return (response['items'] as List).map((e) => MeasurementModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<AggregatedMeasurement>> getAggregatedHistory(
      int sensorId, DateTime start, DateTime end, String granularity) async {
    
    final response = await _api.get('${ApiConfig.measurements}/aggregated-history', queryParams: {
      'SensorId': sensorId,
      'StartDate': start.toUtc().toIso8601String(),
      'EndDate': end.toUtc().toIso8601String(),
      'Granularity': granularity,
    });

    if (response is List) {
      return response.map((e) => AggregatedMeasurement.fromJson(e)).toList();
    }
    return [];
  }
}