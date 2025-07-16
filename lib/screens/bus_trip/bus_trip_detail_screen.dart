import 'package:amman_tms_mobile/core/services/bus_trip_service.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:amman_tms_mobile/models/bus_trip.dart';

// Asumsikan model ini ada di 'models/bus_trip.dart' atau file terpisah.
// --- MULAI PENAMBAHAN MODEL BARU ---
class TripChatter {
  final int tripId;
  final String tripName;
  final List<ChatterMessage> chatter;

  TripChatter({
    required this.tripId,
    required this.tripName,
    required this.chatter,
  });

  factory TripChatter.fromJson(Map<String, dynamic> json) {
    var chatterList = json['chatter'] as List;
    List<ChatterMessage> messages = chatterList
        .map((i) => ChatterMessage.fromJson(i))
        .toList();
    return TripChatter(
      tripId: json['trip_id'],
      tripName: json['trip_name'],
      chatter: messages,
    );
  }
}

class ChatterMessage {
  final int id;
  final String date;
  final String author;
  final String body;
  final String subtype;
  final String type;

  ChatterMessage({
    required this.id,
    required this.date,
    required this.author,
    required this.body,
    required this.subtype,
    required this.type,
  });

  factory ChatterMessage.fromJson(Map<String, dynamic> json) {
    return ChatterMessage(
      id: json['id'],
      date: json['date'],
      author: json['author'],
      body: json['body'],
      subtype: json['subtype'],
      type: json['type'],
    );
  }

  // Helper untuk membersihkan HTML dari body
  String get cleanedBody {
    // final document = parse(body);
    // final String? parsedString = document.body?.text;
    // return parsedString ?? body;
    return body.replaceAll(
      RegExp(r'<p>|</p>'),
      '',
    ); // Membersihkan tag <p> sederhana
  }
}
// --- AKHIR PENAMBAHAN MODEL BARU ---

const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);
const kSlateGray = Color(0xFF4C5C74);
const kSoftGold = Color(0xFFE0B352);
const kBlueTint = Color(0xFFE6EDF6);

// --- WIDGET DIUBAH MENJADI STATEFULWIDGET ---
class BusTripDetailScreen extends StatefulWidget {
  final BusTrip trip;

  const BusTripDetailScreen({super.key, required this.trip});

  @override
  State<BusTripDetailScreen> createState() => _BusTripDetailScreenState();
}

class _BusTripDetailScreenState extends State<BusTripDetailScreen> {
  // --- MULAI PENAMBAHAN STATE UNTUK DATA LOG ---
  late final BusTripService _busTripService;
  TripChatter? _tripChatter;
  bool _isLoadingLog = true;
  String? _logErrorMessage;
  // --- AKHIR PENAMBAHAN STATE UNTUK DATA LOG ---

  @override
  void initState() {
    super.initState();
    _busTripService = BusTripService();
    _fetchTripChatter();
  }

  // --- FUNGSI BARU UNTUK MENGAMBIL DATA LOG DARI API ---
  Future<void> _fetchTripChatter() async {
    // Pastikan widget masih ada dalam tree sebelum update state
    if (!mounted) return;

    final response = await _busTripService.getTripChatter(widget.trip.id);

    if (!mounted) return;

    setState(() {
      if (response['status'] == true && response['data'] != null) {
        _tripChatter = TripChatter.fromJson(response['data']);
        if (_tripChatter!.chatter.isEmpty) {
          _logErrorMessage = "Belum ada riwayat untuk perjalanan ini.";
        }
      } else {
        // Gunakan pesan dari service atau pesan default
        _logErrorMessage =
            response['message'] ?? "Gagal memuat riwayat perjalanan.";
      }
      _isLoadingLog = false;
    });
  }

