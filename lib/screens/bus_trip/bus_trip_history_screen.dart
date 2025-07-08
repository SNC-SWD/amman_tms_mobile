import 'package:flutter/material.dart';
import 'package:amman_tms_mobile/core/services/bus_trip_service.dart';
import 'package:amman_tms_mobile/models/bus_trip.dart';
import 'bus_trip_detail_screen.dart';
import 'package:intl/intl.dart';

const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);
const kSlateGray = Color(0xFF4C5C74);
const kSoftGold = Color(0xFFE0B352);
const kBlueTint = Color(0xFFE6EDF6);

class BusTripHistoryScreen extends StatefulWidget {
  final String? initialStartDate;
  final String? initialEndDate;
  const BusTripHistoryScreen({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<BusTripHistoryScreen> createState() => _BusTripHistoryScreenState();
}

class _BusTripHistoryScreenState extends State<BusTripHistoryScreen> {
  final BusTripService _busTripService = BusTripService();
  List<BusTrip> _busTrips = [];
  List<BusTrip> _filteredTrips = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedBus;
  int? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _busList = [];

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
  void initState() {
    super.initState();
    if (widget.initialStartDate != null) {
      _startDate = DateTime.tryParse(widget.initialStartDate!);
    }
    if (widget.initialEndDate != null) {
      _endDate = DateTime.tryParse(widget.initialEndDate!);
    }
    _loadBusTrips(
      startDate: _startDate != null
          ? _startDate!.toIso8601String().substring(0, 10)
          : null,
      endDate: _endDate != null
          ? _endDate!.toIso8601String().substring(0, 10)
          : null,
      statusSeq: _selectedStatus,
    );
  }

  Future<void> _loadBusTrips({
    String? busId,
    String? startDate,
    String? endDate,
    int? statusSeq,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _busTripService.getBusTrips(
        busId: busId,
        startDate: startDate,
        endDate: endDate,
        busStatusSeq: statusSeq?.toString(),
      );
      if (result['status'] == true) {
        final List<dynamic> tripsData = result['data'];
        final trips = tripsData.map((trip) => BusTrip.fromJson(trip)).toList();
        setState(() {
          _busTrips = trips;
          _filteredTrips = trips;
          _busList = trips.map((e) => e.busInfo).toSet().toList();
        });
        _applySearch(_searchQuery);
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load bus trips: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      _filteredTrips = _busTrips.where((trip) {
        final q = query.toLowerCase();
        return trip.routeName.toLowerCase().contains(q) ||
            trip.userIdName.toLowerCase().contains(q) ||
            trip.busInfo.toLowerCase().contains(q);
      }).toList();
    });
  }

  void _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String? tempBus = _selectedBus;
        int? tempStatus = _selectedStatus;
        DateTime? tempStart = _startDate;
        DateTime? tempEnd = _endDate;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: tempBus ?? '',
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All Bus'),
                      ),
                      ..._busList
                          .map(
                            (bus) => DropdownMenuItem<String>(
                              value: bus,
                              child: Text(bus),
                            ),
                          )
                          .toList(),
                    ],
                    onChanged: (v) => setModalState(() => tempBus = v),
                    decoration: const InputDecoration(
                      labelText: 'Bus',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int?>(
                    value: tempStatus,
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Semua Status'),
                      ),
                      DropdownMenuItem(value: 0, child: Text('Ready')),
                      DropdownMenuItem(value: 1, child: Text('Trip Confirmed')),
                      DropdownMenuItem(value: 2, child: Text('On Trip')),
                      DropdownMenuItem(value: 3, child: Text('End Trip')),
                    ],
                    onChanged: (v) => setModalState(() => tempStatus = v),
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempStart ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setModalState(() => tempStart = picked);
                            }
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Start Date',
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.date_range),
                              ),
                              controller: TextEditingController(
                                text: tempStart != null
                                    ? tempStart!.toIso8601String().substring(
                                        0,
                                        10,
                                      )
                                    : '',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempEnd ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setModalState(() => tempEnd = picked);
                            }
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'End Date',
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.date_range),
                              ),
                              controller: TextEditingController(
                                text: tempEnd != null
                                    ? tempEnd!.toIso8601String().substring(
                                        0,
                                        10,
                                      )
                                    : '',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'bus': tempBus,
                              'status': tempStatus,
                              'start': tempStart,
                              'end': tempEnd,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedBus = result['bus'];
        _selectedStatus = result['status'];
        _startDate = result['start'];
        _endDate = result['end'];
      });
      await _loadBusTrips(
        busId: _selectedBus != null && _selectedBus!.isNotEmpty
            ? _busTrips
                  .firstWhere((e) => e.busInfo == _selectedBus)
                  .busId
                  .toString()
            : null,
        startDate: _startDate != null
            ? _startDate!.toIso8601String().substring(0, 10)
            : null,
        endDate: _endDate != null
            ? _endDate!.toIso8601String().substring(0, 10)
            : null,
        statusSeq: _selectedStatus,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = responsivePadding(context);

    return Scaffold(
      backgroundColor: kLightGray,
      appBar: AppBar(
        title: Text(
          'Bus Trip History',
          style: TextStyle(
            color: kPrimaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: responsiveFont(18, context),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryBlue),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              horizontalPadding,
              horizontalPadding,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by route, driver, or bus',
                      hintStyle: TextStyle(
                        fontSize: responsiveFont(14, context),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: responsiveFont(20, context),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: responsiveFont(14, context),
                        horizontal: responsiveFont(16, context),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(fontSize: responsiveFont(14, context)),
                    onChanged: _applySearch,
                  ),
                ),
                SizedBox(width: responsiveFont(14, context)),
                Material(
                  color: kAccentGold,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _openFilterSheet,
                    child: Padding(
                      padding: EdgeInsets.all(responsiveFont(14, context)),
                      child: Icon(
                        Icons.filter_alt_rounded,
                        color: Colors.white,
                        size: responsiveFont(24, context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: responsiveFont(8, context)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: kSlateGray),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBusTrips,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentGold,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadBusTrips,
                    child: _filteredTrips.isEmpty
                        ? const Center(
                            child: Text(
                              'No bus trips found',
                              style: TextStyle(color: kSlateGray),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(horizontalPadding),
                            itemCount: _filteredTrips.length,
                            itemBuilder: (context, index) {
                              final trip = _filteredTrips[index];
                              final isLast = index == _filteredTrips.length - 1;
                              return Column(
                                children: [
                                  _buildModernTripCard(trip),
                                  if (!isLast)
                                    SizedBox(
                                      height: responsiveFont(14, context),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTripCard(BusTrip trip) {
    String _formatDate(String? dateStr) {
      try {
        if (dateStr == null) return '';
        final date = DateTime.parse(dateStr);
        return DateFormat('dd MMM yyyy').format(date);
      } catch (_) {
        return dateStr ?? '';
      }
    }

    String _formatTime(double time) {
      final hour = time.floor();
      final minute = ((time - hour) * 60).round();
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    // Status logic - following the same logic as home screen
    int statusSeq = trip.statusSeq ?? 0;
    String badgeLabel = 'Ready';
    Color badgeColor = Colors.grey;
    switch (statusSeq) {
      case 0:
        badgeLabel = 'Ready';
        badgeColor = Colors.grey;
        break;
      case 1:
        badgeLabel = 'Trip Confirmed';
        badgeColor = Colors.blue;
        break;
      case 2:
        badgeLabel = 'On Trip';
        badgeColor = Colors.green;
        break;
      case 3:
        badgeLabel = 'End Trip';
        badgeColor = Colors.red;
        break;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth < 360 ? 12.0 : 18.0;
    final iconPadding = screenWidth < 360 ? 6.0 : 8.0;
    final iconSize = screenWidth < 360 ? 16.0 : 18.0;
    final maxCardWidth = 500.0;

    return Center(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxCardWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kBlueTint.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: kAccentGold.withOpacity(0.18),
              width: 1.2,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusTripDetailScreen(trip: trip),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: kAccentGold.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(iconPadding),
                              child: Icon(
                                Icons.directions_bus_rounded,
                                color: kAccentGold,
                                size: iconSize,
                              ),
                            ),
                            SizedBox(width: responsiveFont(8, context)),
                            Flexible(
                              child: Text(
                                _formatDate(trip.tripDate),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsiveFont(14, context),
                                  color: kPrimaryBlue,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsiveFont(8, context)),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${trip.boardingPointName ?? ''} ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsiveFont(14, context),
                                  color: kAccentGold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: kPrimaryBlue,
                              size: responsiveFont(14, context),
                            ),
                            Flexible(
                              child: Text(
                                ' ${trip.dropPointName ?? ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsiveFont(14, context),
                                  color: kPrimaryBlue,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsiveFont(6, context)),
                        Row(
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.green,
                              size: responsiveFont(14, context),
                            ),
                            SizedBox(width: responsiveFont(4, context)),
                            Text(
                              _formatTime(trip.startTime),
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: responsiveFont(13, context),
                              ),
                            ),
                            SizedBox(width: responsiveFont(14, context)),
                            Icon(
                              Icons.flag_rounded,
                              color: Colors.red,
                              size: responsiveFont(14, context),
                            ),
                            SizedBox(width: responsiveFont(4, context)),
                            Text(
                              _formatTime(trip.endTime),
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: responsiveFont(14, context),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsiveFont(8, context)),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: kSlateGray,
                              size: responsiveFont(14, context),
                            ),
                            SizedBox(width: responsiveFont(6, context)),
                            Flexible(
                              child: Text(
                                trip.userIdName ?? '',
                                style: TextStyle(
                                  color: kSlateGray,
                                  fontSize: responsiveFont(14, context),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // VERTICAL DIVIDER
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: responsiveFont(14, context),
                      vertical: 6,
                    ),
                    width: 1.2,
                    height: 64,
                    color: kBlueTint.withOpacity(0.8),
                  ),
                  // RIGHT COLUMN
                  Expanded(
                    flex: 0,
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Badge status di dalam area card, pojok kanan atas konten
                            Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsiveFont(14, context),
                                  vertical: responsiveFont(7, context),
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: badgeColor.withOpacity(0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    color: badgeLabel == 'Waiting'
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: responsiveFont(12, context),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: responsiveFont(10, context)),
                            // Nama bus
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsiveFont(10, context),
                                vertical: responsiveFont(6, context),
                              ),
                              decoration: BoxDecoration(
                                color: kBlueTint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 100),
                                child: Text(
                                  trip.busInfo ?? '',
                                  style: TextStyle(
                                    color: kPrimaryBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: responsiveFont(12, context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            SizedBox(height: responsiveFont(10, context)),
                            // Penumpang
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsiveFont(10, context),
                                vertical: responsiveFont(6, context),
                              ),
                              decoration: BoxDecoration(
                                color: kBlueTint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.groups_rounded,
                                    color: kSoftGold,
                                    size: responsiveFont(14, context),
                                  ),
                                  SizedBox(width: responsiveFont(4, context)),
                                  Text(
                                    (trip.seatBooked ?? 0).toString(),
                                    style: TextStyle(
                                      color: kPrimaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: responsiveFont(11, context),
                                      letterSpacing: 0.5,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
