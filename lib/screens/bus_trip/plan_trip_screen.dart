import 'package:amman_tms_mobile/core/services/bus_trip_service.dart';
import 'package:amman_tms_mobile/models/bus_trip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'trip_confirmation_screen.dart';

const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);
const kSlateGray = Color(0xFF4C5C74);
const kSoftGold = Color(0xFFE0B352);
const kBlueTint = Color(0xFFE6EDF6);

class PlanTripScreen extends StatefulWidget {
  final String? userId;
  final String? tripDate;
  final String? startDate;
  final String? endDate;
  final String? busStatusSeq;
  const PlanTripScreen({
    super.key,
    this.userId,
    this.tripDate,
    this.startDate,
    this.endDate,
    this.busStatusSeq,
  });

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final BusTripService _busTripService = BusTripService();
  List<Map<String, dynamic>> _planTrips = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlanTrips();
  }

  Future<void> _loadPlanTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      String? userId = widget.userId;
      // Prioritaskan filter baru jika ada
      if (widget.startDate != null &&
          widget.endDate != null &&
          widget.busStatusSeq != null) {
        final result = await _busTripService.getBusTrips(
          startDate: widget.startDate,
          endDate: widget.endDate,
          userId: userId,
          busStatusSeq: widget.busStatusSeq,
        );
        if (result['status'] == true) {
          final List<dynamic> planTripsData = result['data'];
          setState(() {
            _planTrips = planTripsData.cast<Map<String, dynamic>>();
          });
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      } else {
        // fallback ke tripDate lama
        String? tripDate = widget.tripDate;
        final result = await _busTripService.getPlanTrips(
          tripDate: (tripDate != null && tripDate.isNotEmpty) ? tripDate : '',
          userId: userId,
        );
        if (result['status'] == true) {
          final List<dynamic> planTripsData = result['data'];
          setState(() {
            _planTrips = planTripsData.cast<Map<String, dynamic>>();
          });
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load plan trips: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    try {
      if (dateStr == null) return '';
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr ?? '';
    }
  }

  Widget _buildPlanTripCard(Map<String, dynamic> plan) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: kAccentGold.withOpacity(0.18), width: 1.2),
      ),
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: kAccentGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(14),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: kAccentGold,
                size: 32,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _formatDate(plan['trip_date']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kAccentGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kBlueTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${plan['bus_fleet_type'] ?? ''} / ${plan['bus_plate'] ?? ''}',
                          style: const TextStyle(
                            color: kPrimaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${plan['boarding_point_name'] ?? ''} → ${plan['drop_point_name'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: kPrimaryBlue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, color: kSlateGray, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        plan['user_id_name'] ?? '',
                        style: const TextStyle(color: kSlateGray, fontSize: 13),
                      ),
                      const Spacer(),
                      Icon(Icons.groups_rounded, color: kSoftGold, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        (plan['booked_seat'] ?? 0).toString(),
                        style: const TextStyle(
                          color: kPrimaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () {
                        final busTrip = BusTrip.fromJson(plan);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TripConfirmationScreen(trip: busTrip),
                          ),
                        );
                      },
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Trip to Confirm'),
      ),
      backgroundColor: kLightGray,
      body: RefreshIndicator(
        onRefresh: _loadPlanTrips,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: kSlateGray),
                  textAlign: TextAlign.center,
                ),
              )
            : _planTrips.isEmpty
            ? const Center(
                child: Text(
                  'No trip to confirm found',
                  style: TextStyle(color: kSlateGray),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _planTrips.length,
                itemBuilder: (context, index) {
                  return _buildPlanTripCard(_planTrips[index]);
                },
              ),
      ),
    );
  }
}
