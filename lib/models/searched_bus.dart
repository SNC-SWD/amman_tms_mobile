// lib/core/models/searched_bus.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Sub-model untuk setiap segmen dalam route_lines
class RouteLine {
  final int id;
  final String fromName;
  final String toName;
  final String startTime;
  final String endTime;
  final String duration;

  RouteLine({
    required this.id,
    required this.fromName,
    required this.toName,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  factory RouteLine.fromJson(Map<String, dynamic> json) {
    final double start = (json['start_times'] ?? -1.0).toDouble();
    final double end = (json['end_times'] ?? -1.0).toDouble();

    return RouteLine(
      id: json['id'] ?? 0,
      fromName: json['from_name'] ?? 'N/A',
      toName: json['to_name'] ?? 'N/A',
      startTime: _formatTime(start),
      endTime: _formatTime(end),
      duration: _calculateDuration(start, end),
    );
  }
}

// Model utama untuk data perjalanan
class SearchedBus {
  final int id;
  final String tripName;
  final int totalSeats;
  final int bookedSeats;
  final int remainingSeats;
  final String tripStatus;
  final String tripDate;
  final String routeName;
  final String busName;
  final List<RouteLine> routeLines;

  // Properti tambahan untuk kemudahan akses di UI
  final String overallStartTime;
  final String overallEndTime;
  final String startLocation;
  final String endLocation;
  final String overallDuration;

  SearchedBus({
    required this.id,
    required this.tripName,
    required this.totalSeats,
    required this.bookedSeats,
    required this.remainingSeats,
    required this.tripStatus,
    required this.tripDate,
    required this.routeName,
    required this.busName,
    required this.routeLines,
    required this.overallStartTime,
    required this.overallEndTime,
    required this.startLocation,
    required this.endLocation,
    required this.overallDuration,
  });

  factory SearchedBus.fromJson(Map<String, dynamic> json) {
    List<RouteLine> lines = [];
    if (json['route_lines'] != null && json['route_lines'] is List) {
      lines = (json['route_lines'] as List)
          .map((lineJson) => RouteLine.fromJson(lineJson))
          .toList();
    }

    final double overallStartFloat = (json['route_start_time'] ?? -1.0)
        .toDouble();
    final double overallEndFloat = (json['route_end_time'] ?? -1.0).toDouble();

    return SearchedBus(
      id: json['id'] ?? 0,
      tripName: json['name'] ?? 'N/A',
      totalSeats: json['trip_total_seat'] ?? 0,
      bookedSeats: json['trip_booked_seat'] ?? 0,
      remainingSeats: json['trip_remaining_seats'] ?? 0,
      tripStatus: json['trip_status'] ?? 'N/A',
      tripDate: json['trip_date'] ?? 'N/A',
      routeName: json['route_name'] ?? 'N/A',
      busName: json['bus_name'] ?? 'N/A',
      routeLines: lines,

      // Data yang disederhanakan untuk UI
      overallStartTime: _formatTime(overallStartFloat),
      overallEndTime: _formatTime(overallEndFloat),
      startLocation: lines.isNotEmpty ? lines.first.fromName : 'N/A',
      endLocation: lines.isNotEmpty ? lines.last.toName : 'N/A',
      overallDuration: _calculateDuration(overallStartFloat, overallEndFloat),
    );
  }
}

// Helper functions (di luar kelas agar bisa diakses oleh keduanya)
String _formatTime(double timeInHours) {
  if (timeInHours < 0) return "--:--";
  final int hours = timeInHours.floor();
  final int minutes = ((timeInHours - hours) * 60).round();
  final NumberFormat formatter = NumberFormat("00");
  return '${formatter.format(hours)}:${formatter.format(minutes)}';
}

String _calculateDuration(double startTime, double endTime) {
  if (startTime < 0 || endTime < 0 || endTime < startTime) return "N/A";
  final double durationInHours = endTime - startTime;
  final int hours = durationInHours.floor();
  final int minutes = ((durationInHours - hours) * 60).round();

  String durationString = "";
  if (hours > 0) {
    durationString += "${hours}h ";
  }
  if (minutes > 0) {
    durationString += "${minutes}m";
  }
  return durationString.trim().isEmpty ? "0m" : durationString.trim();
}
