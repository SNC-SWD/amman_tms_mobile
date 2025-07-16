import 'package:flutter/material.dart';
import '../models/route_line.dart' as model_route_line;

const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kSlateGray = Color(0xFF4C5C74);
const kBlueTint = Color(0xFFE6EDF6);

class TimelineRouteView extends StatelessWidget {
  final List<model_route_line.RouteLine> lines;
  final String Function(String?, String?) calculateDuration;

  const TimelineRouteView({
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
    // Helper untuk ukuran responsif
    double rSize(double baseSize) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth < 360) {
        return baseSize * 0.9;
      }
      return baseSize;
    }

    return Column(
      children: List.generate(lines.length, (index) {
        final line = lines[index];
        final isFirst = index == 0;
        final isLast = index == lines.length - 1;

        String status;
        Color bulletColor;
        if (isFirst) {
          status = 'Start';
          bulletColor = kAccentGold;
        } else if (isLast) {
          status = 'End';
          bulletColor = kPrimaryBlue;
        } else {
          status = 'Transit';
          bulletColor = kSlateGray;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Timeline Axis (Sumbu Waktu)
              SizedBox(
                width: rSize(40), // Lebar sumbu disesuaikan
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Garis vertikal
                    Container(
                      width: 2.5,
                      color: isLast ? Colors.transparent : kBlueTint,
                    ),
                    // Bulatan penanda
                    Container(
                      width: rSize(20), // MODIFIED
                      height: rSize(20), // MODIFIED
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bulletColor,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: bulletColor.withOpacity(0.3),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: rSize(10), // MODIFIED
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 2. Card Konten
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: rSize(16)),
                  child: Container(
                    padding: EdgeInsets.all(rSize(12)), // MODIFIED
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryBlue.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Waktu dan Lokasi
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(line.startTime),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: rSize(14), // MODIFIED
                                color: kPrimaryBlue,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.circle,
                              size: 6,
                              color: kAccentGold,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                line.from,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: rSize(13), // MODIFIED
                                  color: kPrimaryBlue,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Detail Tujuan dan Durasi (di-indent)
                        Padding(
                          padding: EdgeInsets.only(left: rSize(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _formatTime(line.endTime),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: rSize(12), // MODIFIED
                                      color: kAccentGold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.flag_rounded,
                                    color: kAccentGold,
                                    size: 14,
                                  ), // MODIFIED
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      line.to,
                                      style: TextStyle(
                                        fontSize: rSize(12), // MODIFIED
                                        color: kAccentGold,
                                        fontFamily: 'Poppins',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: kSlateGray,
                                    size: 14,
                                  ), // MODIFIED
                                  const SizedBox(width: 6),
                                  Text(
                                    'Durasi: ${calculateDuration(line.startTime, line.endTime)}',
                                    style: TextStyle(
                                      fontSize: rSize(11), // MODIFIED
                                      color: kSlateGray,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
