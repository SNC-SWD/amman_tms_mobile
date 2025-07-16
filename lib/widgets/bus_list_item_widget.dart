// file: lib/widgets/bus_list_item_widget.dart

import 'package:amman_tms_mobile/models/bus_info.dart';
import 'package:amman_tms_mobile/models/bus_status.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BusListItemWidget extends StatelessWidget {
  final BusInfo busInfo;
  final BusStatus busStatus;
  final VoidCallback onTap;
  // Tambahkan parameter warna
  final Color cardColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;

  const BusListItemWidget({
    super.key,
    required this.busInfo,
    required this.busStatus,
    required this.onTap,
    // Inisialisasi parameter warna
    required this.cardColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEngineOn = busStatus.attributes.ignition;
    final bool isMoving = busStatus.attributes.motion;
    Color statusColor;
    String statusText;

    if (isEngineOn && isMoving) {
      statusColor = Colors.greenAccent.shade400;
      statusText = 'Bergerak';
    } else if (isEngineOn && !isMoving) {
      statusColor = accentColor;
      statusText = 'Menyala';
    } else {
      statusColor = Colors.redAccent.shade400;
      statusText = 'Mati';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: primaryTextColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: primaryTextColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.busSimple,
                  color: primaryTextColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    busInfo.vehicle.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: primaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.5),
                            blurRadius: 4.0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${busStatus.speedInKmh.toStringAsFixed(0)} km/h',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
