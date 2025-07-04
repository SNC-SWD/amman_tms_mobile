import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'models/bus_trip.dart';

const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);
const kSlateGray = Color(0xFF4C5C74);
const kSoftGold = Color(0xFFE0B352);
const kBlueTint = Color(0xFFE6EDF6);

class BusTripDetailScreen extends StatelessWidget {
  final BusTrip trip;

  const BusTripDetailScreen({super.key, required this.trip});

  // Responsive helpers
  double responsiveFont(double base, BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 320) return base * 0.8; // Very small phones
    if (width < 360) return base * 0.85; // Small phones
    if (width < 400) return base * 0.9; // Medium phones
    if (width < 480) return base * 0.95; // Large phones
    if (width > 600) return base * 1.1; // Tablets
    return base; // Default
  }

  double responsivePadding(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 320) return 6.0; // Very small phones
    if (width < 360) return 10.0; // Small phones
    if (width < 400) return 16.0; // Medium phones
    if (width < 480) return 20.0; // Large phones
    if (width > 600) return 40.0; // Tablets
    return 24.0; // Default
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = responsivePadding(context);

    return Scaffold(
      backgroundColor: kLightGray,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: kPrimaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                trip.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: responsiveFont(16, context),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kPrimaryBlue,
                          kPrimaryBlue.withAlpha(204),
                        ], // 0.8 * 255 = 204
                      ),
                    ),
                  ),
                  // Decorative elements
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kAccentGold.withAlpha(
                          26,
                        ), // 0.1 * 255 = 25.5 ≈ 26
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kSoftGold.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  _buildStatusCard(context),
                  SizedBox(height: responsiveFont(24, context)),
                  // Trip Info Card
                  _buildInfoCard(context),
                  SizedBox(height: responsiveFont(24, context)),
                  // Route Details
                  _buildRouteDetails(context),
                  SizedBox(height: responsiveFont(24, context)),
                  // Bus Details
                  _buildBusDetails(context),
                  SizedBox(height: responsiveFont(24, context)),
                  // Passenger Stats
                  _buildPassengerStats(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    // Status logic - following the same logic as other screens
    int statusSeq = trip.statusSeq ?? 0;
    String statusLabel = 'Ready';
    Color statusColor = Colors.grey;
    switch (statusSeq) {
      case 0:
        statusLabel = 'Ready';
        statusColor = Colors.grey;
        break;
      case 1:
        statusLabel = 'Trip Confirmed';
        statusColor = Colors.blue;
        break;
      case 2:
        statusLabel = 'On Trip';
        statusColor = Colors.green;
        break;
      case 3:
        statusLabel = 'End Trip';
        statusColor = Colors.red;
        break;
    }

    return Container(
      padding: EdgeInsets.all(responsiveFont(20, context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withAlpha(13), // 0.05 * 255 = 12.75 ≈ 13
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(responsiveFont(12, context)),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_rounded,
              color: statusColor,
              size: responsiveFont(24, context),
            ),
          ),
          SizedBox(width: responsiveFont(16, context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    color: kSlateGray,
                    fontSize: responsiveFont(14, context),
                  ),
                ),
                SizedBox(height: responsiveFont(4, context)),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: responsiveFont(18, context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(responsiveFont(20, context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withAlpha(13), // 0.05 * 255 = 12.75 ≈ 13
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsiveFont(12, context)),
                decoration: BoxDecoration(
                  color: kAccentGold.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.confirmation_number_rounded,
                  color: kAccentGold,
                  size: responsiveFont(24, context),
                ),
              ),
              SizedBox(width: responsiveFont(16, context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip ID',
                      style: TextStyle(
                        color: kSlateGray,
                        fontSize: responsiveFont(14, context),
                      ),
                    ),
                    SizedBox(height: responsiveFont(4, context)),
                    Text(
                      trip.name,
                      style: TextStyle(
                        color: kPrimaryBlue,
                        fontSize: responsiveFont(18, context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsiveFont(20, context)),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsiveFont(12, context)),
                decoration: BoxDecoration(
                  color: kSoftGold.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: kSoftGold,
                  size: responsiveFont(24, context),
                ),
              ),
              SizedBox(width: responsiveFont(16, context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Date',
                      style: TextStyle(
                        color: kSlateGray,
                        fontSize: responsiveFont(14, context),
                      ),
                    ),
                    SizedBox(height: responsiveFont(4, context)),
                    Text(
                      trip.tripDate,
                      style: TextStyle(
                        color: kPrimaryBlue,
                        fontSize: responsiveFont(18, context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(responsiveFont(20, context)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kPrimaryBlue.withAlpha(13), // 0.05 * 255 = 12.75 ≈ 13
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route Details',
                style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: responsiveFont(18, context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: responsiveFont(20, context)),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(responsiveFont(12, context)),
                    decoration: BoxDecoration(
                      color: kAccentGold.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.alt_route,
                      color: kAccentGold,
                      size: responsiveFont(24, context),
                    ),
                  ),
                  SizedBox(width: responsiveFont(16, context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route Name',
                          style: TextStyle(
                            color: kSlateGray,
                            fontSize: responsiveFont(14, context),
                          ),
                        ),
                        SizedBox(height: responsiveFont(4, context)),
                        Text(
                          trip.routeName,
                          style: TextStyle(
                            color: kPrimaryBlue,
                            fontSize: responsiveFont(18, context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsiveFont(16, context)),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(responsiveFont(12, context)),
                    decoration: BoxDecoration(
                      color: kSoftGold.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: kSoftGold,
                      size: responsiveFont(24, context),
                    ),
                  ),
                  SizedBox(width: responsiveFont(16, context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: TextStyle(
                            color: kSlateGray,
                            fontSize: responsiveFont(14, context),
                          ),
                        ),
                        SizedBox(height: responsiveFont(4, context)),
                        Text(
                          trip.timeRange,
                          style: TextStyle(
                            color: kPrimaryBlue,
                            fontSize: responsiveFont(18, context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (trip.routeLineIds != null && trip.routeLineIds!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: responsiveFont(24, context)),
            child: Container(
              padding: EdgeInsets.all(responsiveFont(20, context)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withAlpha(
                      13,
                    ), // 0.05 * 255 = 12.75 ≈ 13
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Timeline',
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontSize: responsiveFont(18, context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: responsiveFont(2, context)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trip.routeLineIds!.length,
                    itemBuilder: (context, index) {
                      final routeLine = trip.routeLineIds![index];
                      final isFirst = index == 0;
                      final isLast = index == trip.routeLineIds!.length - 1;

                      return TimelineTile(
                        alignment: TimelineAlign.start,
                        isFirst: isFirst,
                        isLast: isLast,
                        beforeLineStyle: const LineStyle(
                          color: kAccentGold,
                          thickness: 2,
                        ),
                        afterLineStyle: const LineStyle(
                          color: kAccentGold,
                          thickness: 2,
                        ),
                        indicatorStyle: IndicatorStyle(
                          width: responsiveFont(30, context),
                          height: responsiveFont(30, context),
                          indicator: Container(
                            decoration: BoxDecoration(
                              color: kAccentGold,
                              shape: BoxShape.circle,
                              border: Border.all(color: kPrimaryBlue, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                (index + 1).toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: responsiveFont(14, context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        endChild: Padding(
                          padding: EdgeInsets.all(responsiveFont(8, context)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${routeLine.from} to ${routeLine.to}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsiveFont(16, context),
                                  color: kPrimaryBlue,
                                ),
                              ),
                              SizedBox(height: responsiveFont(4, context)),
                              Text(
                                '${routeLine.startTime ?? ""} - ${routeLine.endTime ?? ""}',
                                style: TextStyle(
                                  fontSize: responsiveFont(14, context),
                                  color: kSlateGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBusDetails(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(responsiveFont(20, context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withAlpha(13), // 0.05 * 255 = 12.75 ≈ 13
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bus Details',
            style: TextStyle(
              color: kPrimaryBlue,
              fontSize: responsiveFont(18, context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: responsiveFont(20, context)),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsiveFont(12, context)),
                decoration: BoxDecoration(
                  color: kAccentGold.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: kAccentGold,
                  size: responsiveFont(24, context),
                ),
              ),
              SizedBox(width: responsiveFont(16, context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus Type',
                      style: TextStyle(
                        color: kSlateGray,
                        fontSize: responsiveFont(14, context),
                      ),
                    ),
                    SizedBox(height: responsiveFont(4, context)),
                    Text(
                      trip.busFleetType,
                      style: TextStyle(
                        color: kPrimaryBlue,
                        fontSize: responsiveFont(18, context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsiveFont(20, context)),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsiveFont(12, context)),
                decoration: BoxDecoration(
                  color: kSoftGold.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: kSoftGold,
                  size: responsiveFont(24, context),
                ),
              ),
              SizedBox(width: responsiveFont(16, context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus Status',
                      style: TextStyle(
                        color: kSlateGray,
                        fontSize: responsiveFont(14, context),
                      ),
                    ),
                    SizedBox(height: responsiveFont(4, context)),
                    Text(
                      trip.busIdStatusName ?? 'N/A',
                      style: TextStyle(
                        color: kPrimaryBlue,
                        fontSize: responsiveFont(18, context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsiveFont(20, context)),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsiveFont(12, context)),
                decoration: BoxDecoration(
                  color: kSoftGold.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.confirmation_number_rounded,
                  color: kSoftGold,
                  size: responsiveFont(24, context),
                ),
              ),
              SizedBox(width: responsiveFont(16, context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'License Plate',
                      style: TextStyle(
                        color: kSlateGray,
                        fontSize: responsiveFont(14, context),
                      ),
                    ),
                    SizedBox(height: responsiveFont(4, context)),
                    Text(
                      trip.busPlate,
                      style: TextStyle(
                        color: kPrimaryBlue,
                        fontSize: responsiveFont(18, context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerStats(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(responsiveFont(20, context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withAlpha(13), // 0.05 * 255 = 12.75 ≈ 13
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passenger Statistics',
            style: TextStyle(
              color: kPrimaryBlue,
              fontSize: responsiveFont(18, context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: responsiveFont(20, context)),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.event_seat_rounded,
                  color: kAccentGold,
                  title: 'Total Seats',
                  value: trip.totalSeat.toString(),
                ),
              ),
              SizedBox(width: responsiveFont(16, context)),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.groups_rounded,
                  color: kSoftGold,
                  title: 'Booked',
                  value: trip.seatBooked.toString(),
                ),
              ),
              SizedBox(width: responsiveFont(16, context)),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.event_available_rounded,
                  color: kPrimaryBlue,
                  title: 'Available',
                  value: trip.remainingSeats.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(responsiveFont(16, context)),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: responsiveFont(24, context)),
          SizedBox(height: responsiveFont(8, context)),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: responsiveFont(14, context),
            ),
          ),
          SizedBox(height: responsiveFont(4, context)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: responsiveFont(20, context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
