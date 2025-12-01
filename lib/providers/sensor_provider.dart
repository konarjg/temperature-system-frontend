import 'package:flutter/material.dart';
import '../models/sensor_model.dart';
import '../repositories/sensor_repository.dart';
import '../services/signalr_service.dart';

class SensorProvider extends ChangeNotifier {
  final SensorRepository _repository;
  final SignalRService _signalRService;

  List<SensorModel> _sensors = [];
  List<SensorModel> get sensors => _sensors;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SensorState? _currentFilter;
  SensorState? get currentFilter => _currentFilter;

  SensorProvider(this._repository, this._signalRService) {
    _signalRService.onSensorStateChanged = _handleSensorUpdate;
  }

  Future<void> loadSensors() async {
    _isLoading = true;
    notifyListeners();
    try {
      _sensors = await _repository.getSensors(state: _currentFilter);
    } catch (e) {
      debugPrint('Error loading sensors: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterByState(SensorState? state) async {
    if (_currentFilter == state) return;
    _currentFilter = state;
    await loadSensors();
  }

  Future<void> addSensor(String name, String address) async {
    try {
      await _repository.createSensor(SensorRequest(displayName: name, deviceAddress: address));
      await loadSensors();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeSensor(int id) async {
    try {
      await _repository.deleteSensor(id);
      _sensors.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void _handleSensorUpdate(int id, SensorState newState) {
    if (_currentFilter != null && newState != _currentFilter) {
       _sensors.removeWhere((s) => s.id == id);
       notifyListeners();
       return;
    }

    final index = _sensors.indexWhere((s) => s.id == id);
    if (index != -1) {
      final updated = SensorModel(
        id: _sensors[index].id,
        displayName: _sensors[index].displayName,
        deviceAddress: _sensors[index].deviceAddress,
        state: newState,
      );
      _sensors[index] = updated;
      notifyListeners();
    } else if (_currentFilter == null || newState == _currentFilter) {
     
    }
  }
}