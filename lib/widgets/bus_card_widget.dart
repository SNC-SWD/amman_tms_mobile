import 'dart:convert';
import 'package:amman_tms_mobile/models/bus_model.dart';
import 'package:flutter/material.dart';

class BusCard extends StatelessWidget {
  final Bus bus;

  const BusCard({super.key, required this.bus});

  // Helper widget untuk membuat chip status dengan warna dan ikon yang sesuai
  Widget _buildStatusChip(String status) {
    Color chipColor;
    String chipText;
    IconData chipIcon;

    String normalizedStatus = status.toLowerCase().replaceAll(' ', '');

    switch (normalizedStatus) {
      case 'ready':
        chipColor = Colors.green.shade600;
        chipText = 'Siap Jalan';
        chipIcon = Icons.check_circle_outline;
        break;
      case 'tripconfirmed':
        chipColor = Colors.teal;
        chipText = 'Trip Dikonfirmasi';
        chipIcon = Icons.confirmation_number_outlined;
        break;
      case 'ontrip':
        chipColor = Colors.blueAccent;
        chipText = 'Dalam Perjalanan';
        chipIcon = Icons.directions_bus_filled;
        break;
      case 'endtrip':
        chipColor = Colors.purple;
        chipText = 'Trip Selesai';
        chipIcon = Icons.flag_outlined;
        break;
      case 'standby':
        chipColor = Colors.grey.shade600;
        chipText = 'Standby';
        chipIcon = Icons.watch_later_outlined;
        break;
      case 'maintenance':
        chipColor = Colors.orange.shade700;
        chipText = 'Perawatan';
        chipIcon = Icons.build_circle_outlined;
        break;
      case 'changeshift':
        chipColor = Colors.amber.shade800;
        chipText = 'Ganti Shift';
        chipIcon = Icons.people_alt_outlined;
        break;
      case 'rest':
        chipColor = Colors.indigo;
        chipText = 'Istirahat';
        chipIcon = Icons.hotel_outlined;
        break;
      default:
        chipColor = Colors.black45;
        chipText = status;
        chipIcon = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(chipIcon, color: Colors.white, size: 18),
      label: Text(
        chipText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }

  // Helper widget untuk menampilkan baris informasi dengan ikon
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Detail untuk bus ${bus.licensePlate}')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bus.licensePlate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(bus.status),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  bus.fleetType,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                Text(
                  'Model: ${bus.modelName}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),

                const Divider(height: 24, thickness: 1),

                _buildInfoRow(Icons.person_outline, bus.driver),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
