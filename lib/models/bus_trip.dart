import 'package:amman_tms_mobile/models/bus_point.dart';
import 'package:amman_tms_mobile/models/route_line.dart';

class BusTrip {
  final int id;
  final String name;
  final int routeId;
  final String routeName;
  final int busId;
  final String busFleetType;
  final String busPlate;
  final String tripDate;
  final int totalSeat;
  final int seatBooked;
  final int remainingSeats;
  final int boardingPointId;
  final String boardingPointName;
  final int dropPointId;
  final String dropPointName;
  final double startTime;
  final double endTime;
  final String userIdName;
  final int userId;
  final int? statusSeq;
  final List<RouteLine>? routeLineIds;

  BusTrip({
    required this.id,
    required this.name,
    required this.routeId,
    required this.routeName,
    required this.busId,
    required this.busFleetType,
    required this.busPlate,
    required this.tripDate,
    required this.totalSeat,
    required this.seatBooked,
    required this.remainingSeats,
    required this.boardingPointId,
    required this.boardingPointName,
    required this.dropPointId,
    required this.dropPointName,
    required this.startTime,
    required this.endTime,
    required this.userIdName,
    required this.userId,
    this.statusSeq,
    this.routeLineIds,
  });

  factory BusTrip.fromJson(Map<String, dynamic> json) {
    return BusTrip(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      routeId: int.tryParse(json['route_id']?.toString() ?? '') ?? 0,
      routeName: json['route_name']?.toString() ?? '',
      busId: int.tryParse(json['bus_id']?.toString() ?? '') ?? 0,
      busFleetType: json['bus_fleet_type']?.toString() ?? '',
      busPlate: json['bus_plate']?.toString() ?? '',
      tripDate: json['trip_date']?.toString() ?? '',
      totalSeat: int.tryParse(json['total_seat']?.toString() ?? '') ?? 0,
      seatBooked: int.tryParse(json['booked_seat']?.toString() ?? '') ?? 0,
      remainingSeats:
          int.tryParse(json['remaining_seats']?.toString() ?? '') ?? 0,
      boardingPointId:
          int.tryParse(json['boarding_point_id']?.toString() ?? '') ?? 0,
      boardingPointName: json['boarding_point_name']?.toString() ?? '',
      dropPointId: int.tryParse(json['drop_point_id']?.toString() ?? '') ?? 0,
      dropPointName: json['drop_point_name']?.toString() ?? '',
      startTime: double.tryParse(json['start_time']?.toString() ?? '') ?? 0.0,
      endTime: double.tryParse(json['end_time']?.toString() ?? '') ?? 0.0,
      userIdName: json['user_id_name']?.toString() ?? '',
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      statusSeq: json['status_bus_trip_sec'] != null
          ? int.tryParse(json['status_bus_trip_sec'].toString())
          : null,
      routeLineIds: (json['route_line_ids'] as List<dynamic>?)
          ?.map((e) => RouteLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get busInfo => '$busFleetType/$busPlate';

  String get timeRange {
    final startHour = startTime.floor();
    final startMinute = ((startTime - startHour) * 60).round();
    final endHour = endTime.floor();
    final endMinute = ((endTime - endHour) * 60).round();

    return '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} - ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }
}
