class PlanTrip {
  final int id;
  final String name;
  final String tripDate;
  final int fromId;
  final String fromName;
  final int toId;
  final String toName;
  final int busId;
  final String busName;
  final String busPlate;
  final String busFleetType;
  final int userId;
  final String userName;
  final int totalSeat;
  final int bookedSeat;
  final int remainingSeats;

  PlanTrip({
    required this.id,
    required this.name,
    required this.tripDate,
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.busId,
    required this.busName,
    required this.busPlate,
    required this.busFleetType,
    required this.userId,
    required this.userName,
    required this.totalSeat,
    required this.bookedSeat,
    required this.remainingSeats,
  });

  factory PlanTrip.fromJson(Map<String, dynamic> json) {
    return PlanTrip(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      tripDate: json['trip_date'] ?? '',
      fromId: json['from_id'] ?? 0,
      fromName: json['from_name'] ?? '',
      toId: json['to_id'] ?? 0,
      toName: json['to_name'] ?? '',
      busId: json['bus_id'] ?? 0,
      busName: json['bus_name'] ?? '',
      busPlate: json['bus_plate'] ?? '',
      busFleetType: json['bus_fleet_type'] ?? '',
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      totalSeat: json['total_seat'] ?? 0,
      bookedSeat: json['booked_seat'] ?? 0,
      remainingSeats: json['remaining_seats'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'trip_date': tripDate,
      'from_id': fromId,
      'from_name': fromName,
      'to_id': toId,
      'to_name': toName,
      'bus_id': busId,
      'bus_name': busName,
      'bus_plate': busPlate,
      'bus_fleet_type': busFleetType,
      'user_id': userId,
      'user_name': userName,
      'total_seat': totalSeat,
      'booked_seat': bookedSeat,
      'remaining_seats': remainingSeats,
    };
  }
}
