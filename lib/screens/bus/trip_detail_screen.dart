// lib/features/passenger/screens/trip_detail_screen.dart

import 'package:amman_tms_mobile/models/searched_bus.dart';
import 'package:amman_tms_mobile/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:timeline_tile/timeline_tile.dart';

class TripDetailScreen extends StatelessWidget {
  final SearchedBus trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBusInfoCard(),
                  const SizedBox(height: 24),
                  Text(
                    'Itinerary',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildItineraryTimeline(),
                ],
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: _buildBookingButton(),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      backgroundColor: kPrimaryBlue,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          trip.routeName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryBlue, kSlateGray],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 50.0, left: 16, right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.startLocation,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        trip.endLocation,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  trip.tripDate,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusInfoCard() {
    double seatPercentage = trip.totalSeats > 0
        ? (trip.bookedSeats / trip.totalSeats)
        : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus, color: kPrimaryBlue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trip.busName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  trip.tripName,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoChip(
                  'Total Seats',
                  trip.totalSeats.toString(),
                  Icons.event_seat,
                ),
                _infoChip(
                  'Remaining',
                  trip.remainingSeats.toString(),
                  Icons.person_add_alt_1,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (trip.totalSeats > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: seatPercentage,
                  minHeight: 8,
                  backgroundColor: Colors.green.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildItineraryTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trip.routeLines.length,
      itemBuilder: (context, index) {
        final line = trip.routeLines[index];
        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.3,
          isFirst: index == 0,
          isLast: index == trip.routeLines.length - 1,
          indicatorStyle: const IndicatorStyle(
            width: 20,
            color: kPrimaryBlue,
            padding: EdgeInsets.all(4),
          ),
          beforeLineStyle: const LineStyle(color: kPrimaryBlue, thickness: 2),
          endChild: _buildTimelineCard(line),
          startChild: _buildTimelineTime(line),
        );
      },
    );
  }

  Widget _buildTimelineTime(RouteLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            line.startTime,
            style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            'depart',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(RouteLine line) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.fromName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.arrow_downward, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${line.duration} to next stop',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          if (line == trip.routeLines.last)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                line.toName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // Aksi untuk booking
        },
        child: Text(
          'Book Now',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
