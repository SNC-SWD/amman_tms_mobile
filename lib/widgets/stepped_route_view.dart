import 'package:flutter/material.dart';
import '../models/route_line.dart' as model_route_line;

const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kSlateGray = Color(0xFF4C5C74);
const kBlueTint = Color(0xFFE6EDF6);

class SteppedRouteView extends StatelessWidget {
  final List<model_route_line.RouteLine> lines;
  final String Function(String?, String?) calculateDuration;

  const SteppedRouteView({
    super.key,
    required this.lines,
    required this.calculateDuration,
  });

  String _formatTime(String? time) {
    if (time == null) return '-';
    try {
      final parts = time.split('.');
      if (parts.length != 2) return time;
      final hours = int.parse(parts[0]).toString().padLeft(2, '0');
      final minutes = parts[1].padLeft(2, '0');
      return '$hours:$minutes';
    } catch (_) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(lines.length, (index) {
        final line = lines[index];
        final isLast = index == lines.length - 1;

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: kBlueTint.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_bus_rounded,
                          color: kAccentGold,
                          size: 20,
                        ), // MODIFIED
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            line.from,
                            style: const TextStyle(
                              fontSize: 14, // MODIFIED
                              fontWeight: FontWeight.bold,
                              color: kPrimaryBlue,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      16,
                    ), // MODIFIED
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context,
                          icon: Icons.play_circle_outline_rounded,
                          iconColor: Colors.green,
                          label: 'Berangkat:',
                          value: _formatTime(line.startTime),
                        ),
                        const SizedBox(height: 10), // MODIFIED
                        _buildInfoRow(
                          context,
                          icon: Icons.flag_circle_rounded,
                          iconColor: kAccentGold,
                          label: 'Tiba:',
                          value: _formatTime(line.endTime),
                        ),
                        const SizedBox(height: 10), // MODIFIED
                        _buildInfoRow(
                          context,
                          icon: Icons.alt_route_rounded,
                          iconColor: const Color(0xFFE57373),
                          label: 'Rute:',
                          value: '${line.from} ➝ ${line.to}',
                          isRoute: true,
                        ),
                        const SizedBox(height: 10), // MODIFIED
                        _buildInfoRow(
                          context,
                          icon: Icons.timer_rounded,
                          iconColor: kSlateGray,
                          label: 'Durasi:',
                          value: calculateDuration(
                            line.startTime,
                            line.endTime,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            if (!isLast)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: const Icon(Icons.more_vert, color: kBlueTint),
              ),
          ],
        );
      }),
    );
  }

  // Helper widget untuk membuat baris info agar kode tidak berulang
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isRoute = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18), // MODIFIED
        const SizedBox(width: 12),
        SizedBox(
          width: 65, // MODIFIED
          child: Text(
            label,
            style: const TextStyle(
              color: kSlateGray,
              fontSize: 12, // MODIFIED
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isRoute ? iconColor : kPrimaryBlue,
              fontSize: 12, // MODIFIED
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
