// lib/models/bus_model.dart

class Bus {
  final int id;
  final String modelName;
  final String licensePlate;
  final String driver;
  final String fleetType;
  final String status;

  Bus({
    required this.id,
    required this.modelName,
    required this.licensePlate,
    required this.driver,
    required this.fleetType,
    required this.status,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] ?? 0,
      modelName: json['model_name'] ?? 'N/A',
      licensePlate: json['license_plate'] ?? 'N/A',
      driver: json['driver'] ?? 'N/A',
      fleetType: json['fleet_type'] ?? 'N/A',
      status: json['status'] ?? 'Unknown',
    );
  }
}
