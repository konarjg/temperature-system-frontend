import 'package:flutter/material.dart';
import '../models/measurement_model.dart';
import '../repositories/measurement_repository.dart';
import '../services/signalr_service.dart';

class MeasurementProvider extends ChangeNotifier {
  final MeasurementRepository _repository;
  final SignalRService _signalRService;

  List<MeasurementModel> _realTimeData = [];
  List<MeasurementModel> get realTimeData => _realTimeData;

  List<MeasurementModel> _rawHistory = [];
  List<MeasurementModel> get rawHistory => _rawHistory;

  List<AggregatedMeasurement> _aggregatedHistory = [];
  List<AggregatedMeasurement> get aggregatedHistory => _aggregatedHistory;

  int? _activeSensorId;
  int? get activeSensorId => _activeSensorId;

  // Track subscribed IDs to unsubscribe later
  final List<int> _subscribedIds = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _isHistoryLoading = false;
  bool get isHistoryLoading => _isHistoryLoading;

  bool _hasMoreHistory = true;

  MeasurementProvider(this._repository, this._signalRService) {
    _signalRService.onMeasurementReceived = _handleNewMeasurement;
  }

  /// [sensorId] can be null for "All Sensors". 
  /// [allSensorIds] is required if [sensorId] is null to subscribe to all groups.
  Future<void> setActiveSensor(int? sensorId, {List<int>? allSensorIds}) async {
    if (_activeSensorId == sensorId && sensorId != null) return;

    // 1. Unsubscribe from previous
    if (_subscribedIds.isNotEmpty) {
      for (final id in _subscribedIds) {
        await _signalRService.unsubscribeFromMeasurement(id);
      }
      _subscribedIds.clear();
    }

    _activeSensorId = sensorId;
    _realTimeData = []; 
    _rawHistory = [];
    _aggregatedHistory = []; // Clear chart for 'All' view
    _hasMoreHistory = true;
    notifyListeners();

    if (sensorId != null) {
      // --- Single Sensor Mode ---
      await fetchLatest(sensorId);
      await _signalRService.subscribeToMeasurement(sensorId);
      _subscribedIds.add(sensorId);
    } else if (allSensorIds != null && allSensorIds.isNotEmpty) {
      // --- All Sensors Mode ---
      // Note: 'Latest' and 'Aggregated' APIs require specific ID, so we skip them.
      // We only subscribe to real-time updates for everyone.
      for (final id in allSensorIds) {
        await _signalRService.subscribeToMeasurement(id);
        _subscribedIds.add(id);
      }
    }
  }

  Future<void> fetchLatest(int sensorId) async {
    try {
      final data = await _repository.getLatest(sensorId, 20);
      if (_activeSensorId == sensorId) {
        _realTimeData = data;
        _realTimeData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching latest: $e");
    }
  }

  Future<void> fetchAggregatedHistory(int sensorId, String granularity) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now().toUtc();
    DateTime start;
    DateTime end = now.add(const Duration(days: 1));

    if (granularity == 'Hourly') {
      start = now.subtract(const Duration(hours: 24));
    } else if (granularity == 'Daily') {
      start = now.subtract(const Duration(days: 7));
    } else {
      start = now.subtract(const Duration(days: 365));
    }

    try {
      _aggregatedHistory = await _repository.getAggregatedHistory(sensorId, start, end, granularity);
    } catch (e) {
      debugPrint("Error fetching aggregated history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRawHistory({bool refresh = false}) async {
    // Allows null activeSensorId
    if (_isHistoryLoading) return;
    if (!refresh && !_hasMoreHistory) return;

    _isHistoryLoading = true;
    notifyListeners();

    if (refresh) {
      _rawHistory.clear();
      _hasMoreHistory = true;
    }

    try {
      DateTime? cursor;
      if (_rawHistory.isNotEmpty) {
        cursor = _rawHistory.last.timestamp;
      }

      final end = DateTime.now().toUtc().add(const Duration(days: 1)); 
      final start = DateTime.now().toUtc().subtract(const Duration(days: 365));
      const pageSize = 20;

      final newItems = await _repository.getHistory(
        sensorId: _activeSensorId, // Null implies all
        start: start,
        end: end,
        pageSize: pageSize,
        cursor: cursor
      );

      if (newItems.length < pageSize) {
        _hasMoreHistory = false;
      }

      _rawHistory.addAll(newItems);
    } catch (e) {
      debugPrint("Error fetching raw history: $e");
      _hasMoreHistory = false;
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  void _handleNewMeasurement(int _, double temp, DateTime time) {
    // If activeSensorId is set, ideally we check if it matches, 
    // but since SignalR payload lacks ID, we assume the subscription management 
    // handled the filtering. 
    
    // For "All Sensors", we accept everything.
    final newMeasurement = MeasurementModel(
      id: DateTime.now().millisecondsSinceEpoch,
      sensorId: _activeSensorId ?? 0, // 0 or unknown if showing all
      temperature: temp,
      timestamp: time,
    );

    final updatedList = List<MeasurementModel>.from(_realTimeData);
    updatedList.add(newMeasurement);
    
    if (updatedList.length > 20) {
      updatedList.removeAt(0);
    }
    
    _realTimeData = updatedList;
    
    final updatedHistory = List<MeasurementModel>.from(_rawHistory);
    updatedHistory.insert(0, newMeasurement);
    _rawHistory = updatedHistory;

    notifyListeners();
  }
}