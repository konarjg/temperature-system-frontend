import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/api_config.dart';
import '../models/measurement_model.dart';
import '../models/sensor_model.dart';
import '../utils/app_parser.dart';

class SignalRService {
  HubConnection? _measurementConnection;
  HubConnection? _sensorConnection;

  // Callbacks for Providers
  Function(int sensorId, double temp, DateTime time)? onMeasurementReceived;
  Function(int sensorId, SensorState state)? onSensorStateChanged;

  Future<void> start(String token) async {
    await stop(); 

    final options = HttpConnectionOptions(
      accessTokenFactory: () async => token,
      skipNegotiation: true,
      transport: HttpTransportType.WebSockets,
    );

    // 1. Configure Measurement Hub
    // Route: /hub/measurements
    _measurementConnection = HubConnectionBuilder()
        .withUrl('${ApiConfig.baseUrl}/hub/measurements', options: options)
        .withAutomaticReconnect()
        .build();

    // Event: ReceiveMeasurement
    _measurementConnection?.on('ReceiveMeasurement', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        _handleMeasurement(arguments[0]);
      }
    });

    // 2. Configure Sensor Hub
    // Route: /hub/sensors
    _sensorConnection = HubConnectionBuilder()
        .withUrl('${ApiConfig.baseUrl}/hub/sensors', options: options)
        .withAutomaticReconnect()
        .build();

    // Event: UpdateSensor
    _sensorConnection?.on('UpdateSensor', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        _handleSensorUpdate(arguments[0]);
      }
    });

    try {
      await _measurementConnection?.start();
      await _sensorConnection?.start();
      
      // Subscribe to global sensor updates
      await _sensorConnection?.invoke('Subscribe');
      
      debugPrint("SignalR Connected");
    } catch (e) {
      debugPrint("SignalR Connection Error: $e");
    }
  }

  Future<void> stop() async {
    await _measurementConnection?.stop();
    await _sensorConnection?.stop();
    _measurementConnection = null;
    _sensorConnection = null;
  }

  // --- Measurement Hub Methods ---

  Future<void> subscribeToMeasurement(int sensorId) async {
    if (_measurementConnection?.state == HubConnectionState.Connected) {
      try {
        await _measurementConnection?.invoke('SubscribeToSensor', args: [sensorId]);
      } catch (e) {
        debugPrint("Error subscribing to sensor $sensorId: $e");
      }
    }
  }

  Future<void> unsubscribeFromMeasurement(int sensorId) async {
    if (_measurementConnection?.state == HubConnectionState.Connected) {
      try {
        await _measurementConnection?.invoke('UnsubscribeFromSensor', args: [sensorId]);
      } catch (e) {
        debugPrint("Error unsubscribing from sensor $sensorId: $e");
      }
    }
  }

  // --- Handlers ---

  void _handleMeasurement(dynamic data) {
    if (onMeasurementReceived == null) return;
    
    // Payload is MeasurementNotification { timestamp, temperatureCelsius }
    // Crucially, it DOES NOT contain the SensorId.
    try {
      final map = data as Map<String, dynamic>;
      final dto = MeasurementNotification.fromJson(map);
      
      // We pass 0 (or ignore ID) because the provider knows which sensor is active/subscribed
      onMeasurementReceived!(0, dto.temperature, AppParser.parseDate(dto.timestampStr));
    } catch (e) {
      debugPrint("Error parsing measurement payload: $e");
    }
  }

  void _handleSensorUpdate(dynamic data) {
    if (onSensorStateChanged == null) return;
    
    // Payload is SensorNotification { id, state }
    try {
      final map = data as Map<String, dynamic>;
      final id = map['id'] is int ? map['id'] : int.parse(map['id'].toString());
      final state = SensorModel.parseState(map['state']);
      
      onSensorStateChanged!(id, state);
    } catch (e) {
      debugPrint("Error parsing sensor update payload: $e");
    }
  }
}