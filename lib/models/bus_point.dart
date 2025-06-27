class BusPoint {
  final int id;
  final String name;

  BusPoint({required this.id, required this.name});

  factory BusPoint.fromJson(Map<String, dynamic> json) {
    return BusPoint(id: json['id'], name: json['name']);
  }
}
