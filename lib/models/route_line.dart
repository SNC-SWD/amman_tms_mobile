class RouteLine {
  final int? id;
  final String from;
  final String to;
  final String? startTime;
  final String? endTime;

  RouteLine({
    this.id,
    required this.from,
    required this.to,
    this.startTime,
    this.endTime,
  });

  factory RouteLine.fromJson(Map<String, dynamic> json) {
    return RouteLine(
      id: json['id'],
      from: json['bording_from'] ?? '',
      to: json['to'] ?? '',
      startTime: json['start_times']?.toString(),
      endTime: json['end_times']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bording_from': from,
      'to': to,
      'start_times': startTime,
      'end_times': endTime,
    };
  }
}
