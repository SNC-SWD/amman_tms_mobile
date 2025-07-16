// file: lib/screens/multi_bus_map_screen.dart

import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Diperlukan untuk SystemNavigator
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import 'package:amman_tms_mobile/core/api/api_config.dart';
import 'package:amman_tms_mobile/core/services/auth_service.dart';
import 'package:amman_tms_mobile/core/services/traccar_service.dart';
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
  int _currentPage = 1;
  final int _perPage = 10;
  bool _isLoading = false;
  bool _hasMore = true;

  late List<BusInfo> allBuses = [];
  late List<BusStatus> allBusStatus = [];
  BusInfo? selectedBus;
  BusStatus? liveBusStatus;
  Timer? _liveTrackingTimer;

  late final MapController _mapController;
  late final AnimationController _animationController;
  // UBAH: Default map menjadi light (street)
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

  // --- FUNGSI LOGIKA (TIDAK DIUBAH) ---
  Future<void> _loadData() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });
    await _authService.initializeSession();
    try {
      final reAuthSuccess = await _reAuthenticate();
      if (!reAuthSuccess) {
        return;
      }
      final Uri uri = Uri.parse(
        '${ApiConfig.baseUrl}/traccar/device?page=$_currentPage&per_page=$_perPage&pagination=1',
      );
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$_sessionId',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final busListResponse = busListResponseFromJson(
          jsonEncode(responseBody),
        );
        final newBuses = busListResponse.data;
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
          allBusStatus.addAll(newBusStatus);
          _currentPage++;
          _hasMore = newBuses.length == _perPage;
        });
      } else if (response.statusCode == 404) {
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          await _loadData();
        }
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
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          final newSessionId = RegExp(
            r'session_id=([^;]+)',
          ).firstMatch(cookies)?.group(1);
          if (newSessionId != null) {
            _sessionId = newSessionId;
            return true;
          }
        }
      }
      return false;
    } catch (e) {
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
      if (positions.isNotEmpty && mounted) {
        final latestPosition = positions.first;
        setState(() {
          liveBusStatus = BusStatus.fromJson(latestPosition);
          _mapController.move(
            LatLng(liveBusStatus!.latitude, liveBusStatus!.longitude),
            _mapController.zoom,
          );
        });
      }
    });
  }
  // --- END OF FUNGSI LOGIKA ---

  @override
  void dispose() {
    _liveTrackingTimer?.cancel();
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
      _liveTrackingTimer?.cancel();
      liveBusStatus = null;
      final status = allBusStatus.firstWhere(
        (s) => s.deviceId.toString() == bus.deviceId,
        orElse: () => BusStatus(
          deviceId: int.parse(bus.deviceId),
          latitude: bus.lastLatitude,
          longitude: bus.lastLongitude,
          speed: 0.0,
          course: 0.0,
          deviceTime: DateTime.now(),
          attributes: Attributes.empty(),
          address: 'Unknown Address',
        ),
      );
      liveBusStatus = status;
      _mapController.move(
        LatLng(liveBusStatus!.latitude, liveBusStatus!.longitude),
        15.0,
      );
      _startLiveTracking(int.parse(bus.deviceId));
    });
  }

  void _clearSelection() {
    _liveTrackingTimer?.cancel();
    setState(() => selectedBus = null);
  }

  @override
  Widget build(BuildContext context) {
    // UBAH: Mendefinisikan warna berdasarkan tema map
    final bool isDarkMode = _currentMapType == MapType.dark;
    final Color panelColor = isDarkMode
        ? const Color(0xFF1C1C1E)
        : Colors.white;
    final Color primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDarkMode
        ? const Color(0xFF8E8E93)
        : Colors.grey.shade600;
    final Color cardColor = isDarkMode
        ? const Color(0xFF2C2C2E)
        : Colors.grey.shade50;
    const Color accentColor = Color(0xFFE0B352);

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : Colors.grey.shade200,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(primaryTextColor),
      body: Stack(
        children: [
          _buildMap(),
          _buildDraggablePanel(
            panelColor,
            primaryTextColor,
            secondaryTextColor,
            cardColor,
            accentColor,
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(isDarkMode),
    );
  }

  PreferredSizeWidget _buildAppBar(Color textColor) {
    return AppBar(
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: Text(
          selectedBus == null ? 'Pantauan Armada' : selectedBus!.vehicle.name,
          key: ValueKey(selectedBus?.id ?? 'all'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontFamily: 'Poppins',
            fontSize: 18,
          ),
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildMap() {
    final mapUrls = {
      MapType.dark:
          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      MapType.street:
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    };
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(-6.97, 107.76),
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: mapUrls[_currentMapType]!,
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        MarkerLayer(
          markers: allBuses.map((bus) {
            final status = allBusStatus.firstWhere(
              (s) => s.deviceId.toString() == bus.deviceId,
              orElse: () => BusStatus.empty(),
            );
            final isSelected = bus.deviceId == selectedBus?.deviceId;
            final currentStatus = isSelected && liveBusStatus != null
                ? liveBusStatus!
                : status;
            return Marker(
              point: LatLng(currentStatus.latitude, currentStatus.longitude),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => _onBusSelected(bus),
                child: _buildBusMarker(currentStatus, isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBusMarker(BusStatus status, bool isSelected) {
    final bool isDarkMode = _currentMapType == MapType.dark;
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
                    color: const Color(
                      0xFFE0B352,
                    ).withOpacity(rippleOpacity * 0.5),
                  ),
                ),
              Transform.rotate(
                angle: (status.course * (3.14159 / 180)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE0B352)
                        : (isDarkMode ? const Color(0xFF1C1C1E) : Colors.white),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : (isDarkMode ? Colors.white24 : Colors.black26),
                      width: 1.5,
                    ),
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
                        ? (isDarkMode ? Colors.black : Colors.white)
                        : (isDarkMode ? Colors.white : Colors.black87),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggablePanel(
    Color panelColor,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color cardColor,
    Color accentColor,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: panelColor.withOpacity(0.85),
                border: Border(
                  top: BorderSide(
                    color: primaryTextColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: selectedBus == null
                    ? _buildBusListView(
                        scrollController,
                        primaryTextColor,
                        secondaryTextColor,
                        cardColor,
                        accentColor,
                      )
                    : _buildDetailView(
                        scrollController,
                        selectedBus!,
                        primaryTextColor,
                        secondaryTextColor,
                        cardColor,
                        accentColor,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusListView(
    ScrollController controller,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color cardColor,
    Color accentColor,
  ) {
    return Column(
      key: const ValueKey('busList'),
      children: [
        _buildGrabber(primaryTextColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(4.0, 0, 16.0, 16.0),
          child: Row(
            children: [
              // (HAPUS) IconButton close (x) di sini
              Expanded(
                child: Text(
                  "Daftar Armada",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: primaryTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Spacer untuk menyeimbangkan tombol
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: controller,
            padding: EdgeInsets.zero,
            itemCount: allBuses.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == allBuses.length) {
                return _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE0B352),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
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
                // UBAH: Mengirimkan warna dinamis
                cardColor: cardColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                accentColor: accentColor,
              ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(
    ScrollController controller,
    BusInfo bus,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color cardColor,
    Color accentColor,
  ) {
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
        statusColor = accentColor;
        break;
      case 'Ready':
        statusColor = Colors.greenAccent.shade400;
        break;
      case 'On Trip':
        statusColor = Colors.blueAccent;
        break;
      case 'Maintenance':
        statusColor = Colors.redAccent.shade400;
        break;
      default:
        statusColor = secondaryTextColor;
    }
    return ListView(
      key: ValueKey('detailView_${bus.id}'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _buildGrabber(primaryTextColor),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // UBAH: Tombol back ditambahkan di detail view juga untuk konsistensi
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: primaryTextColor,
                size: 20,
              ),
              onPressed: _clearSelection,
            ),
            Expanded(
              child: Text(
                'Detail Armada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: primaryTextColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Poppins',
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
              cardColor: cardColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              accentColor: accentColor,
            ),
            const SizedBox(width: 12),
            StatusCardWidget(
              icon: FontAwesomeIcons.key,
              value: displayStatus.attributes.ignition ? 'ON' : 'OFF',
              label: 'Mesin',
              color: displayStatus.attributes.ignition
                  ? Colors.greenAccent.shade400
                  : Colors.redAccent.shade400,
              cardColor: cardColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              accentColor: accentColor,
            ),
            const SizedBox(width: 12),
            StatusCardWidget(
              icon: displayStatus.attributes.motion
                  ? FontAwesomeIcons.route
                  : FontAwesomeIcons.squareParking,
              value: displayStatus.attributes.motion ? 'JALAN' : 'DIAM',
              label: 'Gerak',
              color: displayStatus.attributes.motion
                  ? Colors.blueAccent
                  : secondaryTextColor,
              cardColor: cardColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              accentColor: accentColor,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(
          color: primaryTextColor.withOpacity(0.1),
          height: 24,
          thickness: 1,
        ),
        DetailItemWidget(
          icon: FontAwesomeIcons.gaugeHigh,
          title: 'Odometer',
          value:
              '${NumberFormat('#,##0').format(displayStatus.attributes.odometer / 1000)} km',
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
        DetailItemWidget(
          icon: FontAwesomeIcons.carBattery,
          title: 'Sumber Daya',
          value: '${displayStatus.attributes.power.toStringAsFixed(1)} V',
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
        DetailItemWidget(
          icon: FontAwesomeIcons.clock,
          title: 'Pembaruan Terakhir',
          value: DateFormat(
            'd MMM yyyy, HH:mm:ss',
            'id_ID',
          ).format(displayStatus.deviceTime.toLocal()),
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
        DetailItemWidget(
          icon: FontAwesomeIcons.mapPin,
          title: 'Alamat Terakhir',
          value: displayStatus.address ?? 'Data alamat tidak tersedia',
          isAddress: true,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ].animate(interval: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.3),
    );
  }

  Widget _buildGrabber(Color textColor) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: textColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(bool isDarkMode) {
    final fabColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final iconColor = isDarkMode ? Colors.white : Colors.black87;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.15,
        right: 4,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              if (selectedBus != null) {
                _mapController.move(
                  LatLng(liveBusStatus!.latitude, liveBusStatus!.longitude),
                  15.0,
                );
              }
            },
            heroTag: 'centerMap',
            backgroundColor: fabColor,
            mini: true,
            child: FaIcon(
              FontAwesomeIcons.locationCrosshairs,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _toggleMapType,
            heroTag: 'toggleMap',
            backgroundColor: fabColor,
            mini: true,
            child: FaIcon(
              isDarkMode ? FontAwesomeIcons.sun : FontAwesomeIcons.moon,
              size: 16,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
