import 'dart:ui';
import 'package:amman_tms_mobile/screens/bus_trip/add_bus_trip_screen.dart';
import 'dart:async'; // Import for Timer
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import 'package:amman_tms_mobile/core/api/api_config.dart';
import 'package:amman_tms_mobile/core/services/auth_service.dart';
import 'package:amman_tms_mobile/core/services/traccar_service.dart'; // Import TraccarService
import 'package:amman_tms_mobile/models/bus_info.dart';
import 'package:amman_tms_mobile/models/bus_status.dart';
import 'package:amman_tms_mobile/widgets/bus_list_item_widget.dart';
import 'package:amman_tms_mobile/widgets/detail_item_widget.dart';
import 'package:amman_tms_mobile/widgets/status_card_widget.dart';

enum MapType { dark, street }

class MultiBusMapScreen extends StatefulWidget {
  const MultiBusMapScreen({super.key});

  @override
  State<MultiBusMapScreen> createState() => _MultiBusMapScreenState();
}

class _MultiBusMapScreenState extends State<MultiBusMapScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  // --- DATA SIMULASI ---
  // Dalam aplikasi nyata, data ini akan diambil dari API secara terpisah.
  // --- END OF DATA SIMULASI --- // Remove hardcoded JSON

  // Pagination variables
  int _currentPage = 1;
  final int _perPage = 10;
  bool _isLoading = false;
  bool _hasMore = true;

  late List<BusInfo> allBuses = [];
  late List<BusStatus> allBusStatus = [];
  BusInfo? selectedBus;
  BusStatus? liveBusStatus; // To store live position data
  Timer? _liveTrackingTimer; // Timer for live tracking

  late final MapController _mapController;
  late final AnimationController _animationController;
  MapType _currentMapType = MapType.street;

  late final ScrollController _scrollController;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scrollController = ScrollController()..addListener(_onScroll);
    _authService.initializeSession().then((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    await _authService.initializeSession();
    try {
      // Ensure session is valid before making API call
      final reAuthSuccess = await _reAuthenticate();
      if (!reAuthSuccess) {
        print(
          '❌ [MultiBusMapScreen] Re-authentication failed, cannot proceed with request',
        );
        return;
      }
      // Session ID should now be available via _authService.sessionId if _reAuthenticate was successful

      final Uri uri = Uri.parse(
        '${ApiConfig.baseUrl}/traccar/device?page=$_currentPage&per_page=$_perPage&pagination=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$_sessionId', // Use JSESSIONID for Traccar
        },
      );

      if (response.statusCode == 200) {
        print('API Response Status: ${response.statusCode}');
        print('API Response Body: ${response.body}');
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final busListResponse = busListResponseFromJson(
          jsonEncode(responseBody),
        );
        final newBuses = busListResponse.data;

        // For bus status, we'll need a separate endpoint or integrate it
        // For now, let's assume bus status comes with bus info or is fetched separately
        // This part needs to be adapted based on actual Traccar API for status
        // For simulation, we'll create dummy status for new buses
        final newBusStatus = newBuses
            .map(
              (bus) => BusStatus(
                deviceId: int.parse(bus.deviceId),
                attributes: Attributes(
                  ignition: true,
                  motion: true,
                  power: 12.0,
                  odometer: 0,
                ),
                latitude: bus.lastLatitude,
                longitude: bus.lastLongitude,
                speed: 0.0,
                course: 0,
                deviceTime: DateTime.now(),
                address: 'Unknown Address',
              ),
            )
            .toList();

        setState(() {
          allBuses.addAll(newBuses);
          allBusStatus.addAll(newBusStatus); // Add new statuses
          _currentPage++;
          _hasMore =
              newBuses.length == _perPage; // Check if there are more pages
        });
      } else if (response.statusCode == 404) {
        // Unauthorized, try to re-authenticate and retry
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          await _loadData(); // Retry loading data after re-authentication
        } else {
          print('Authentication failed. Please login again.');
        }
      } else {
        print(
          'Failed to load bus data: ${response.statusCode}. Response body: ${response.body}',
        );
      }
    } catch (e) {
      print('Error loading bus data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _reAuthenticate() async {
    try {
      final Uri authUri = Uri.parse(ApiConfig.connectionEndpoint);
      final response = await http.post(
        authUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "params": {
            "db": "odoo17_copy_experiment",
            "login": _authService.username,
            "password": _authService.password,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Auth API Response Status: ${response.statusCode}');
        print('Auth API Response Body: ${response.body}');
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          final newSessionId = RegExp(
            r'session_id=([^;]+)',
          ).firstMatch(cookies)?.group(1);
          if (newSessionId != null) {
            _sessionId = newSessionId;
            print(
              'Re-authentication successful, new sessionId obtained: $_sessionId',
            );
            return true;
          }
        }
      }
      print(
        'Re-authentication failed: Status ${response.statusCode}. Response body: ${response.body}',
      );
      return false;
    } catch (e) {
      print('Re-authentication error: $e');
      return false;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _loadData();
    }
  }

  void _startLiveTracking(int deviceId) {
    _liveTrackingTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      final positions = await TraccarService.fetchBusPositions(deviceId);
      if (positions.isNotEmpty) {
        final latestPosition = positions.first;
        setState(() {
          liveBusStatus = BusStatus(
            deviceId: latestPosition['deviceId'],
            attributes: Attributes(
              ignition: latestPosition['attributes']['ignition'] ?? false,
              motion: latestPosition['attributes']['motion'] ?? false,
              power:
                  (latestPosition['attributes']['power'] as num?)?.toDouble() ??
                  0.0,
              odometer:
                  (latestPosition['attributes']['odometer'] as num?)?.toInt() ??
                  0,
            ),
            latitude: (latestPosition['latitude'] as num).toDouble(),
            longitude: (latestPosition['longitude'] as num).toDouble(),
            speed: (latestPosition['speed'] as num).toDouble(),
            course: (latestPosition['course'] as num).toDouble(),
            deviceTime: DateTime.parse(latestPosition['deviceTime']),
            address: latestPosition['address'],
          );
          _mapController.move(
            LatLng(liveBusStatus!.latitude, liveBusStatus!.longitude),
            _mapController.zoom,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _liveTrackingTimer?.cancel(); // Cancel timer when screen is disposed
    _mapController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleMapType() => setState(
    () => _currentMapType = _currentMapType == MapType.dark
        ? MapType.street
        : MapType.dark,
  );

  void _onBusSelected(BusInfo bus) {
    setState(() {
      selectedBus = bus;
      _liveTrackingTimer?.cancel(); // Cancel any existing timer
      liveBusStatus = null; // Clear previous live status

      // Find the corresponding BusStatus for the selected bus
      final status = allBusStatus.firstWhere(
        (s) => s.deviceId.toString() == bus.deviceId,
        orElse: () => BusStatus(
          deviceId: int.parse(bus.deviceId),
          attributes: Attributes(
            ignition: false,
            motion: false,
            power: 0.0,
            odometer: 0,
          ),
          latitude: bus.lastLatitude,
          longitude: bus.lastLongitude,
          speed: 0.0,
          course: 0,
          deviceTime: DateTime.now(),
          address: 'Unknown Address',
        ),
      );
      liveBusStatus = status; // Set initial live status

      // Move map to selected bus location
      _mapController.move(
        LatLng(liveBusStatus!.latitude, liveBusStatus!.longitude),
        15.0,
      );

      // Start live tracking
      _startLiveTracking(int.parse(bus.deviceId));
    });
  }

  void _clearSelection() {
    _liveTrackingTimer?.cancel(); // Cancel live tracking timer
    setState(() => selectedBus = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          selectedBus == null ? 'Semua Armada Bus' : selectedBus!.vehicle.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kPrimaryBlue,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: selectedBus != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: _clearSelection,
              )
            : null,
      ),
      body: Stack(children: [_buildMap(), _buildDraggablePanel()]),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildMap() {
    final mapUrls = {
      MapType.dark:
          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      MapType.street: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    };

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(-9.012, 116.808), // Lokasi awal tengah
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(urlTemplate: mapUrls[_currentMapType]!),
        MarkerLayer(
          markers: allBuses.map((bus) {
            final status = allBusStatus.firstWhere(
              (s) => s.deviceId.toString() == bus.deviceId,
              orElse: () => BusStatus.empty(),
            );
            return Marker(
              point: LatLng(
                bus.deviceId == selectedBus?.deviceId && liveBusStatus != null
                    ? liveBusStatus!.latitude
                    : bus.lastLatitude,
                bus.deviceId == selectedBus?.deviceId && liveBusStatus != null
                    ? liveBusStatus!.longitude
                    : bus.lastLongitude,
              ),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => _onBusSelected(bus),
                child: _buildBusMarker(
                  bus.deviceId == selectedBus?.deviceId && liveBusStatus != null
                      ? liveBusStatus!
                      : status,
                  bus.deviceId == selectedBus?.deviceId,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBusMarker(BusStatus status, bool isSelected) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final rippleSize =
            (status.attributes.motion ? _animationController.value : 0) * 50;
        final rippleOpacity = 1 - _animationController.value;

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (status.attributes.motion)
                Container(
                  width: rippleSize.toDouble(),
                  height: rippleSize.toDouble(),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).primaryColor.withOpacity(rippleOpacity * 0.5),
                  ),
                ),
              Transform.rotate(
                angle: (status.course * (3.14159 / 180)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.busSimple,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggablePanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: selectedBus == null
                    ? _buildBusListView(scrollController)
                    : _buildDetailView(scrollController, selectedBus!),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusListView(ScrollController controller) {
    return Column(
      key: const ValueKey('busList'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          child: Text(
            "Daftar Armada",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: controller,
            itemCount:
                allBuses.length +
                (_hasMore ? 1 : 0), // Add 1 for loading indicator
            itemBuilder: (context, index) {
              if (index == allBuses.length) {
                if (_isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  return const SizedBox.shrink(); // No more data and not loading
                }
              }

              final bus = allBuses[index];
              final status = allBusStatus.firstWhere(
                (s) => s.deviceId.toString() == bus.deviceId,
                orElse: () => BusStatus.empty(),
              );
              return BusListItemWidget(
                busInfo: bus,
                busStatus: status,
                onTap: () => _onBusSelected(bus),
              ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(ScrollController controller, BusInfo bus) {
    final displayStatus =
        selectedBus?.deviceId == bus.deviceId && liveBusStatus != null
        ? liveBusStatus!
        : allBusStatus.firstWhere(
            (s) => s.deviceId.toString() == bus.deviceId,
            orElse: () => BusStatus.empty(),
          );
    String statusText = bus.vehicle.state.name;
    Color statusColor;
    switch (statusText) {
      case 'Trip Confirmed':
        statusColor = Theme.of(context).primaryColor;
        break;
      case 'Ready':
        statusColor = Colors.green;
        break;
      case 'On Trip':
        statusColor = Colors.blue;
        break;
      case 'Maintenance':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return ListView(
      key: ValueKey('detailView_${bus.id}'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: _clearSelection,
          ),
        ),
        const SizedBox(height: 12),
        // Primary Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Status Langsung',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor, width: 1.5),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            StatusCardWidget(
              icon: FontAwesomeIcons.gaugeSimpleHigh,
              value: displayStatus.speedInKmh.toStringAsFixed(0),
              unit: 'km/h',
              label: 'Kecepatan',
            ),
            StatusCardWidget(
              icon: FontAwesomeIcons.key,
              value: displayStatus.attributes.ignition ? 'ON' : 'OFF',
              label: 'Mesin',
              color: displayStatus.attributes.ignition
                  ? Theme.of(context).primaryColor
                  : Colors.redAccent,
            ),
            StatusCardWidget(
              icon: displayStatus.attributes.motion
                  ? FontAwesomeIcons.route
                  : FontAwesomeIcons.squareParking,
              value: displayStatus.attributes.motion ? 'YA' : 'TIDAK',
              label: 'Gerak',
              color: displayStatus.attributes.motion
                  ? Theme.of(context).primaryColor
                  : Colors.grey[400],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 16),
        // Secondary Info
        DetailItemWidget(
          icon: FontAwesomeIcons.gaugeHigh,
          title: 'Odometer',
          value:
              '${NumberFormat('#,##0').format(displayStatus.attributes.odometer / 1000)} km',
        ),
        DetailItemWidget(
          icon: FontAwesomeIcons.carBattery,
          title: 'Sumber Daya',
          value: '${displayStatus.attributes.power.toStringAsFixed(1)} V',
        ),
        DetailItemWidget(
          icon: FontAwesomeIcons.clock,
          title: 'Pembaruan Terakhir',
          value: DateFormat(
            'd MMM yyyy, HH:mm:ss',
            'id_ID',
          ).format(displayStatus.deviceTime.toLocal()),
        ),
        DetailItemWidget(
          icon: FontAwesomeIcons.mapPin,
          title: 'Alamat Terakhir',
          value: displayStatus.address ?? 'Data alamat tidak tersedia',
          isAddress: true,
        ),
      ].animate(interval: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.5),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () {
            if (selectedBus != null) {
              _onBusSelected(selectedBus!);
            }
          },
          heroTag: 'centerMap',
          mini: true,
          child: const FaIcon(FontAwesomeIcons.locationCrosshairs, size: 18),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          onPressed: _toggleMapType,
          heroTag: 'toggleMap',
          mini: true,
          child: FaIcon(
            _currentMapType == MapType.dark
                ? FontAwesomeIcons.solidSun
                : FontAwesomeIcons.solidMoon,
            size: 18,
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.15,
        ), // Adjust space based on screen
      ],
    );
  }
}
