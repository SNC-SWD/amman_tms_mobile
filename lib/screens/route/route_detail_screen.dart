import 'package:amman_tms_mobile/screens/route/route_form_screen.dart';
import 'package:amman_tms_mobile/screens/route/routes_screen.dart';
import 'package:amman_tms_mobile/widgets/stepped_route_view.dart';
import 'package:amman_tms_mobile/widgets/timeline_route_view.dart';
import 'package:flutter/material.dart';

// --- Color Palette ---
const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);
const kSlateGray = Color(0xFF4C5C74);
const kSoftGold = Color(0xFFE0B352);
const kBlueTint = Color(0xFFE6EDF6);

class RouteDetailScreen extends StatefulWidget {
  final RouteData route;
  final String userRole;
  final Function(RouteData)? onRouteUpdated;
  const RouteDetailScreen({
    super.key,
    required this.route,
    required this.userRole,
    this.onRouteUpdated,
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  late RouteData _currentRoute;
  bool _timelineMode = true;

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.route;
  }

  String _formatTime(String? time) {
    if (time == null) return '-';
    try {
      final parts = time.split('.');
      return '${parts[0].padLeft(2, '0')}:${parts.length > 1 ? parts[1].padLeft(2, '0') : '00'}';
    } catch (e) {
      return time;
    }
  }

  String _calculateDuration(String? start, String? end) {
    if (start == null || end == null) return '-';
    try {
      final startTotal =
          int.parse(start.split('.')[0]) * 60 + int.parse(start.split('.')[1]);
      final endTotal =
          int.parse(end.split('.')[0]) * 60 + int.parse(end.split('.')[1]);
      int diff = endTotal - startTotal;
      if (diff < 0) diff += 24 * 60;
      final hours = diff ~/ 60;
      final minutes = diff % 60;
      if (hours > 0) {
        return minutes > 0 ? '$hours j $minutes m' : '$hours jam';
      } else {
        return '$minutes menit';
      }
    } catch (_) {
      return '-';
    }
  }

  void _editRoute() async {
    final result = await pushWithTransition(
      context,
      RouteFormScreen(title: "Edit Rute", initialData: _currentRoute),
    );
    if (result == true) {
      // Refresh detail, ideally reload from API, for now just pop and reload parent
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // trigger parent refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryBlue,
        elevation: 0.5,
        title: const Text(
          'Detail Rute',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          if (widget.userRole != 'driver')
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: kAccentGold),
              tooltip: 'Edit Rute',
              onPressed: _editRoute,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailHeader(),
            const SizedBox(height: 24),
            _buildRouteLinesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentRoute.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kPrimaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.directions_bus, color: kSlateGray, size: 16),
              const SizedBox(width: 8),
              Text(
                _currentRoute.bus,
                style: const TextStyle(
                  fontSize: 14,
                  color: kSlateGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.timer_outlined, color: kSlateGray, size: 16),
              const SizedBox(width: 8),
              Text(
                '${_formatTime(_currentRoute.startTime)} - ${_formatTime(_currentRoute.endTime)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: kSlateGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          IntrinsicHeight(
            child: Row(
              children: [
                _buildDetailInfo(
                  Icons.my_location,
                  "Boarding",
                  _currentRoute.boardingPoint ?? '-',
                ),
                const VerticalDivider(width: 24, thickness: 1),
                _buildDetailInfo(
                  Icons.flag,
                  "Dropping",
                  _currentRoute.droppingPoint ?? '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailInfo(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: kSlateGray.withOpacity(0.8),
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: kPrimaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteLinesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Route Lines',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: kPrimaryBlue,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: kBlueTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ToggleButtons(
                isSelected: [_timelineMode, !_timelineMode],
                onPressed: (index) =>
                    setState(() => _timelineMode = index == 0),
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                color: kPrimaryBlue,
                fillColor: kPrimaryBlue,
                splashColor: kPrimaryBlue.withOpacity(0.2),
                borderWidth: 0,
                selectedBorderColor: kPrimaryBlue,
                constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.timeline, size: 20),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.view_agenda, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_currentRoute.lines == null || _currentRoute.lines!.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.alt_route, size: 40, color: kSlateGray),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada route line',
                    style: TextStyle(
                      color: kSlateGray,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _timelineMode
              ? TimelineRouteView(
                  lines: _currentRoute.lines!,
                  calculateDuration: _calculateDuration,
                )
              : SteppedRouteView(
                  lines: _currentRoute.lines!,
                  calculateDuration: _calculateDuration,
                ),
      ],
    );
  }
}
