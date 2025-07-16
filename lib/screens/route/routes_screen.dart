import 'dart:ui';

import 'package:amman_tms_mobile/screens/route/route_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'route_form_screen.dart'; // Asumsi file ini ada
import 'package:amman_tms_mobile/widgets/timeline_route_view.dart'; // Asumsi file ini ada
import 'package:amman_tms_mobile/widgets/stepped_route_view.dart'; // Asumsi file ini ada
import 'package:amman_tms_mobile/models/route_line.dart'
    as model_route_line; // Asumsi file ini ada
import 'package:amman_tms_mobile/core/services/route_service.dart'; // Asumsi file ini ada
import 'package:intl/intl.dart'; // Untuk format tanggal

// --- Color Palette ---
const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);
const kSlateGray = Color(0xFF4C5C74);
const kSoftGold = Color(0xFFE0B352);
const kBlueTint = Color(0xFFE6EDF6);

// --- Best Practice: Pindahkan helper/util ke file terpisah, misal: 'utils/navigation.dart' ---
// Helper untuk dialog dengan animasi
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim1, anim2) => builder(context),
    transitionBuilder: (context, anim1, anim2, child) {
      final curved = Curves.easeOutBack.transform(anim1.value);
      return Opacity(
        opacity: anim1.value,
        child: Transform.scale(scale: 0.95 + 0.05 * curved, child: child),
      );
    },
  );
}

// Helper untuk push screen dengan transisi fade+slide
Future<T?> pushWithTransition<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.15, 0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        final fadeTween = Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}

// --- Best Practice: Pindahkan model data ke file terpisah, misal: 'models/route_data.dart' ---
class RouteData {
  final int? id;
  final String name;
  final String bus;
  final int? busId;
  final String? boardingPoint;
  final String? droppingPoint;
  final String? startTime;
  final String? endTime;
  final List<model_route_line.RouteLine>? lines;

  RouteData({
    this.id,
    this.name = '',
    required this.bus,
    this.busId,
    this.boardingPoint,
    this.droppingPoint,
    this.startTime,
    this.endTime,
    this.lines,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      id: json['id'],
      name: json['name'] ?? '',
      bus: json['fleet'] ?? '',
      busId: json['fleet_id'],
      boardingPoint: json['boarding'],
      droppingPoint: json['dropping'],
      startTime: json['str_time']?.toString(),
      endTime: json['end_time']?.toString(),
      lines: (json['route_lines'] as List<dynamic>?)
          ?.map((line) => model_route_line.RouteLine.fromJson(line))
          .toList(),
    );
  }
}

