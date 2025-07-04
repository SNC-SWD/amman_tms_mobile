import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

// Import model dan widget kustom
import '../models/bus_data.dart';
import '../widgets/detail_item_widget.dart';
import '../widgets/status_card_widget.dart';

// Enum untuk tipe peta
enum MapType { dark, street }

class BusMapScreen extends StatefulWidget {
  const BusMapScreen({super.key});

  @override
  State<BusMapScreen> createState() => _BusMapScreenState();
}

class _BusMapScreenState extends State<BusMapScreen>
    with TickerProviderStateMixin {
  // Data JSON mentah (dalam aplikasi nyata, ini akan datang dari API)
  final String jsonData = '''
  [{"id":2379440,"attributes":{"priority":0,"sat":16,"event":0,"ignition":true,"motion":true,"rssi":3,"sleepMode":0,"io69":1,"pdop":1.1,"hdop":0.5,"power":28.217,"battery":4.060,"operator":51010,"odometer":34559046,"totalDistance":2071268.47},"deviceId":1032,"protocol":"teltonika","deviceTime":"2025-07-02T08:37:04.000+00:00","latitude":-9.0102666,"longitude":116.8046533,"speed":18.898495,"course":351,"address":"Jl. Raya Mataram, Labuhan Haji, Kabupaten Lombok Timur, Nusa Tenggara Bar."}]
  ''';

  late final BusData busData;
  late final MapController _mapController;
  late final AnimationController _animationController;

  MapType _currentMapType = MapType.street;

  @override
  void initState() {
    super.initState();
    // Parsing data JSON
    busData = busDataFromJson(jsonData).first;
    _mapController = MapController();

    // Setup animasi untuk marker
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengganti tipe peta
  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.street
          ? MapType.dark
          : MapType.street;
    });
  }

  // Fungsi untuk memusatkan peta ke lokasi bus
  void _centerMap() {
    _mapController.move(LatLng(busData.latitude, busData.longitude), 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Lacak Bus #${busData.deviceId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(children: [_buildMap(), _buildDraggableDetailsPanel()]),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  // Widget untuk Peta
  Widget _buildMap() {
    final mapUrls = {
      MapType.dark:
          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      MapType.street: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    };

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(busData.latitude, busData.longitude),
        initialZoom: 16.0,
        maxZoom: 18.0,
        minZoom: 5.0,
      ),
      children: [
        TileLayer(
          urlTemplate: mapUrls[_currentMapType],
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(busData.latitude, busData.longitude),
              width: 80,
              height: 80,
              child: _buildBusMarker(),
            ),
          ],
        ),
      ],
    );
  }

  // Widget untuk Marker Bus di Peta
  Widget _buildBusMarker() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Membuat efek gelombang (ripple)
        final rippleSize = (_animationController.value * 50);
        final rippleOpacity = (1 - _animationController.value);

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Lingkaran animasi
              if (busData.attributes.motion)
                Container(
                  width: rippleSize,
                  height: rippleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).primaryColor.withOpacity(rippleOpacity * 0.5),
                  ),
                ),
              // Ikon bus yang berputar sesuai arah
              Transform.rotate(
                angle: (busData.course * (3.14159 / 180)), // Derajat ke radian
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
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
                    color: Theme.of(context).primaryColor,
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

  // Widget untuk Panel Detail yang bisa ditarik
  Widget _buildDraggableDetailsPanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                controller: scrollController,
                children: [
                  // Handle
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
                  const SizedBox(height: 12),
                  // Info Utama
                  _buildPrimaryInfo(),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  // Info Sekunder
                  DetailItemWidget(
                    icon: FontAwesomeIcons.gaugeHigh,
                    title: 'Odometer',
                    value:
                        '${NumberFormat('#,##0').format(busData.attributes.odometer / 1000)} km',
                  ),
                  DetailItemWidget(
                    icon: FontAwesomeIcons.carBattery,
                    title: 'Sumber Daya',
                    value: '${busData.attributes.power.toStringAsFixed(1)} V',
                  ),
                  DetailItemWidget(
                    icon: FontAwesomeIcons.clock,
                    title: 'Pembaruan Terakhir',
                    value: DateFormat(
                      'd MMM yyyy, HH:mm:ss',
                      'id_ID',
                    ).format(busData.deviceTime.toLocal()),
                  ),
                  DetailItemWidget(
                    icon: FontAwesomeIcons.mapPin,
                    title: 'Alamat Terakhir',
                    value: busData.address ?? 'Data alamat tidak tersedia',
                    isAddress: true,
                  ),
                ].animate(interval: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget untuk Informasi Utama di Panel
  Widget _buildPrimaryInfo() {
    String statusText = busData.attributes.motion ? 'Bergerak' : 'Berhenti';
    Color statusColor = busData.attributes.motion
        ? Theme.of(context).primaryColor
        : Colors.amber.shade600;

    return Column(
      children: [
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
              value: busData.speedInKmh.toStringAsFixed(0),
              unit: 'km/h',
              label: 'Kecepatan',
            ),
            StatusCardWidget(
              icon: busData.attributes.ignition
                  ? FontAwesomeIcons.key
                  : FontAwesomeIcons.key,
              value: busData.attributes.ignition ? 'ON' : 'OFF',
              label: 'Mesin',
              color: busData.attributes.ignition
                  ? Theme.of(context).primaryColor
                  : Colors.redAccent,
            ),
            StatusCardWidget(
              icon: busData.attributes.motion
                  ? FontAwesomeIcons.route
                  : FontAwesomeIcons.squareParking,
              value: busData.attributes.motion ? 'YA' : 'TIDAK',
              label: 'Gerak',
              color: busData.attributes.motion
                  ? Theme.of(context).primaryColor
                  : Colors.grey[400],
            ),
          ],
        ),
      ],
    );
  }

  // Widget untuk Tombol Aksi
  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: _centerMap,
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
        const SizedBox(height: 110), // Memberi ruang untuk panel bawah
      ],
    );
  }
}
