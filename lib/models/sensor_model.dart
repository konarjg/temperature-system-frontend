enum SensorState {
  Operational,
  Unavailable,
  Unknown
}

class SensorModel {
  final int id;
  final String? displayName;
  final String? deviceAddress;
  final SensorState state;

  SensorModel({
    required this.id,
    this.displayName,
    this.deviceAddress,
    required this.state,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      id: json['id'] ?? 0,
      displayName: json['displayName'],
      deviceAddress: json['deviceAddress'],
      state: parseState(json['state']),
    );
  }

  static SensorState parseState(dynamic state) {
    if (state == null) return SensorState.Unknown;
    
    // Handle String (API typically serializes enums as strings)
    final str = state.toString().toLowerCase();
    if (str == 'operational') return SensorState.Operational;
    if (str == 'unavailable') return SensorState.Unavailable;
    
    // Handle Integer (SignalR often sends raw integers for enums)
    if (state == 0) return SensorState.Operational;
    if (state == 1) return SensorState.Unavailable;
    
    return SensorState.Unknown;
  }
}

class SensorRequest {
  final String displayName;
  final String deviceAddress;

  SensorRequest({required this.displayName, required this.deviceAddress});

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'deviceAddress': deviceAddress,
  };
}