// --- Best Practice: File ini seharusnya hanya berisi RoutesScreen dan widget-child-nya ---
class RoutesScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String userRole;
  final String? busName;
  const RoutesScreen({
    super.key,
    required this.onLogout,
    required this.userRole,
    this.busName,
  });

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  // ... (State variables tidak berubah, jadi saya persingkat di sini)
  String username = 'Demo';
  bool _isLoading = true;
  String? _errorMessage;
  List<RouteData> allRoutes = [];
  final RouteService _routeService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFleet;
  List<String> _availableFleets = [];
  int _currentPage = 1;
  final int _perPage = 10;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  // ... (Variabel state lain)

  _RoutesScreenState() : _routeService = RouteService();

  @override
  void initState() {
    super.initState();
    _loadRoutes(); // Panggil _loadRoutes langsung
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData && !_isLoading) {
        _loadMoreRoutes();
      }
    }
  }

  // --- (Logika pengambilan data seperti _loadRoutes, _loadMoreRoutes tidak diubah) ---
  Future<void> _loadRoutes({bool forceRefresh = false}) async {
    // MODIFIED: Clear error on refresh and set loading
    if (forceRefresh) {
      setState(() {
        _errorMessage = null;
        _currentPage = 1;
        allRoutes.clear();
      });
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await _routeService.getRoutes(
        page: 1, // Always fetch page 1 on refresh
        perPage: _perPage,
        pagination: true,
      );
      if (!mounted) return;
      if (result['status'] == true) {
        final routesData = (result['data'] as List)
            .map((json) => RouteData.fromJson(json))
            .toList();
        final fleets = routesData
            .map((r) => r.bus)
            .where((b) => b.isNotEmpty)
            .toSet()
            .toList();
        setState(() {
          allRoutes = routesData;
          _availableFleets = fleets;
          _hasMoreData = routesData.length >= _perPage;
          _currentPage = 1;
          _errorMessage = null; // Clear error on success
        });
      } else {
        setState(() => _errorMessage = result['message']);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Gagal memuat rute: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreRoutes() async {
    if (_isLoadingMore || !_hasMoreData) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _routeService.getRoutes(
        page: _currentPage + 1,
        perPage: _perPage,
        pagination: true,
      );
      if (result['status'] == true) {
        final newRoutes = (result['data'] as List)
            .map((json) => RouteData.fromJson(json))
            .toList();
        if (newRoutes.isNotEmpty) {
          setState(() {
            allRoutes.addAll(newRoutes);
            _currentPage++;
            _hasMoreData = newRoutes.length >= _perPage;
          });
        } else {
          setState(() => _hasMoreData = false);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // Getter untuk filter, tidak berubah
  List<RouteData> get filteredRoutes {
    // ... Logika filter tidak berubah
    return allRoutes.where((route) {
      final matchesSearch =
          route.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          route.bus.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFleet =
          _selectedFleet == null || route.bus == _selectedFleet;
      return matchesSearch && matchesFleet;
    }).toList();
  }

  // Navigasi
  void _openRouteDetail(RouteData route) {
    pushWithTransition(
      context,
      RouteDetailScreen(route: route, userRole: widget.userRole),
    );
  }

  void _addRoute() {
    pushWithTransition(context, RouteFormScreen(title: 'Tambah Rute')).then((
      result,
    ) {
      if (result == true) {
        _loadRoutes(forceRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result == false) {
        // Opsional: tampilkan error jika gagal
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Gagal menyimpan route'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: kLightGray,
        body: Stack(
          children: [
            // --- Layer 1: Latar Belakang Gradient Mesh Baru ---
            _buildModernBackground(),

            // --- Layer 2: Konten Utama ---
            Column(
              children: [
                _buildHeader(),
                _buildSearchAndFilter(),
                Expanded(child: _buildBodyContent()),
              ],
            ),
          ],
        ),
        floatingActionButton:
            (widget.userRole == 'driver' || widget.userRole == 'passenger')
            ? null
            : FloatingActionButton(
                onPressed: _addRoute,
                backgroundColor: kAccentGold,
                foregroundColor: Colors.white,
                tooltip: 'Tambah Rute',
                elevation: 4,
                child: const Icon(Icons.add, size: 28),
              ),
      ),
    );
  }

  // --- WIDGET BARU UNTUK LATAR BELAKANG MODERN ---
  Widget _buildModernBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: kLightGray,
      child: Stack(
        children: [
          // Lingkaran gradien yang di-blur
          Positioned(
            top: -150,
            left: -150,
            child: _buildGradientCircle(kPrimaryBlue.withOpacity(0.2), 400),
          ),
          Positioned(
            bottom: -200,
            right: -150,
            child: _buildGradientCircle(kAccentGold.withOpacity(0.2), 450),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: _buildGradientCircle(kPrimaryBlue.withOpacity(0.1), 350),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          center: Alignment.center,
          radius: 0.8,
        ),
      ),
    );
  }

  // --- WIDGET BARU UNTUK HEADER MODERN ---
  Widget _buildHeader() {
    return Container(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 130, // Tinggi header disesuaikan untuk halaman ini
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryBlue, Color(0xFF2E4C6D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Konten di atas latar belakang melengkung
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Tombol kembali jika diperlukan (opsional)
                  // IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  // Spacer(),
                  const Text(
                    'Routes',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  // Spacer(),
                  // SizedBox(width: 48), // Spacer untuk menyeimbangkan tombol kembali
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIKASI: _buildSearchAndFilter dibuat transparan ---
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: Colors.transparent, // Dibuat transparan
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cari rute, bus, atau lokasi...',
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kSlateGray,
              ),
              labelStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kSlateGray,
              ),
              prefixIcon: const Icon(Icons.search, color: kSlateGray, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: kSlateGray,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none, // Hapus border default
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kAccentGold, width: 1.5),
              ),
            ),
          ),
          if (_availableFleets.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _availableFleets.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildFilterChip(
                      'Semua',
                      _selectedFleet == null,
                      () {
                        setState(() => _selectedFleet = null);
                      },
                    );
                  }
                  final fleet = _availableFleets[index - 1];
                  final isSelected = _selectedFleet == fleet;
                  return _buildFilterChip(fleet, isSelected, () {
                    setState(() => _selectedFleet = isSelected ? null : fleet);
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // MODIFIED: buildBodyContent now wraps all states with RefreshIndicator
  Widget _buildBodyContent() {
    return RefreshIndicator(
      onRefresh: () => _loadRoutes(forceRefresh: true),
      color: kAccentGold,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_isLoading && allRoutes.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: kAccentGold),
            );
          }

          if (_errorMessage != null && allRoutes.isEmpty) {
            // Make error state scrollable to enable refresh
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: constraints.maxHeight, // Take full height
                alignment: Alignment.center,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          color: kSlateGray,
                          size: 50,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _loadRoutes(forceRefresh: true),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          if (filteredRoutes.isEmpty) {
            // Make empty state scrollable to enable refresh
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: constraints.maxHeight,
                alignment: Alignment.center,
                child: _buildEmptyState(),
              ),
            );
          }

          // The main list view for data
          return ListView.separated(
            controller: _scrollController,
            physics:
                const AlwaysScrollableScrollPhysics(), // Ensure it's always scrollable
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: filteredRoutes.length + (_isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == filteredRoutes.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(color: kAccentGold),
                  ),
                );
              }
              final route = filteredRoutes[index];
              return _buildRouteCard(route);
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onSelected,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: kAccentGold.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? kAccentGold : kSlateGray,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? kAccentGold : Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 50, color: kSlateGray.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Rute Ditemukan',
            style: TextStyle(
              fontSize: 14,
              color: kSlateGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba ubah kata kunci atau filter Anda',
            style: TextStyle(
              fontSize: 12,
              color: kSlateGray.withOpacity(0.7),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(RouteData route) {
    // Helper format waktu yang disederhanakan
    String formatTime(String? time) {
      if (time == null) return '-';
      try {
        final parts = time.split('.');
        return '${parts[0].padLeft(2, '0')}:${parts.length > 1 ? parts[1].padLeft(2, '0') : '00'}';
      } catch (e) {
        return time;
      }
    }

    return InkWell(
      onTap: () => _openRouteDetail(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16), // Padding disesuaikan
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kPrimaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_bus,
                            color: kSlateGray,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            route.bus,
                            style: const TextStyle(
                              color: kSlateGray,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: kBlueTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${formatTime(route.startTime)} - ${formatTime(route.endTime)}',
                    style: const TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: kLightGray),
            Row(
              children: [
                _buildLocationInfo(
                  icon: Icons.my_location,
                  label: 'Boarding',
                  value: route.boardingPoint ?? '-',
                ),
                const SizedBox(width: 16),
                _buildLocationInfo(
                  icon: Icons.flag,
                  label: 'Dropping',
                  value: route.droppingPoint ?? '-',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kSlateGray, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: kSlateGray.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: kPrimaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- CLASS BARU UNTUK MEMBUAT BENTUK MELENGKUNG (SAMA SEPERTI HOME) ---
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40); // Mulai dari bawah
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(
      size.width - (size.width / 4),
      size.height - 40,
    );
    var secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
