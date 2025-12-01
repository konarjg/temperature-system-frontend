import '../config/api_config.dart';
import '../models/sensor_model.dart';
import '../services/api_service.dart';

class SensorRepository {
  final ApiService _api;

  SensorRepository(this._api);

  Future<List<SensorModel>> getSensors({SensorState? state}) async {
    final query = <String, dynamic>{};
    
    if (state != null && state != SensorState.Unknown) {
      query['state'] = state.name; 
    }

    final response = await _api.get(ApiConfig.sensors, queryParams: query);
    
    if (response is List) {
      return response.map((e) => SensorModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> createSensor(SensorRequest request) async {
    await _api.post(ApiConfig.sensors, request.toJson());
  }

  Future<void> deleteSensor(int id) async {
    await _api.delete('${ApiConfig.sensors}/$id');
  }
}