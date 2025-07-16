import 'package:amman_tms_mobile/core/services/auth_service.dart';
import 'package:amman_tms_mobile/core/services/bus_trip_service.dart';
import 'package:amman_tms_mobile/models/bus_trip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// TripConfirmationScreen
// Halaman konfirmasi trip: menampilkan detail inquiry perjalanan, section jumlah penumpang (+, -, input manual), dan tombol submit untuk checkout trip.
// trip: data trip dari card Trip to Confirm
// Desain modern, trendy, dan eye catching.
//
// Author: AI Assistant (Revamped by Gemini, using local fonts)

class TripConfirmationScreen extends StatefulWidget {
  final BusTrip? trip;

  const TripConfirmationScreen({super.key, this.trip});

  @override
  State<TripConfirmationScreen> createState() => _TripConfirmationScreenState();
}

class _TripConfirmationScreenState extends State<TripConfirmationScreen> {
  BusTrip? selectedTrip;
  int passengerQuantity = 1;
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController _controller = TextEditingController(text: '1');
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  String searchQuery = '';
  List<BusTrip> availableTrips = [];
  bool isFetchingTrips = false;

  @override
  void initState() {
    super.initState();
    if (widget.trip != null) {
      selectedTrip = widget.trip;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updatePassengerQuantity(int value) {
    setState(() {
      passengerQuantity = value < 1 ? 1 : value;
      _controller.text = passengerQuantity.toString();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  Future<void> _submit() async {
    if (isLoading || selectedTrip == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final planTripResult = await BusTripService().getPlanTrips(
        tripDate: selectedTrip!.tripDate ?? '',
        userId: selectedTrip!.userId.toString(),
        routeId: selectedTrip!.routeId.toString(),
      );

      if (planTripResult['status'] != true ||
          planTripResult['data'] == null ||
          planTripResult['data'].isEmpty) {
        throw planTripResult['message'] ??
            'No plan trip found for confirmation.';
      }

      final searchResultId = planTripResult['data'][0]['id'].toString();

      final checkoutResult = await BusTripService().checkoutBusTrip(
        searchResultId: searchResultId,
        passengerQuantity: passengerQuantity,
      );

      if (checkoutResult['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildStatusSnackBar(
              message: checkoutResult['message'] ?? 'Confirmation success',
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF00A99D),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      } else {
        throw checkoutResult['message'] ?? 'Failed to confirm trip';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          _buildStatusSnackBar(
            message: errorMessage!,
            icon: Icons.error_outline_rounded,
            color: const Color(0xFFD9534F),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  SnackBar _buildStatusSnackBar({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    );
  }

  Future<void> _openTripSelectorDialog() async {
    setState(() {
      isFetchingTrips = true;
    });

    try {
      final userId = await AuthService().getUserId();
      final result = await BusTripService().getBusTrips(
        userId: userId ?? '',
        startDate: filterStartDate != null
            ? DateFormat('yyyy-MM-dd').format(filterStartDate!)
            : null,
        endDate: filterEndDate != null
            ? DateFormat('yyyy-MM-dd').format(filterEndDate!)
            : null,
      );

      if (result['status'] == true && result['data'] != null) {
        List<BusTrip> fetchedTrips = (result['data'] as List)
            .map((e) => BusTrip.fromJson(e))
            .where((t) => (t.statusSeq ?? 0) > 0)
            .toList();

        setState(() {
          availableTrips = fetchedTrips;
          isFetchingTrips = false;
        });

        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => _buildTripSelectorDialog(ctx, fetchedTrips),
          );
        }
      } else {
        throw 'Failed to get trip data.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildStatusSnackBar(
            message: e.toString(),
            icon: Icons.error_outline_rounded,
            color: const Color(0xFFD9534F),
          ),
        );
        setState(() {
          isFetchingTrips = false;
        });
      }
    }
  }

  Widget _buildTripSelectorDialog(
    BuildContext context,
    List<BusTrip> initialTrips,
  ) {
    return StatefulBuilder(
      builder: (ctx, setStateDialog) {
        final filteredTrips = initialTrips.where((t) {
          final query = searchQuery.toLowerCase();
          return (t.busPlate?.toLowerCase().contains(query) ?? false) ||
              (t.boardingPointName?.toLowerCase().contains(query) ?? false) ||
              (t.dropPointName?.toLowerCase().contains(query) ?? false);
        }).toList();

        return AlertDialog(
          backgroundColor: const Color(0xFFF8F9FD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Select a Trip',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2A4A),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by bus, route, or plate',
                    hintStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF1A2A4A),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (val) => setStateDialog(() => searchQuery = val),
                ),
                const SizedBox(height: 16),
                if (isFetchingTrips)
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A99D)),
                  )
                else if (filteredTrips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No trips found.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredTrips.length,
                      itemBuilder: (ctx, idx) {
                        final trip = filteredTrips[idx];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFF00A99D,
                              ).withOpacity(0.1),
                              child: const Icon(
                                Icons.directions_bus_filled_rounded,
                                color: Color(0xFF00A99D),
                              ),
                            ),
                            title: Text(
                              '${trip.boardingPointName} → ${trip.dropPointName}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${trip.busFleetType} (${trip.busPlate}) - ${_formatTripDate(trip.tripDate)}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            onTap: () {
                              setState(() => selectedTrip = trip);
                              Navigator.of(ctx).pop();
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2A4A),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTripDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2A4A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        title: const Text(
          'Confirm Your Trip',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFF3F6FA),
        foregroundColor: const Color(0xFF1A2A4A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            if (selectedTrip == null)
              ..._buildTripSelector()
            else
              ..._buildTripDetails(selectedTrip!),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  List<Widget> _buildTripSelector() {
    return [
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'No Trip Selected',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a trip to continue.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.directions_bus_rounded, size: 18),
              label: const Text(
                'Select a Trip',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A99D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
                shadowColor: const Color(0xFF00A99D).withOpacity(0.4),
              ),
              onPressed: isFetchingTrips ? null : _openTripSelectorDialog,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildTripDetails(BusTrip p) {
    return [
      // Trip Details Card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _openTripSelectorDialog,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF1A2A4A).withOpacity(0.1),
                    child: const Icon(
                      Icons.route_rounded,
                      color: Color(0xFF1A2A4A),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p.boardingPointName}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A2A4A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '→ ${p.dropPointName}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A2A4A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_note_rounded, color: Color(0xFF00A99D)),
                ],
              ),
            ),
            const Divider(height: 30, thickness: 1, color: Color(0xFFF3F6FA)),
            _infoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: _formatTripDate(p.tripDate),
              color: const Color(0xFF00A99D),
            ),
            _infoRow(
              icon: Icons.directions_bus_rounded,
              label: 'Bus',
              value: '${p.busFleetType} (${p.busPlate})',
              color: const Color(0xFF4A90E2),
            ),
            _infoRow(
              icon: Icons.person_rounded,
              label: 'Driver',
              value: p.userIdName ?? 'N/A',
              color: const Color(0xFF50E3C2),
            ),
            _infoRow(
              icon: Icons.chair_rounded,
              label: 'Available Seats',
              value: p.remainingSeats.toString(),
              color: const Color(0xFFFFAB76),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      // Passenger Quantity Section
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Passengers',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1A2A4A),
              ),
            ),
            Row(
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onPressed: passengerQuantity > 1
                      ? () => _updatePassengerQuantity(passengerQuantity - 1)
                      : null,
                ),
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed >= 1) {
                        _updatePassengerQuantity(parsed);
                      }
                    },
                  ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  onPressed: () =>
                      _updatePassengerQuantity(passengerQuantity + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF1A2A4A)),
        onPressed: onPressed,
        disabledColor: Colors.grey[300],
        splashRadius: 20,
      ),
    );
  }

  Widget _buildBottomBar() {
    if (selectedTrip == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: const Color(0xFF1A2A4A),
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0xFF1A2A4A).withOpacity(0.4),
          ),
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Text(
                  'Confirm',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
