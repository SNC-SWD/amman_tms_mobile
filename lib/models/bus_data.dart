import 'dart:convert';

List<BusData> busDataFromJson(String str) =>
    List<BusData>.from(json.decode(str).map((x) => BusData.fromJson(x)));

class BusData {
  final int deviceId;
  final double latitude;
  final double longitude;
  final double speed;
  final double course;
  final DateTime deviceTime;
  final Attributes attributes;
  final String? address;

  BusData({
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.course,
    required this.deviceTime,
    required this.attributes,
    this.address,
  });

  factory BusData.fromJson(Map<String, dynamic> json) => BusData(
    deviceId: json["deviceId"],
    latitude: json["latitude"]?.toDouble() ?? 0.0,
    longitude: json["longitude"]?.toDouble() ?? 0.0,
    speed: json["speed"]?.toDouble() ?? 0.0,
    course: json["course"]?.toDouble() ?? 0.0,
    deviceTime: DateTime.parse(json["deviceTime"]),
    address: json["address"],
    attributes: Attributes.fromJson(json["attributes"]),
  );

  // Konversi kecepatan dari knots ke km/h
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

  factory Attributes.fromJson(Map<String, dynamic> json) => Attributes(
    ignition: json["ignition"] ?? false,
    motion: json["motion"] ?? false,
    power: json["power"]?.toDouble() ?? 0.0,
    odometer: json["odometer"] ?? 0,
  );
}
