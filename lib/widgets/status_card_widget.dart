// file: lib/widgets/status_card_widget.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StatusCardWidget extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? unit;
  final Color? color;
  // Tambahkan parameter warna
  final Color cardColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;

  const StatusCardWidget({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.unit,
    this.color,
    // Inisialisasi parameter warna
    required this.cardColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? accentColor;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 20, color: defaultColor),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (unit != null) const SizedBox(width: 4),
                if (unit != null)
                  Text(
                    unit!,
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: secondaryTextColor,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