  // Responsive helpers
  double responsiveFont(double base, BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 320) return base * 0.8;
    if (width < 360) return base * 0.85;
    if (width < 400) return base * 0.9;
    if (width < 480) return base * 0.95;
    if (width > 600) return base * 1.1;
    return base;
  }

  double responsivePadding(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 320) return 6.0;
    if (width < 360) return 10.0;
    if (width < 400) return 16.0;
    if (width < 480) return 20.0;
    if (width > 600) return 40.0;
    return 24.0;
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
                widget.trip.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: responsiveFont(16, context),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [kPrimaryBlue, kPrimaryBlue.withAlpha(204)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kAccentGold.withAlpha(26),
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
                        color: kSoftGold.withAlpha(26),
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
                  _buildStatusCard(context),
                  SizedBox(height: responsiveFont(24, context)),
                  _buildInfoCard(context),
                  SizedBox(height: responsiveFont(24, context)),
                  _buildRouteDetails(context),
                  SizedBox(height: responsiveFont(24, context)),
                  _buildBusDetails(context),
                  SizedBox(height: responsiveFont(24, context)),
                  _buildPassengerStats(context),
                  SizedBox(height: responsiveFont(24, context)),
                  // --- MULAI SECTION LOG YANG DINAMIS ---
                  _buildTripLogSection(context),
                  // --- AKHIR SECTION LOG YANG DINAMIS ---
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Widget _buildStatusCard, _buildInfoCard, dll tetap sama, hanya perlu mengganti `trip` menjadi `widget.trip`)
  Widget _buildStatusCard(BuildContext context) {
    int statusSeq = widget.trip.statusSeq ?? 0;
    // ... sisa implementasi sama
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
            color: kPrimaryBlue.withAlpha(13),
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
                  color: kAccentGold.withAlpha(26),
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
                      widget.trip.name,
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
                      widget.trip.tripDate,
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
                color: kPrimaryBlue.withAlpha(13),
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
                      color: kAccentGold.withAlpha(26),
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
                          widget.trip.routeName,
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
                      color: kSoftGold.withAlpha(26),
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
                          widget.trip.timeRange,
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
        if (widget.trip.routeLineIds != null &&
            widget.trip.routeLineIds!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: responsiveFont(24, context)),
            child: Container(
              padding: EdgeInsets.all(responsiveFont(20, context)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withAlpha(13),
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
                    itemCount: widget.trip.routeLineIds!.length,
                    itemBuilder: (context, index) {
                      final routeLine = widget.trip.routeLineIds![index];
                      final isFirst = index == 0;
                      final isLast =
                          index == widget.trip.routeLineIds!.length - 1;

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
            color: kPrimaryBlue.withAlpha(13),
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
          _buildPunctualityStatus(context),
          SizedBox(height: responsiveFont(20, context)),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsiveFont(12, context)),
                decoration: BoxDecoration(
                  color: kAccentGold.withAlpha(26),
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
                      widget.trip.busFleetType,
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
                      widget.trip.busIdStatusName ?? 'N/A',
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
                      widget.trip.busPlate,
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
            color: kPrimaryBlue.withAlpha(13),
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
                  value: widget.trip.totalSeat.toString(),
                ),
              ),
              SizedBox(width: responsiveFont(16, context)),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.groups_rounded,
                  color: kSoftGold,
                  title: 'Booked',
                  value: widget.trip.seatBooked.toString(),
                ),
              ),
              SizedBox(width: responsiveFont(16, context)),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.event_available_rounded,
                  color: kPrimaryBlue,
                  title: 'Available',
                  value: widget.trip.remainingSeats.toString(),
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
        color: color.withAlpha(26),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  Widget _buildPunctualityStatus(BuildContext context) {
    String statusText;
    Color statusColor;

    switch (widget.trip.punctualityStatus) {
      case 0:
        statusText = 'Start Trip - On Time';
        statusColor = Colors.green;
        break;
      case 1:
        statusText = 'Start Trip - Late';
        statusColor = Colors.red;
        break;
      case 2:
        statusText = 'End Trip - On Time';
        statusColor = Colors.green;
        break;
      case 3:
        statusText = 'End Trip - Late';
        statusColor = Colors.red;
        break;
      default:
        statusText = 'Punctuality status not available';
        statusColor = Colors.grey;
        break;
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(responsiveFont(12, context)),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.access_time_rounded,
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
                'Punctuality Status',
                style: TextStyle(
                  color: kSlateGray,
                  fontSize: responsiveFont(14, context),
                ),
              ),
              SizedBox(height: responsiveFont(4, context)),
              Text(
                statusText,
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
    );
  }

  // --- WIDGET KONDISIONAL BARU UNTUK MENAMPILKAN LOG ---
  Widget _buildTripLogSection(BuildContext context) {
    // Tampilkan indikator pemuatan
    if (_isLoadingLog) {
      return const Center(child: CircularProgressIndicator());
    }

    // Tampilkan pesan jika ada kendala atau data kosong
    if (_logErrorMessage != null) {
      return Container(
        padding: EdgeInsets.all(responsiveFont(20, context)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            _logErrorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: responsiveFont(15, context),
              color: kSlateGray,
            ),
          ),
        ),
      );
    }

    // Jika data berhasil dimuat, tampilkan riwayat
    if (_tripChatter != null) {
      return _buildTripLogHistory(context, _tripChatter!);
    }

    // Fallback jika tidak ada kondisi yang terpenuhi
    return const SizedBox.shrink();
  }

  // --- WIDGET LOG HISTORY DIPERBARUI UNTUK MENERIMA DATA SEBAGAI PARAMETER ---
  Widget _buildTripLogHistory(BuildContext context, TripChatter tripLog) {
    // Balikkan daftar untuk menampilkan log terbaru di atas
    final reversedChatter = tripLog.chatter.reversed.toList();

    return Container(
      padding: EdgeInsets.all(responsiveFont(20, context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Log History',
            style: TextStyle(
              color: kPrimaryBlue,
              fontSize: responsiveFont(18, context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reversedChatter.length,
            itemBuilder: (context, index) {
              final log = reversedChatter[index];
              final isFirst = index == 0;
              final isLast = index == reversedChatter.length - 1;

              return TimelineTile(
                alignment: TimelineAlign.start,
                isFirst: isFirst,
                isLast: isLast,
                beforeLineStyle: LineStyle(color: kBlueTint, thickness: 2),
                indicatorStyle: IndicatorStyle(
                  width: responsiveFont(24, context),
                  height: responsiveFont(24, context),
                  padding: const EdgeInsets.all(6),
                  indicator: Container(
                    decoration: BoxDecoration(
                      color: kBlueTint,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isFirst ? Icons.history_toggle_off : Icons.circle,
                        size: responsiveFont(12, context),
                        color: kPrimaryBlue,
                      ),
                    ),
                  ),
                ),
                endChild: Padding(
                  padding: EdgeInsets.only(
                    left: responsiveFont(16, context),
                    top: responsiveFont(8, context),
                    bottom: responsiveFont(8, context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.cleanedBody, // Gunakan body yang sudah dibersihkan
                        style: TextStyle(
                          fontSize: responsiveFont(15, context),
                          color: kSlateGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: responsiveFont(6, context)),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: responsiveFont(12, context),
                            color: Colors.grey,
                          ),
                          SizedBox(width: responsiveFont(4, context)),
                          Expanded(
                            child: Text(
                              log.author,
                              style: TextStyle(
                                fontSize: responsiveFont(12, context),
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: responsiveFont(12, context),
                            color: Colors.grey,
                          ),
                          SizedBox(width: responsiveFont(4, context)),
                          Text(
                            log.date,
                            style: TextStyle(
                              fontSize: responsiveFont(12, context),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
