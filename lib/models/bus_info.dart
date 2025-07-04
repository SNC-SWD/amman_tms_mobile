import 'dart:convert';

BusListResponse busListResponseFromJson(String str) =>
    BusListResponse.fromJson(json.decode(str));

class BusListResponse {
  final bool status;
  final String message;
  final List<BusInfo> data;

  BusListResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory BusListResponse.fromJson(Map<String, dynamic> json) =>
      BusListResponse(
        status: json["status"],
        message: json["message"],
        data: List<BusInfo>.from(json["data"].map((x) => BusInfo.fromJson(x))),
      );
}

class BusInfo {
  final int id;
  final String name;
  final String deviceId;
  final double lastLatitude;
  final double lastLongitude;
  final Vehicle vehicle;
  final String lastUpdate;

  BusInfo({
    required this.id,
    required this.name,
    required this.deviceId,
    required this.lastLatitude,
    required this.lastLongitude,
    required this.vehicle,
    required this.lastUpdate,
  });

  factory BusInfo.fromJson(Map<String, dynamic> json) => BusInfo(
    id: json["id"],
    name: json["name"],
    deviceId: json["device_id"],
    lastLatitude: json["last_latitude"]?.toDouble() ?? 0.0,
    lastLongitude: json["last_longitude"]?.toDouble() ?? 0.0,
    vehicle: Vehicle.fromJson(json["vehicle"]),
    lastUpdate: json["last_update"],
  );
}

class Vehicle {
  final int id;
  final String name;
  final Driver driver;
  final StateInfo state;

  Vehicle({
    required this.id,
    required this.name,
    required this.driver,
    required this.state,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json["id"],
    name: json["name"],
    driver: Driver.fromJson(json["driver"]),
    state: StateInfo.fromJson(json["state"]),
  );
}

class Driver {
  final int id;
  final String name;

  Driver({required this.id, required this.name});

  factory Driver.fromJson(Map<String, dynamic> json) =>
      Driver(id: json["id"], name: json["name"]);
}

class StateInfo {
  final String name;

  StateInfo({required this.name});

  factory StateInfo.fromJson(Map<String, dynamic> json) =>
      StateInfo(name: json["name"]);
}
