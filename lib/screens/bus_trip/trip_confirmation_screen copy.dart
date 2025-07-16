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
// Author: AI Assistant

class TripConfirmationScreen extends StatefulWidget {
  final BusTrip? trip;

  const TripConfirmationScreen({Key? key, this.trip}) : super(key: key);

  @override
  State<TripConfirmationScreen> createState() => _TripConfirmationScreenState();
}

class _TripConfirmationScreenState extends State<TripConfirmationScreen> {
  BusTrip? selectedTrip;
  int passengerQuantity = 1;
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
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
    });
  }

  Future<void> _submit() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      // Step 1: Call getPlanTrips with trip_date, user_id, route_id
      final planTripResult = await BusTripService().getPlanTrips(
        tripDate: selectedTrip?.tripDate ?? '',
        userId: selectedTrip?.userId.toString() ?? '',
        routeId: selectedTrip?.routeId.toString() ?? '',
      );
      if (planTripResult['status'] != true ||
          planTripResult['data'] == null ||
          planTripResult['data'].isEmpty) {
        setState(() {
          errorMessage =
              planTripResult['message'] ??
              'No plan trip found for confirmation.';
        });
        return;
      }
      final planTripData = planTripResult['data'];
      final searchResultId = planTripData[0]['id'].toString();

      // Step 2: Call checkoutBusTrip with search_result_id and passenger_quantity
      final checkoutResult = await BusTripService().checkoutBusTrip(
        searchResultId: searchResultId,
        passengerQuantity: passengerQuantity,
      );

      if (checkoutResult['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkoutResult['message'] ?? 'Confirmation sukses',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.of(context).pop(true);
          });
        }
      } else {
        setState(() {
          errorMessage = checkoutResult['message'] ?? 'Failed to confirm trip';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkoutResult['message'] ?? 'Failed to confirm trip',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error during confirmation: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error during confirmation: $e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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

  Future<void> _openTripSelectorDialog() async {
    setState(() {
      isFetchingTrips = true;
    });
    final userId = await AuthService().getUserId();
    final startDate = filterStartDate != null
        ? DateFormat('yyyy-MM-dd').format(filterStartDate!)
        : null;
    final endDate = filterEndDate != null
        ? DateFormat('yyyy-MM-dd').format(filterEndDate!)
        : null;
    final result = await BusTripService().getBusTrips(
      userId: userId ?? '',
      startDate: startDate,
      endDate: endDate,
    );
    setState(() {
      isFetchingTrips = false;
    });
    if (result['status'] == true && result['data'] != null) {
      List<BusTrip> trips = (result['data'] as List)
          .map((e) => BusTrip.fromJson(e))
          .toList();
      // Filter bus_state_seq > 0
      trips = trips.where((t) => (t.statusSeq ?? 0) > 0).toList();
      if (searchQuery.isNotEmpty) {
        trips = trips
            .where(
              (t) =>
                  (t.busPlate?.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ??
                      false) ||
                  (t.boardingPointName?.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ??
                      false) ||
                  (t.dropPointName?.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
      }
      setState(() {
        availableTrips = trips;
      });
      await showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return AlertDialog(
                title: const Text('Pilih Bus Trip'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Cari bus, rute, atau plat',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                              onChanged: (val) {
                                setStateDialog(() {
                                  searchQuery = val;
                                  availableTrips = trips
                                      .where(
                                        (t) =>
                                            (t.busPlate?.toLowerCase().contains(
                                                  val.toLowerCase(),
                                                ) ??
                                                false) ||
                                            (t.boardingPointName
                                                    ?.toLowerCase()
                                                    .contains(
                                                      val.toLowerCase(),
                                                    ) ??
                                                false) ||
                                            (t.dropPointName
                                                    ?.toLowerCase()
                                                    .contains(
                                                      val.toLowerCase(),
                                                    ) ??
                                                false),
                                      )
                                      .toList();
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.filter_alt_rounded),
                            onPressed: () async {
                              final pickedStart = await showDatePicker(
                                context: ctx,
                                initialDate: filterStartDate ?? DateTime.now(),
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2100),
                              );
                              if (pickedStart != null) {
                                setStateDialog(() {
                                  filterStartDate = pickedStart;
                                });
                              }
                              final pickedEnd = await showDatePicker(
                                context: ctx,
                                initialDate: filterEndDate ?? DateTime.now(),
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2100),
                              );
                              if (pickedEnd != null) {
                                setStateDialog(() {
                                  filterEndDate = pickedEnd;
                                });
                              }
                              Navigator.of(ctx).pop();
                              _openTripSelectorDialog();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isFetchingTrips)
                        const Center(child: CircularProgressIndicator()),
                      if (!isFetchingTrips && availableTrips.isEmpty)
                        const Text('Tidak ada trip ditemukan.'),
                      if (!isFetchingTrips)
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: availableTrips.length,
                            itemBuilder: (ctx, idx) {
                              final trip = availableTrips[idx];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.directions_bus_rounded,
                                    color: Colors.amber,
                                  ),
                                  title: Text(
                                    '${trip.boardingPointName} → ${trip.dropPointName}',
                                  ),
                                  subtitle: Text(
                                    '${trip.busFleetType} (${trip.busPlate})',
                                  ),
                                  trailing: Text(
                                    DateFormat('dd MMM yyyy').format(
                                      DateTime.parse(trip.tripDate ?? ''),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      selectedTrip = trip;
                                    });
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
                    child: const Text('Tutup'),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      setState(() {
        availableTrips = [];
      });
      showDialog(
        context: context,
        builder: (ctx) => const AlertDialog(
          title: Text('Error'),
          content: Text('Gagal mengambil data trip.'),
        ),
      );
    }
  }

  String _formatTripDate(String? dateStr) {
    try {
      if (dateStr == null || dateStr.isEmpty) return '';
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr ?? '';
    }
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.blueGrey[400]),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF163458),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = selectedTrip;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Passenger', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF163458),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (p == null) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_bus_rounded),
                label: const Text('Pilih Trip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isFetchingTrips ? null : _openTripSelectorDialog,
              ),
              const SizedBox(height: 24),
            ],
            if (p != null) ...[
              // Detail Inquiry Section
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6EDF6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.route,
                            color: Color(0xFF163458),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${p.boardingPointName} → ${p.dropPointName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF163458),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: _formatTripDate(p.tripDate),
                      iconColor: Colors.amber,
                      valueColor: Colors.amber[800],
                    ),
                    _infoRow(
                      icon: Icons.directions_bus,
                      label: 'Bus',
                      value: '${p.busFleetType} (${p.busPlate})',
                      iconColor: Colors.blue,
                    ),
                    _infoRow(
                      icon: Icons.directions,
                      label: 'Bus Type',
                      value: p.busFleetType,
                      iconColor: Colors.blueGrey,
                    ),
                    _infoRow(
                      icon: Icons.person,
                      label: 'Driver',
                      value: p.userIdName,
                      iconColor: Colors.green,
                    ),
                    _infoRow(
                      icon: Icons.event_seat,
                      label: 'Total Seats',
                      value: p.totalSeat.toString(),
                      iconColor: Colors.deepPurple,
                    ),
                    _infoRow(
                      icon: Icons.chair_alt,
                      label: 'Passengers',
                      value: p.seatBooked.toString(),
                      iconColor: Colors.orange,
                    ),
                    _infoRow(
                      icon: Icons.chair,
                      label: 'Available',
                      value: p.remainingSeats.toString(),
                      iconColor: Colors.teal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Passenger Quantity Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Number of Passengers',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF163458),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.redAccent,
                            size: 32,
                          ),
                          onPressed: passengerQuantity > 1
                              ? () => _updatePassengerQuantity(
                                  passengerQuantity - 1,
                                )
                              : null,
                        ),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null && parsed > 0) {
                                _updatePassengerQuantity(parsed);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.green,
                            size: 32,
                          ),
                          onPressed: () =>
                              _updatePassengerQuantity(passengerQuantity + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    elevation: 6,
                    shadowColor: Colors.amberAccent.withOpacity(0.3),
                  ),
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 18),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (successMessage != null) ...[
                const SizedBox(height: 18),
                Text(
                  successMessage!,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF3F6FA),
    );
  }
}
