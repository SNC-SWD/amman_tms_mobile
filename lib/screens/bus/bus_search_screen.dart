// lib/features/passenger/screens/bus_search_screen.dart

import 'package:amman_tms_mobile/screens/bus/trip_detail_screen.dart';
import 'package:amman_tms_mobile/widgets/timeline_route_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:amman_tms_mobile/models/bus_point.dart';
import 'package:amman_tms_mobile/models/searched_bus.dart';
import 'package:amman_tms_mobile/core/services/bus_point_service.dart';
import 'package:amman_tms_mobile/core/services/fleet_service.dart';

class BusSearchScreen extends StatefulWidget {
  const BusSearchScreen({super.key});

  @override
  State<BusSearchScreen> createState() => _BusSearchScreenState();
}

class _BusSearchScreenState extends State<BusSearchScreen> {
  final BusPointService _busPointService = BusPointService();
  final FleetService _fleetService = FleetService();

  // State
  DateTime _selectedDate = DateTime.now();
  BusPoint? _fromLocation;
  BusPoint? _toLocation;
  List<BusPoint> _busPoints = [];
  List<SearchedBus> _searchResults = [];

  // UI State
  bool _isLoadingBusPoints = true;
  bool _isSearching = false;
  String? _errorMessage;
  String? _searchMessage;

  @override
  void initState() {
    super.initState();
    _fetchBusPoints();
  }

  Future<void> _fetchBusPoints() async {
    setState(() {
      _isLoadingBusPoints = true;
      _errorMessage = null;
    });
    try {
      final response = await _busPointService.getBusPoints();
      if (response['status'] == true && response['data'] != null) {
        List<dynamic> data = response['data'];
        setState(() {
          _busPoints = data.map((item) => BusPoint.fromJson(item)).toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load bus points');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingBusPoints = false;
      });
    }
  }

  Future<void> _performSearch() async {
    // Validasi input
    if (_fromLocation == null || _toLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select origin and destination.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    if (_fromLocation == _toLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Origin and destination cannot be the same.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _searchMessage = null;
      _searchResults.clear();
    });

    try {
      final response = await _fleetService.searchBuses(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        fromLocationId: _fromLocation!.id,
        toLocationId: _toLocation!.id,
      );

      if (response['status'] == true && response['data'] != null) {
        List<dynamic> data = response['data'];
        if (data.isEmpty) {
          setState(() {
            _searchMessage = 'No buses found for the selected route and date.';
          });
        } else {
          setState(() {
            _searchResults = data
                .map((item) => SearchedBus.fromJson(item))
                .toList();
          });
        }
      } else {
        setState(() {
          _searchMessage =
              response['message'] ?? 'An error occurred during search.';
        });
      }
    } catch (e) {
      setState(() {
        _searchMessage = 'Network Error: Failed to connect to the server.';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _swapLocations() {
    if (_fromLocation != null || _toLocation != null) {
      setState(() {
        final temp = _fromLocation;
        _fromLocation = _toLocation;
        _toLocation = temp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Find Your Bus',
          style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: _isLoadingBusPoints
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState(_errorMessage!, _fetchBusPoints)
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSearchForm(),
                const SizedBox(height: 24),
                _buildSearchResults(),
              ],
            ),
    );
  }

  Widget _buildSearchForm() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildLocationSelectors(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.search, size: 18),
              label: Text(
                'Search',
                style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
              ),
              onPressed: _isSearching ? null : _performSearch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Departure Date',
          labelStyle: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        child: Text(
          DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelectors() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildDropdown(
                hint: 'From',
                value: _fromLocation,
                onChanged: (newValue) =>
                    setState(() => _fromLocation = newValue),
                items: _busPoints,
                icon: Icons.my_location,
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                hint: 'To',
                value: _toLocation,
                onChanged: (newValue) => setState(() => _toLocation = newValue),
                items: _busPoints,
                icon: Icons.location_on,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(
            Icons.swap_vert_circle_rounded,
            color: kAccentGold,
            size: 32,
          ),
          onPressed: _swapLocations,
          tooltip: 'Swap Locations',
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String hint,
    required IconData icon,
    required BusPoint? value,
    required void Function(BusPoint?) onChanged,
    required List<BusPoint> items,
  }) {
    return DropdownButtonFormField<BusPoint>(
      value: value,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      items: items.map<DropdownMenuItem<BusPoint>>((BusPoint point) {
        return DropdownMenuItem<BusPoint>(
          value: point,
          child: Text(
            point.name,
            style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      hint: Text(
        'Select $hint',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchMessage != null) {
      return _buildInfoState(_searchMessage!);
    }

    if (_searchResults.isEmpty) {
      return _buildInfoState('Start by searching for a bus trip. 🚌');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final bus = _searchResults[index];
        return _buildBusResultCard(bus);
      },
    );
  }

  // =================================================================
  // KARTU HASIL PENCARIAN (UPDATED)
  // =================================================================
  Widget _buildBusResultCard(SearchedBus bus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        // Bungkus dengan InkWell agar seluruh kartu bisa di-tap
        onTap: () {
          // Aksi navigasi ke halaman detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetailScreen(trip: bus),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas: Nama Bus dan Rute
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      bus.busName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    bus.routeName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Baris Tengah: Waktu, Durasi, dan Lokasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTimeLocationInfo(
                    time: bus.overallStartTime,
                    location: bus.startLocation,
                  ),
                  _buildDurationInfo(bus.overallDuration),
                  _buildTimeLocationInfo(
                    time: bus.overallEndTime,
                    location: bus.endLocation,
                    alignRight: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Baris Bawah: Info kursi dan tombol
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${bus.remainingSeats}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        TextSpan(
                          text: ' seats left',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeLocationInfo({
    required String time,
    required String location,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 100, // Memberi batas lebar agar teks tidak terlalu panjang
          child: Text(
            location,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(String time, String location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          location,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildDurationInfo(String duration) {
    return Column(
      children: [
        Icon(Icons.timeline, color: Colors.grey.shade400, size: 20),
        Text(
          duration,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Try Again',
                style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
              ),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
