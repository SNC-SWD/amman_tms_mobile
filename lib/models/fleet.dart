class Fleet {
  final int id;
  final String modelName;
  final String licensePlate;
  final String driver;
  final String fleetType;
  final String status;

  Fleet({
    required this.id,
    required this.modelName,
    required this.licensePlate,
    required this.driver,
    required this.fleetType,
    required this.status,
  });

  String get displayName => '$modelName - $licensePlate';

  // Opsional: badge color untuk status
  // Color get statusColor {
  //   switch (status.toLowerCase()) {
  //     case 'available':
  //       return Colors.green;
  //     case 'on trip':
  //       return Colors.orange;
  //     default:
  //       return Colors.grey;
  //   }
  // }

  factory Fleet.fromJson(Map<String, dynamic> json) {
    return Fleet(
      id: json['id'] as int,
      modelName: json['model_name'] as String,
      licensePlate: json['license_plate'] as String,
      driver: json['driver'] as String,
      fleetType: json['fleet_type'] as String,
      status: json['status']?.toString() ?? '-',
    );
  }
}
