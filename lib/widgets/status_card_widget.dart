import 'package:amman_tms_mobile/widgets/timeline_route_view.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StatusCardWidget extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? unit;
  final Color? color;

  const StatusCardWidget({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Theme.of(context).primaryColor;
    return Column(
      children: [
        FaIcon(icon, size: 24, color: defaultColor),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: defaultColor,
              ),
            ),
            if (unit != null) const SizedBox(width: 4),
            if (unit != null)
              Text(unit!, style: TextStyle(fontSize: 14, color: kPrimaryBlue)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: kPrimaryBlue)),
      ],
    );
  }
}
