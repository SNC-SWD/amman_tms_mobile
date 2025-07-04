import 'dart:convert';

List<BusStatus> busStatusFromJson(String str) =>
    List<BusStatus>.from(json.decode(str).map((x) => BusStatus.fromJson(x)));

class BusStatus {
  final int deviceId;
  final double latitude;
  final double longitude;
  final double speed;
  final double course;
  final DateTime deviceTime;
  final Attributes attributes;
  final String? address;

  BusStatus({
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.course,
    required this.deviceTime,
    required this.attributes,
    this.address,
  });

  // Factory untuk membuat instance kosong jika data tidak ditemukan
  factory BusStatus.empty() => BusStatus(
    deviceId: 0,
    latitude: 0,
    longitude: 0,
    speed: 0,
    course: 0,
    deviceTime: DateTime.now(),
    attributes: Attributes.empty(),
    address: "No data",
  );

  factory BusStatus.fromJson(Map<String, dynamic> json) => BusStatus(
    deviceId: json["deviceId"],
    latitude: json["latitude"]?.toDouble() ?? 0.0,
    longitude: json["longitude"]?.toDouble() ?? 0.0,
    speed: json["speed"]?.toDouble() ?? 0.0,
    course: json["course"]?.toDouble() ?? 0.0,
    deviceTime: DateTime.parse(json["deviceTime"]),
    address: json["address"],
    attributes: Attributes.fromJson(json["attributes"]),
  );

  double get speedInKmh => speed * 1.852;
}

class Attributes {
  final bool ignition;
  final bool motion;
  final double power;
  final int odometer;

  Attributes({
    required this.ignition,
    required this.motion,
    required this.power,
    required this.odometer,
  });

  factory Attributes.empty() =>
      Attributes(ignition: false, motion: false, power: 0, odometer: 0);

  factory Attributes.fromJson(Map<String, dynamic> json) => Attributes(
    ignition: json["ignition"] ?? false,
    motion: json["motion"] ?? false,
    power: json["power"]?.toDouble() ?? 0.0,
    odometer: json["odometer"] ?? 0,
  );
}
