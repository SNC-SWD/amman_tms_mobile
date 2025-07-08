import 'package:amman_tms_mobile/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/bus_info.dart';
import '../models/bus_status.dart';

class BusListItemWidget extends StatelessWidget {
  final BusInfo busInfo;
  final BusStatus busStatus;
  final VoidCallback onTap;

  const BusListItemWidget({
    super.key,
    required this.busInfo,
    required this.busStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusName = busInfo.vehicle.state?.name ?? 'N/A';
    Color statusColor;
    switch (statusName) {
      case 'Trip Confirmed':
        statusColor = Theme.of(context).primaryColor;
        break;
      case 'Ready':
        statusColor = Colors.green;
        break;
      case 'On Trip':
        statusColor = Colors.blue;
        break;
      case 'Maintenance':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          busInfo.vehicle.name ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Text(
                            statusName,
                            style: const TextStyle(color: Colors.white, fontSize: 12.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Driver: ${busInfo.vehicle.driver?.name ?? 'N/A'}',
                      style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Last Update: ${busInfo.lastUpdate.replaceAll('T', ' ').substring(0, 16) ?? 'N/A'}',
                      style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
