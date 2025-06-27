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
    // Convert float time to user-friendly format (e.g., 6.0 -> "06:00")
    String formatTime(dynamic time) {
      if (time == null) return '';
      
      // Convert to double
      double timeValue = time is double ? time : double.tryParse(time.toString()) ?? 0.0;
      
      // Extract hours and minutes
      int hours = timeValue.floor();
      int minutes = ((timeValue - hours) * 60).round();
      
      // Format as HH:MM
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
    
    return RouteLine(
      id: json['id'],
      from: json['bording_from_name'] ?? json['bording_from'] ?? '',
      to: json['to_name'] ?? json['to'] ?? '',
      startTime: formatTime(json['start_times']),
      endTime: formatTime(json['end_times']),
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
