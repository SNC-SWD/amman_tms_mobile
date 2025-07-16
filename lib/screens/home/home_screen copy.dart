import 'package:amman_tms_mobile/screens/bus/bus_search_screen.dart';
import 'package:amman_tms_mobile/screens/notification/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amman_tms_mobile/screens/bus_trip/bus_trip_history_screen.dart';
import 'package:amman_tms_mobile/screens/bus_trip/bus_trip_detail_screen.dart';
import 'package:amman_tms_mobile/screens/bus_trip/add_bus_trip_screen.dart';
import 'package:amman_tms_mobile/screens/bus_trip/plan_trip_screen.dart';
import 'package:amman_tms_mobile/screens/bus_trip/trip_confirmation_screen.dart';
import 'package:amman_tms_mobile/core/services/bus_trip_service.dart';
import 'package:amman_tms_mobile/core/services/route_service.dart';
import 'package:amman_tms_mobile/core/services/auth_service.dart';
import 'package:amman_tms_mobile/core/services/fleet_service.dart';
import 'package:amman_tms_mobile/models/bus_trip.dart';
import 'package:intl/intl.dart';
import 'package:amman_tms_mobile/screens/bus/bus_list_page.dart';

const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);
const kSlateGray = Color(0xFF4C5C74);
const kSoftGold = Color(0xFFE0B352);
const kBlueTint = Color(0xFFE6EDF6);

class HomeScreen extends StatefulWidget {
  final String userRole;
  final String? busName;

  const HomeScreen({super.key, required this.userRole, this.busName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BusTripService _busTripService = BusTripService();
  final RouteService _routeService = RouteService();
  final AuthService _authService = AuthService();
  final FleetService _fleetService = FleetService();
  List<BusTrip> _recentBusTrips = [];
  List<BusTrip> _routesToConfirm = [];
  bool _isLoadingTrips = true;
  bool _isLoadingRoutes = true;
  bool _isLoadingBus = true;
  String? _errorMessage;
  String? _routeErrorMessage;
  String? _busErrorMessage;
  Map<String, dynamic>? _assignedBus;

  // Cache variables for bus trips
  static List<BusTrip>? _cachedTrips;
  static DateTime? _cachedTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Cache variables for routes to confirm
  static List<BusTrip>? _cachedRoutes;
  static DateTime? _cachedRoutesTime;
  static const Duration _routesCacheDuration = Duration(minutes: 5);

  // Cache variables for assigned bus
  static Map<String, dynamic>? _cachedAssignedBus;
  static DateTime? _cachedAssignedBusTime;
  static const Duration _assignedBusCacheDuration = Duration(minutes: 5);

  // Cache variables for supervisor stats
  static Map<String, int>? _cachedStats;
  static DateTime? _cachedStatsTime;
  static const Duration _statsCacheDuration = Duration(minutes: 5);

  List<Map<String, dynamic>> _recentPlanTrips = [];
  bool _isLoadingPlanTrips = true;
  String? _planTripErrorMessage;
  static List<Map<String, dynamic>>? _cachedPlanTrips;
  static DateTime? _cachedPlanTripsTime;
  static const Duration _planTripsCacheDuration = Duration(minutes: 5);

  String _userName = '';

  // Add filter state for Trip to Confirm
  int? _filterStatusSeq; // null = Semua
  DateTime _filterStartDate = DateTime.now();
  DateTime _filterEndDate = DateTime.now().add(const Duration(days: 1));

  // Tambahkan state di _HomeScreenState
  int _totalRoutes = 0;
  int _activeBuses = 0;
  int _totalPassengers = 0;
  int _todaysTrips = 0;
  bool _isLoadingStats = true;

  // Tambahkan helper untuk mapping status_seq ke label dan warna
  Map<int, Map<String, dynamic>> busStatusMap = {
    0: {'label': 'Ready', 'color': Colors.grey},
    1: {'label': 'Trip Confirmed', 'color': Colors.blue},
    2: {'label': 'On Trip', 'color': Colors.green},
    3: {'label': 'End Trip', 'color': Colors.red},
    4: {'label': 'Standby', 'color': Colors.orange},
    5: {'label': 'Maintenance', 'color': Colors.purple},
    6: {'label': 'Change Shift', 'color': Colors.teal},
    7: {'label': 'Rest', 'color': Colors.brown},
  };

  @override
  void initState() {
    super.initState();
    _loadUserName();
    if (widget.userRole == 'unknown') {
      // If userRole is unknown, try to get it from AuthService
      _authService.getUserProfile().then((profile) {
        if (profile != null && mounted) {
          final jobTitle =
              profile['employee']?['job_title']?.toString().toLowerCase() ?? '';
          String userRole = 'unknown';
          if (jobTitle.contains('driver')) {
            userRole = 'driver';
          } else if (jobTitle.contains('supervisor') ||
              jobTitle.contains('system analyst')) {
            userRole = 'supervisor';
          } else if (jobTitle.contains('passenger')) {
            userRole = 'passenger';
          }
          // Update the parent widget's state through a callback
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HomeScreen(userRole: userRole, busName: widget.busName),
              ),
            );
          }
        }
      });
    }
    if (widget.userRole == 'driver') {
      _loadRoutesToConfirm();
      _loadAssignedBus();
    }
    if (widget.userRole == 'supervisor') {
      _loadSupervisorStats();
      _loadRecentBusTrips();
      _loadRecentPlanTrips();
    }
    if (widget.userRole == 'passenger') {
      _loadRecentBusTrips();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh routes data when screen becomes active (for driver role)
    if (widget.userRole == 'driver' &&
        _routesToConfirm.isEmpty &&
        !_isLoadingRoutes) {
      _loadRoutesToConfirm();
    }
  }

  Future<void> _loadUserName() async {
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _userName = profile['employee']?['name'] ?? '';
        });
      }
    } catch (e) {
      // ignore error, fallback to default
    }
  }

  Future<void> _loadRoutesToConfirm() async {
    // Check cache first
    if (_cachedRoutes != null && _cachedRoutesTime != null) {
      final now = DateTime.now();
      if (now.difference(_cachedRoutesTime!) < _routesCacheDuration) {
        print('🔄 [HomeScreen] Using cached routes to confirm');
        setState(() {
          _routesToConfirm = _cachedRoutes!;
          _isLoadingRoutes = false;
        });
        print('✅ [HomeScreen] Routes cache used, loading false');
        return;
      }
    }

    setState(() {
      _isLoadingRoutes = true;
      _routeErrorMessage = null;
    });
    print('🔄 [HomeScreen] Start loading routes from API');

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        setState(() {
          _routeErrorMessage = 'User ID not found. Please login again.';
          _isLoadingRoutes = false;
        });
        return;
      }
      List<BusTrip> newRoutes = [];
      if (widget.userRole == 'driver') {
        final startDate = DateFormat('yyyy-MM-dd').format(_filterStartDate);
        final endDate = DateFormat('yyyy-MM-dd').format(_filterEndDate);
        final result = await _busTripService.getBusTrips(
          startDate: startDate,
          endDate: endDate,
          userId: userId,
          busStatusSeq: _filterStatusSeq != null
              ? _filterStatusSeq.toString()
              : null,
        );
        if (result['status'] == true) {
          final List<dynamic> routesData = result['data'];
          newRoutes = routesData
              .map<BusTrip>((route) => BusTrip.fromJson(route))
              .toList();

          // Update cache
          _cachedRoutes = newRoutes;
          _cachedRoutesTime = DateTime.now();
        } else {
          setState(() {
            _routeErrorMessage = result['message'];
            // Clear cache on error to prevent showing stale data
            _cachedRoutes = null;
            _cachedRoutesTime = null;
          });
          return;
        }
      } else {
        newRoutes = [];
      }
      setState(() {
        _routesToConfirm = newRoutes;
      });
      print('✅ [HomeScreen] Routes API success, loading false');
    } catch (e) {
      setState(() {
        _routeErrorMessage = 'Failed to load routes: $e';
        // Clear cache on error to prevent showing stale data
        _cachedRoutes = null;
        _cachedRoutesTime = null;
      });
      print('❌ [HomeScreen] Routes Exception, loading false');
    } finally {
      setState(() {
        _isLoadingRoutes = false;
      });
    }
  }

  Future<void> _loadRecentBusTrips() async {
    // Check cache first
    if (_cachedTrips != null && _cachedTime != null) {
      final now = DateTime.now();
      if (now.difference(_cachedTime!) < _cacheDuration) {
        print('🔄 [HomeScreen] Using cached bus trips');
        setState(() {
          _recentBusTrips = _cachedTrips!;
          _isLoadingTrips = false;
        });
        print('✅ [HomeScreen] Cache used, loading false');
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoadingTrips = true;
      _errorMessage = null;
    });
    print('🔄 [HomeScreen] Start loading from API');

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final result = await _busTripService.getBusTrips(
        startDate: today,
        endDate: today,
        busStatusSeq: widget.userRole == 'passenger' ? '2' : null,
      );

      if (!mounted) return;

      if (result['status'] == true) {
        final List<dynamic> tripsData = result['data'];
        final newTrips = tripsData
            .map((trip) => BusTrip.fromJson(trip))
            .toList();

        // Update cache
        _cachedTrips = newTrips;
        _cachedTime = DateTime.now();

        setState(() {
          _recentBusTrips = newTrips;
          _isLoadingTrips = false;
          _errorMessage = null;
        });
        print('✅ [HomeScreen] API success, loading false');
      } else {
        // Handle API error response
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load bus trips';
          _isLoadingTrips = false;
          // Clear cache on error to prevent showing stale data
          _cachedTrips = null;
          _cachedTime = null;
        });
        print('❌ [HomeScreen] API error, loading false');
      }
    } catch (e) {
      if (!mounted) return;
      // Handle network/other errors
      setState(() {
        _errorMessage = 'Failed to load bus trips: $e';
        _isLoadingTrips = false;
        // Clear cache on error to prevent showing stale data
        _cachedTrips = null;
        _cachedTime = null;
      });
      print('❌ [HomeScreen] Exception, loading false');
    }
  }

  Future<void> _loadAssignedBus() async {
    // Check cache first
    if (_cachedAssignedBus != null && _cachedAssignedBusTime != null) {
      final now = DateTime.now();
      if (now.difference(_cachedAssignedBusTime!) < _assignedBusCacheDuration) {
        print('🔄 [HomeScreen] Using cached assigned bus');
        setState(() {
          _assignedBus = _cachedAssignedBus;
          _isLoadingBus = false;
        });
        print('✅ [HomeScreen] Assigned bus cache used, loading false');
        return;
      }
    }

    setState(() {
      _isLoadingBus = true;
      _busErrorMessage = null;
    });
    print('🔄 [HomeScreen] Start loading assigned bus from API');

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        setState(() {
          _busErrorMessage = 'User ID not found. Please login again.';
          _isLoadingBus = false;
        });
        return;
      }

      final result = await _fleetService.getMyAssignedBus(userId);
      if (result['status'] == true) {
        final List<dynamic> busData = result['data'];
        if (busData.isNotEmpty) {
          // Update cache
          _cachedAssignedBus = busData[0];
          _cachedAssignedBusTime = DateTime.now();

          setState(() {
            _assignedBus = busData[0];
          });
        }
      } else {
        setState(() {
          _busErrorMessage = result['message'];
          // Clear cache on error to prevent showing stale data
          _cachedAssignedBus = null;
          _cachedAssignedBusTime = null;
        });
      }
      print('✅ [HomeScreen] Assigned bus API success, loading false');
    } catch (e) {
      setState(() {
        _busErrorMessage = 'Failed to load assigned bus: $e';
        // Clear cache on error to prevent showing stale data
        _cachedAssignedBus = null;
        _cachedAssignedBusTime = null;
      });
      print('❌ [HomeScreen] Assigned bus Exception, loading false');
    } finally {
      setState(() {
        _isLoadingBus = false;
      });
    }
  }

  Future<void> _loadRecentPlanTrips() async {
    // Check cache first
    if (_cachedPlanTrips != null && _cachedPlanTripsTime != null) {
      final now = DateTime.now();
      if (now.difference(_cachedPlanTripsTime!) < _planTripsCacheDuration) {
        print('🔄 [HomeScreen] Using cached plan trips');
        setState(() {
          _recentPlanTrips = _cachedPlanTrips!;
          _isLoadingPlanTrips = false;
        });
        return;
      }
    }
    setState(() {
      _isLoadingPlanTrips = true;
      _planTripErrorMessage = null;
    });
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final result = await _busTripService.getPlanTrips(tripDate: today);
      if (result['status'] == true) {
        final List<dynamic> planTripsData = result['data'];
        final newPlanTrips = planTripsData.cast<Map<String, dynamic>>();
        _cachedPlanTrips = newPlanTrips;
        _cachedPlanTripsTime = DateTime.now();
        setState(() {
          _recentPlanTrips = newPlanTrips;
        });
      } else {
        setState(() {
          _planTripErrorMessage = result['message'];
          // Clear cache on error to prevent showing stale data
          _cachedPlanTrips = null;
          _cachedPlanTripsTime = null;
        });
      }
      print('✅ [HomeScreen] Plan trips API success, loading false');
    } catch (e) {
      setState(() {
        _planTripErrorMessage = 'Failed to load plan trips: $e';
        // Clear cache on error to prevent showing stale data
        _cachedPlanTrips = null;
        _cachedPlanTripsTime = null;
      });
      print('❌ [HomeScreen] Plan trips Exception, loading false');
    } finally {
      setState(() {
        _isLoadingPlanTrips = false;
      });
    }
  }

  Future<void> _loadSupervisorStats() async {
    // Check cache first
    if (_cachedStats != null && _cachedStatsTime != null) {
      final now = DateTime.now();
      if (now.difference(_cachedStatsTime!) < _statsCacheDuration) {
        print('🔄 [HomeScreen] Using cached supervisor stats');
        setState(() {
          _totalRoutes = _cachedStats!['totalRoutes'] ?? 0;
          _activeBuses = _cachedStats!['activeBuses'] ?? 0;
          _todaysTrips = _cachedStats!['todaysTrips'] ?? 0;
          _totalPassengers = _cachedStats!['totalPassengers'] ?? 0;
          _isLoadingStats = false;
        });
        print('✅ [HomeScreen] Stats cache used, loading false');
        return;
      }
    }

    setState(() => _isLoadingStats = true);
    print('🔄 [HomeScreen] Start loading supervisor stats from API');

    try {
      // Total Routes
      final routeResult = await _routeService.getRoutes();
      if (routeResult['status'] == true) {
        _totalRoutes = (routeResult['data'] as List).length;
      } else {
        _totalRoutes = 0;
      }

      // Active Buses (On Trip)
      final fleetResult = await _fleetService.getFleets(statusName: 'On Trip');
      if (fleetResult['status'] == true) {
        _activeBuses = (fleetResult['data'] as List).length;
      } else {
        _activeBuses = 0;
      }

      // Today's Trips & Passengers
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final tripResult = await _busTripService.getBusTrips(
        startDate: today,
        endDate: today,
      );
      if (tripResult['status'] == true) {
        final trips = tripResult['data'] as List;
        _todaysTrips = trips.length;
        _totalPassengers = trips.fold<int>(
          0,
          (sum, t) => sum + ((t['seat_booked'] ?? 0) as int),
        );
      } else {
        _todaysTrips = 0;
        _totalPassengers = 0;
      }

      // Update cache
      _cachedStats = {
        'totalRoutes': _totalRoutes,
        'activeBuses': _activeBuses,
        'todaysTrips': _todaysTrips,
        'totalPassengers': _totalPassengers,
      };
      _cachedStatsTime = DateTime.now();
      print('✅ [HomeScreen] Supervisor stats API success, loading false');
    } catch (e) {
      _totalRoutes = 0;
      _activeBuses = 0;
      _todaysTrips = 0;
      _totalPassengers = 0;

      // Clear cache on error
      _cachedStats = null;
      _cachedStatsTime = null;
      print('❌ [HomeScreen] Supervisor stats Exception, loading false');
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  // Helper function to map status sequence to state value
  String _getStateFromStatusSeq(int statusSeq) {
    switch (statusSeq) {
      case 0:
        return 'ready';
      case 1:
        return 'trip_confirmed';
      case 2:
        return 'on_trip';
      case 3:
        return 'end_trip';
      default:
        return 'ready';
    }
  }

  // Helper function to format time
  String _formatTime(double time) {
    final hour = time.floor();
    final minute = ((time - hour) * 60).round();
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

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
    if (widget.userRole == 'unknown') {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final horizontalPadding = responsivePadding(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: kPrimaryBlue,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Clear cache for all roles so refresh always fetches new data
            _cachedTrips = null;
            _cachedTime = null;
            _cachedRoutes = null;
            _cachedRoutesTime = null;
            _cachedPlanTrips = null;
            _cachedPlanTripsTime = null;
            _cachedAssignedBus = null;
            _cachedAssignedBusTime = null;
            _cachedStats = null;
            _cachedStatsTime = null;

            print('🔄 [HomeScreen] Refresh: All caches cleared');

            if (widget.userRole == 'supervisor') {
              print('🔄 [HomeScreen] Refresh: Loading supervisor data');
              await Future.wait([
                _loadSupervisorStats(),
                _loadRecentBusTrips(),
                _loadRecentPlanTrips(),
              ]);
            } else if (widget.userRole == 'driver') {
              print('🔄 [HomeScreen] Refresh: Loading driver data');
              await Future.wait([_loadRoutesToConfirm(), _loadAssignedBus()]);
            } else if (widget.userRole == 'passenger') {
              print('🔄 [HomeScreen] Refresh: Loading passenger data');
              await _loadRecentBusTrips();
            }
            print('✅ [HomeScreen] Refresh completed');
          },
          color: kAccentGold,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.userRole == 'supervisor'
                            ? 'Welcome, ${_userName.isNotEmpty ? _userName : 'Supervisor'}'
                            : widget.userRole == 'passenger'
                            ? 'Welcome, ${_userName.isNotEmpty ? _userName : 'Passenger'}'
                            : 'Hello, ${_userName.isNotEmpty ? _userName : 'Driver'}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveFont(20, context), // MODIFIED
                          color: kPrimaryBlue,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.notifications_rounded,
                        color: kPrimaryBlue,
                        size: responsiveFont(22, context), // MODIFIED
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Section for each role
                if (widget.userRole == 'supervisor') ...[
                  _buildSupervisorStats(),
                  const SizedBox(height: 24),
                  _buildRecentBusTrips(context),
                  // if (_recentPlanTrips.isNotEmpty) ...[
                  //   const SizedBox(height: 24),
                  //   _buildRecentPlanTrips(context),
                  // ],
                  const SizedBox(height: 24),
                  _buildSupervisorActions(context),
                ] else if (widget.userRole == 'driver') ...[
                  _buildDriverStats(),
                  const SizedBox(height: 24),
                  _buildRoutesToConfirm(),
                  const SizedBox(height: 24),
                  _buildDriverActions(context),
                ] else if (widget.userRole == 'passenger') ...[
                  _buildPassengerStatsSection(),
                  const SizedBox(height: 24),
                  _buildRecentBusTrips(context),
                  const SizedBox(height: 24),
                  _buildPassengerActions(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupervisorStats() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: responsiveFont(14, context),
            color: kPrimaryBlue,
          ),
        ),
        SizedBox(height: responsiveFont(16, context)),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.route_rounded,
                title: 'Total Routes',
                value: '$_totalRoutes Routes',
                color: kPrimaryBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.directions_bus_rounded,
                title: 'Active Buses',
                value: '$_activeBuses Buses Running',
                color: kAccentGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.groups_rounded,
                title: 'Total Passengers',
                value: '$_totalPassengers',
                color: kSoftGold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.schedule_rounded,
                title: 'Today\'s Trips',
                value: '$_todaysTrips',
                color: kSlateGray,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverStats() {
    // --- Data Logic (No Changes) ---
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayTrips = _routesToConfirm
        .where((trip) => trip.tripDate == today)
        .toList();

    // 1. Today's Route
    String todayRouteValue = 'No route today';
    final activeTrips = todayTrips
        .where((trip) => trip.statusSeq == 1 || trip.statusSeq == 2)
        .toList();
    if (activeTrips.isNotEmpty) {
      activeTrips.sort((a, b) => a.startTime.compareTo(b.startTime));
      final nearestTrip = activeTrips.first;
      final startHour = nearestTrip.startTime.floor();
      final startMinute = ((nearestTrip.startTime - startHour) * 60).round();
      final timeStr =
          '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
      todayRouteValue =
          '${nearestTrip.boardingPointName} → ${nearestTrip.dropPointName}, $timeStr';
    }

    // 2. Total Passengers
    int totalPassengers = todayTrips.fold(
      0,
      (sum, trip) => sum + trip.seatBooked,
    );
    String totalPassengersValue = '$totalPassengers Today';

    // 3. Last Confirmation
    String lastConfirmationValue = 'No confirmation yet';
    final confirmedTrips = todayTrips
        .where((trip) => trip.statusSeq == 1 || trip.statusSeq == 2)
        .toList();
    if (confirmedTrips.isNotEmpty) {
      confirmedTrips.sort((a, b) {
        if (a.statusSeq != b.statusSeq) {
          return (b.statusSeq ?? 0).compareTo(a.statusSeq ?? 0);
        }
        return b.startTime.compareTo(a.startTime);
      });
      final lastConfirmedTrip = confirmedTrips.first;
      final startHour = lastConfirmedTrip.startTime.floor();
      final startMinute = ((lastConfirmedTrip.startTime - startHour) * 60)
          .round();
      final timeStr =
          '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
      lastConfirmationValue = 'Confirmed at $timeStr';
    }

    // 4. Assigned Bus Logic (diintegrasikan dari _buildAssignedBusCard)
    String assignedBusTitle = 'Assigned Bus';
    String assignedBusValue;
    if (_isLoadingBus) {
      assignedBusValue = 'Loading...';
    } else if (_busErrorMessage != null) {
      assignedBusValue = 'Error loading bus';
    } else if (_assignedBus == null) {
      assignedBusValue = 'No bus assigned';
    } else {
      assignedBusValue =
          '${_assignedBus!['model_name']} - ${_assignedBus!['license_plate']}';
    }

    // --- UI Constants ---
    const double kTitleFontSize = 14.0;
    const double kSpacing = 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: kSpacing),
          child: Text(
            'Quick Stats',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: kTitleFontSize,
              color: kPrimaryBlue,
            ),
          ),
        ),
        const SizedBox(height: kSpacing),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: kSpacing),
          child: Row(
            children: [
              _buildStatCardV2(
                icon: Icons.route_rounded,
                title: 'Today\'s Route',
                value: todayRouteValue,
                gradientColors: [Colors.blue.shade300, Colors.blue.shade500],
                maxLines: 3,
              ),
              const SizedBox(width: kSpacing),
              _buildStatCardV2(
                icon: Icons.directions_bus_rounded,
                title: assignedBusTitle,
                value: assignedBusValue,
                gradientColors: [
                  Colors.orange.shade300,
                  Colors.orange.shade500,
                ],
                maxLines: 2,
              ),
              const SizedBox(width: kSpacing),
              _buildStatCardV2(
                icon: Icons.groups_rounded,
                title: 'Total Passengers',
                value: totalPassengersValue,
                gradientColors: [Colors.green.shade300, Colors.green.shade500],
              ),
              const SizedBox(width: kSpacing),
              _buildStatCardV2(
                icon: Icons.access_time_rounded,
                title: 'Last Confirmation',
                value: lastConfirmationValue,
                gradientColors: [Colors.grey.shade500, Colors.grey.shade700],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerStatsSection() {
    // Data dummy, bisa diganti dengan data asli jika ada
    int totalTrips = _recentBusTrips.length;
    int activeTrips = _recentBusTrips.where((t) {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      return t.tripDate == todayStr;
    }).length;
    int bookedSeats = _recentBusTrips.fold(
      0,
      (sum, t) => sum + (t.seatBooked ?? 0),
    );
    int activeRoutes = 8; // Dummy, bisa diganti jika ada data

    final stats = [
      {
        'icon': Icons.confirmation_number_rounded,
        'label': 'Total Trips',
        'value': '$totalTrips',
        'color': kPrimaryBlue,
      },
      {
        'icon': Icons.directions_bus_rounded,
        'label': 'Active Trips',
        'value': '$activeTrips',
        'color': kAccentGold,
      },
      {
        'icon': Icons.event_seat_rounded,
        'label': 'Booked Seats',
        'value': '$bookedSeats',
        'color': kSoftGold,
      },
      {
        'icon': Icons.route_rounded,
        'label': 'Active Routes',
        'value': '$activeRoutes',
        'color': kSlateGray,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: responsiveFont(14, context), // MODIFIED
            color: kPrimaryBlue,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: responsiveFont(16, context)),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 400;
            final isVerySmall = constraints.maxWidth < 340;
            return Wrap(
              spacing: responsiveFont(16, context),
              runSpacing: responsiveFont(16, context),
              children: stats.map((stat) {
                return Container(
                  width: isWide
                      ? (constraints.maxWidth - responsiveFont(16, context)) / 2
                      : (constraints.maxWidth - responsiveFont(16, context)),
                  constraints: BoxConstraints(
                    minWidth: isVerySmall ? 120 : 140,
                    maxWidth: isVerySmall ? 200 : 260,
                  ),
                  padding: EdgeInsets.all(responsiveFont(18, context)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: kAccentGold.withOpacity(0.13),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: (stat['color'] as Color).withOpacity(0.13),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(responsiveFont(10, context)),
                        child: Icon(
                          stat['icon'] as IconData,
                          color: stat['color'] as Color,
                          size: responsiveFont(22, context), // MODIFIED
                        ),
                      ),
                      SizedBox(width: responsiveFont(14, context)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: kSlateGray,
                                fontSize: responsiveFont(
                                  11.5,
                                  context,
                                ), // MODIFIED
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: responsiveFont(4, context)),
                            Text(
                              stat['value'] as String,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: stat['color'] as Color,
                                fontSize: responsiveFont(
                                  14,
                                  context,
                                ), // MODIFIED
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    double? minHeight,
    int? maxLines,
  }) {
    return Container(
      padding: EdgeInsets.all(responsiveFont(16, context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: minHeight != null
          ? BoxConstraints(minHeight: minHeight)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: responsiveFont(22, context),
          ), // MODIFIED
          SizedBox(height: responsiveFont(12, context)),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: kSlateGray,
                fontSize: responsiveFont(12, context), // MODIFIED
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(height: responsiveFont(4, context)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: color,
                fontSize: responsiveFont(14, context), // MODIFIED
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: maxLines ?? 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardV2({
    required IconData icon,
    required String title,
    required String value,
    required List<Color> gradientColors,
    int maxLines = 2, // Default maxLines
  }) {
    // --- UI Constants ---
    const double kCardWidth = 150.0;
    const double kCardHeight = 160.0;
    const double kIconCircleRadius = 22.0;
    const double kIconSize = 24.0;
    const double kTitleFontSize = 12.0;
    const double kValueFontSize = 15.0;

    return SizedBox(
      width: kCardWidth,
      height: kCardHeight,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            CircleAvatar(
              radius: kIconCircleRadius,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(icon, color: Colors.white, size: kIconSize),
            ),
            // Texts
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.9),
                    fontSize: kTitleFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: kValueFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBusTrips(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Trips',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: responsiveFont(14, context), // MODIFIED
                  color: kPrimaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusTripHistoryScreen(
                      initialStartDate: today,
                      initialEndDate: today,
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: kAccentGold,
                size: responsiveFont(18, context), // MODIFIED
              ),
              label: Text(
                'View All',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: responsiveFont(12, context), // MODIFIED
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: responsiveFont(8, context),
                  vertical: responsiveFont(4, context),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsiveFont(16, context)),
        if (_isLoadingTrips)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          Center(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: kSlateGray, fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
          )
        else if (_recentBusTrips == null || _recentBusTrips.isEmpty)
          const Center(
            child: Text(
              'No recent bus trips',
              style: TextStyle(color: kSlateGray, fontFamily: 'Poppins'),
            ),
          )
        else
          ..._recentBusTrips
              .take(2)
              .map(
                (trip) => Padding(
                  padding: EdgeInsets.only(bottom: responsiveFont(18, context)),
                  child: _buildModernTripCard(trip),
                ),
              ),
      ],
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

    // Status logic - following the same logic as _buildRoutesToConfirm
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
    final iconSize = screenWidth < 360 ? 18.0 : 20.0; // MODIFIED
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
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsiveFont(
                                    14,
                                    context,
                                  ), // MODIFIED
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
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsiveFont(
                                    14,
                                    context,
                                  ), // MODIFIED
                                  color: kAccentGold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: kPrimaryBlue,
                              size: responsiveFont(16, context), // MODIFIED
                            ),
                            Flexible(
                              child: Text(
                                ' ${trip.dropPointName ?? ''}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsiveFont(
                                    14,
                                    context,
                                  ), // MODIFIED
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
                              size: responsiveFont(16, context), // MODIFIED
                            ),
                            SizedBox(width: responsiveFont(4, context)),
                            Text(
                              _formatTime(trip.startTime),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: responsiveFont(
                                  12,
                                  context,
                                ), // MODIFIED
                              ),
                            ),
                            SizedBox(width: responsiveFont(14, context)),
                            Icon(
                              Icons.flag_rounded,
                              color: Colors.red,
                              size: responsiveFont(16, context), // MODIFIED
                            ),
                            SizedBox(width: responsiveFont(4, context)),
                            Text(
                              _formatTime(trip.endTime),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: responsiveFont(
                                  12,
                                  context,
                                ), // MODIFIED
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
                              size: responsiveFont(16, context), // MODIFIED
                            ),
                            SizedBox(width: responsiveFont(6, context)),
                            Flexible(
                              child: Text(
                                trip.userIdName ?? '',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: kSlateGray,
                                  fontSize: responsiveFont(
                                    11,
                                    context,
                                  ), // MODIFIED
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
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: badgeLabel == 'Waiting'
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: responsiveFont(
                                      11,
                                      context,
                                    ), // MODIFIED
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
                                    fontFamily: 'Poppins',
                                    color: kPrimaryBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: responsiveFont(
                                      11,
                                      context,
                                    ), // MODIFIED
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
                                    size: responsiveFont(
                                      14,
                                      context,
                                    ), // MODIFIED
                                  ),
                                  SizedBox(width: responsiveFont(4, context)),
                                  Text(
                                    (trip.seatBooked ?? 0).toString(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: kPrimaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: responsiveFont(
                                        13,
                                        context,
                                      ), // MODIFIED
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

  Widget _buildRoutesToConfirm() {
    // Section label tetap berdasarkan filter
    String sectionLabel = 'My Trips';
    if (_filterStatusSeq == 1) {
      sectionLabel = 'Trip Confirmed';
    } else if (_filterStatusSeq == 2) {
      sectionLabel = 'On Trip';
    } else if (_filterStatusSeq == 3) {
      sectionLabel = 'End Trip';
    } else if (_filterStatusSeq == null) {
      sectionLabel = 'My Trips';
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return RefreshIndicator(
      onRefresh: _loadRoutesToConfirm,
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sectionLabel,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: responsiveFont(14, context), // MODIFIED
                    color: kPrimaryBlue,
                  ),
                ),
              ),
              if (widget.userRole == 'driver')
                IconButton(
                  icon: Icon(
                    Icons.filter_alt_rounded,
                    color: kPrimaryBlue,
                    size: responsiveFont(22, context), // MODIFIED
                  ),
                  onPressed: _showTripToConfirmFilterDialog,
                  tooltip: 'Filter',
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.all(responsiveFont(8, context)),
                  ),
                ),
            ],
          ),
          SizedBox(height: responsiveFont(16, context)),
          if (_isLoadingRoutes)
            const Center(child: CircularProgressIndicator())
          else if (_routeErrorMessage != null)
            Center(
              child: Text(
                _routeErrorMessage!,
                style: const TextStyle(
                  color: kSlateGray,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (_routesToConfirm.isEmpty)
            const Center(
              child: Text(
                'No routes to confirm',
                style: TextStyle(color: kSlateGray, fontFamily: 'Poppins'),
              ),
            )
          else
            ..._routesToConfirm.map((trip) {
              // Tombol dan popup berdasarkan status trip
              String actionLabel = 'Konfirmasi Trip';
              int nextStatusSeq = 1;
              String popupMsg =
                  'Apakah Anda yakin ingin mengkonfirmasi trip ini? Status akan menjadi Trip Confirmed.';
              if (trip.statusSeq == 1) {
                actionLabel = 'Mulai Perjalanan';
                nextStatusSeq = 2;
                popupMsg = 'Mulai perjalanan ini? Status akan menjadi On Trip.';
              } else if (trip.statusSeq == 2) {
                actionLabel = 'Akhiri Trip';
                nextStatusSeq = 3;
                popupMsg = 'Akhiri trip ini? Status akan menjadi End Trip.';
              }
              return Padding(
                padding: EdgeInsets.only(bottom: responsiveFont(12, context)),
                child: _buildConfirmCard(
                  trip: trip,
                  actionLabel: actionLabel,
                  nextStatusSeq: nextStatusSeq,
                  popupMsg: popupMsg,
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showTripToConfirmFilterDialog() async {
    int? tempStatus = _filterStatusSeq;
    DateTime tempStart = _filterStartDate;
    DateTime tempEnd = _filterEndDate;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Filter Trip'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int?>(
                      value: tempStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua')),
                        DropdownMenuItem(value: 0, child: Text('Ready')),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Trip Confirmed'),
                        ),
                        DropdownMenuItem(value: 2, child: Text('On Trip')),
                        DropdownMenuItem(value: 3, child: Text('End Trip')),
                      ],
                      onChanged: (v) => setState(() => tempStatus = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: tempStart,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() => tempStart = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                              ),
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(tempStart),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: tempEnd,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() => tempEnd = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                              ),
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(tempEnd),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterStatusSeq = tempStatus;
                      _filterStartDate = tempStart;
                      _filterEndDate = tempEnd;
                    });
                    _loadRoutesToConfirm();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmCard({
    required BusTrip trip,
    String actionLabel = 'Confirm',
    int nextStatusSeq = 1,
    String popupMsg = '',
  }) {
    // --- Helper & Logic ---
    String formatTripDate(String? dateStr) {
      try {
        if (dateStr == null || dateStr.isEmpty) return 'No Date';
        final date = DateTime.parse(dateStr);
        return DateFormat('dd MMM yyyy').format(date);
      } catch (_) {
        return dateStr ?? 'Invalid Date';
      }
    }

    // Status logic
    final int statusSeq = trip.statusSeq ?? 0;
    String statusLabel;
    Color statusColor;
    switch (statusSeq) {
      case 1:
        statusLabel = 'Trip Confirmed';
        statusColor = Colors.blue.shade600;
        break;
      case 2:
        statusLabel = 'On Trip';
        statusColor = Colors.green.shade600;
        break;
      case 3:
        statusLabel = 'End Trip';
        statusColor = Colors.red.shade600;
        break;
      default: // case 0
        statusLabel = 'Ready';
        statusColor = Colors.grey.shade600;
    }

    // --- UI Constants for Readability ---
    const double kCardPadding = 16.0;
    const double kIconPadding = 10.0;
    const double kIconSize = 22.0;
    const double kHorizontalSpacing = 16.0;
    const double kVerticalSpacing = 8.0;

    // Font Sizes
    const double kTitleFontSize = 14.0;
    const double kSubtitleFontSize = 13.0;
    const double kInfoFontSize = 12.0;

    // Colors (asumsi kPrimaryBlue, kAccentGold, dll sudah didefinisikan di scope yang lebih tinggi)
    // static const kPrimaryBlue = Color(0xFF163458);
    // static const kAccentGold = Color(0xFFE0B352);
    // static const kSlateGray = Color(0xFF4C5C74);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500.0),
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: kAccentGold.withOpacity(0.2), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(kCardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                decoration: BoxDecoration(
                  color: kAccentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(kIconPadding),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: kAccentGold,
                  size: kIconSize,
                ),
              ),
              const SizedBox(width: kHorizontalSpacing),
              // Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Bus Info & Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${trip.busFleetType} / ${trip.busPlate}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: kTitleFontSize,
                                  color: kPrimaryBlue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatTripDate(trip.tripDate),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: kInfoFontSize,
                                  color: kAccentGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: kInfoFontSize,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: kVerticalSpacing),
                    // Route Information
                    Text(
                      '${trip.boardingPointName} → ${trip.dropPointName}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: kSubtitleFontSize,
                        color: kPrimaryBlue,
                      ),
                      maxLines: 2, // Allow up to 2 lines for long routes
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kVerticalSpacing),
                    // Driver and Passenger Info
                    Row(
                      children: [
                        const Icon(Icons.person, color: kSlateGray, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            trip.userIdName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: kSlateGray,
                              fontSize: kInfoFontSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.groups_rounded,
                          color: kSlateGray,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (trip.seatBooked).toString(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: kPrimaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: kInfoFontSize,
                          ),
                        ),
                      ],
                    ),
                    // Action Button
                    if (statusLabel != 'End Trip') ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentGold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(actionLabel),
                                content: Text(popupMsg),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: Text(actionLabel),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              // Call both APIs in parallel
                              final vehicleResult = await _fleetService
                                  .updateVehicleStatus(
                                    busId: trip.busId,
                                    statusSeq: nextStatusSeq,
                                  );

                              final tripStateResult = await _busTripService
                                  .updateBusTripState(
                                    tripId: trip.id,
                                    state: nextStatusSeq.toString(),
                                    // state: _getStateFromStatusSeq(
                                    //   nextStatusSeq,
                                    // ),
                                  );

                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(); // remove loading

                              // Check if both operations were successful
                              if (vehicleResult['status'] == true &&
                                  tripStateResult['status'] == true) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$actionLabel success!'),
                                    ),
                                  );
                                  await _loadRoutesToConfirm();
                                }
                              } else {
                                if (mounted) {
                                  // Show error message from the failed operation
                                  String errorMessage = '';
                                  if (vehicleResult['status'] != true) {
                                    errorMessage =
                                        vehicleResult['message'] ??
                                        'Failed to update vehicle status';
                                  } else if (tripStateResult['status'] !=
                                      true) {
                                    errorMessage =
                                        tripStateResult['message'] ??
                                        'Failed to update trip state';
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errorMessage)),
                                  );
                                }
                              }
                            }
                          },
                          child: Text(
                            actionLabel,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupervisorActions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentGold,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: responsiveFont(16, context),
                    horizontal: responsiveFont(8, context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.add_rounded,
                  size: responsiveFont(18, context), // MODIFIED
                ),
                label: Text(
                  'Add New Trip',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: responsiveFont(13, context), // MODIFIED
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddBusTripScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: responsiveFont(16, context)),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: responsiveFont(16, context),
                    horizontal: responsiveFont(8, context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.history_rounded,
                  size: responsiveFont(18, context), // MODIFIED
                ),
                label: Text(
                  'View Bus Trip History',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: responsiveFont(13, context), // MODIFIED
                  ),
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BusTripHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverActions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: responsiveFont(16, context),
                    horizontal: responsiveFont(8, context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.history_rounded,
                  size: responsiveFont(18, context), // MODIFIED
                ),
                label: Text(
                  'My History',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: responsiveFont(13, context), // MODIFIED
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BusTripHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: responsiveFont(16, context)),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentGold,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: responsiveFont(16, context),
                    horizontal: responsiveFont(8, context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.edit_rounded,
                  size: responsiveFont(18, context), // MODIFIED
                ),
                label: Text(
                  'Edit Passenger Count',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: responsiveFont(13, context), // MODIFIED
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripConfirmationScreen(trip: null),
                    ),
                  );
                  if (result == true) {
                    _loadRoutesToConfirm();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPassengerActions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: responsiveFont(16, context),
                    horizontal: responsiveFont(8, context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.history_rounded,
                  size: responsiveFont(18, context), // MODIFIED
                ),
                label: Text(
                  'Trip History',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: responsiveFont(13, context), // MODIFIED
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BusTripHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: responsiveFont(16, context)),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentGold,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: responsiveFont(16, context),
                    horizontal: responsiveFont(8, context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.search_rounded,
                  size: responsiveFont(18, context), // MODIFIED
                ),
                label: Text(
                  'Find Bus',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: responsiveFont(13, context), // MODIFIED
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BusSearchScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentPlanTrips(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Plan Trip',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: responsiveFont(14, context), // MODIFIED
                  color: kPrimaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlanTripScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: kAccentGold,
                size: responsiveFont(18, context), // MODIFIED
              ),
              label: Text(
                'View All',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: responsiveFont(12, context), // MODIFIED
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: responsiveFont(8, context),
                  vertical: responsiveFont(4, context),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsiveFont(16, context)),
        if (_isLoadingPlanTrips)
          const Center(child: CircularProgressIndicator())
        else if (_planTripErrorMessage != null)
          Center(
            child: Text(
              _planTripErrorMessage!,
              style: const TextStyle(color: kSlateGray, fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
          )
        else if (_recentPlanTrips.isEmpty)
          const Center(
            child: Text(
              'No recent plan trips',
              style: TextStyle(color: kSlateGray, fontFamily: 'Poppins'),
            ),
          )
        else
          ..._recentPlanTrips
              .take(2)
              .map(
                (plan) => Padding(
                  padding: EdgeInsets.only(bottom: responsiveFont(18, context)),
                  child: _buildModernPlanTripCard(plan),
                ),
              ),
      ],
    );
  }

  Widget _buildModernPlanTripCard(Map<String, dynamic> plan) {
    String _formatDate(String? dateStr) {
      try {
        if (dateStr == null) return '';
        final date = DateTime.parse(dateStr);
        return DateFormat('dd MMM yyyy').format(date);
      } catch (_) {
        return dateStr ?? '';
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth < 360 ? 12.0 : 18.0;
    final iconPadding = screenWidth < 360 ? 10.0 : 16.0; // MODIFIED
    final iconSize = screenWidth < 360 ? 22.0 : 26.0; // MODIFIED
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
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kAccentGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.all(iconPadding),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: kAccentGold,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: responsiveFont(16, context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First row with date and bus name
                      Wrap(
                        spacing: responsiveFont(8, context),
                        runSpacing: responsiveFont(4, context),
                        children: [
                          Flexible(
                            child: Text(
                              _formatDate(plan['trip_date']),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: responsiveFont(
                                  14,
                                  context,
                                ), // MODIFIED
                                color: kAccentGold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsiveFont(8, context),
                              vertical: responsiveFont(2, context),
                            ),
                            decoration: BoxDecoration(
                              color: kBlueTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${plan['bus_name'] ?? ''}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: responsiveFont(
                                  12,
                                  context,
                                ), // MODIFIED
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsiveFont(6, context)),
                      // Route information
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${plan['from_name'] ?? ''} → ${plan['to_name'] ?? ''}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: responsiveFont(
                                  13,
                                  context,
                                ), // MODIFIED
                                color: kPrimaryBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsiveFont(8, context)),
                      // User and passenger info
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: kSlateGray,
                            size: responsiveFont(16, context), // MODIFIED
                          ),
                          SizedBox(width: responsiveFont(6, context)),
                          Flexible(
                            child: Text(
                              plan['user_name'] ?? '',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: kSlateGray,
                                fontSize: responsiveFont(
                                  11,
                                  context,
                                ), // MODIFIED
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.groups_rounded,
                            color: kSoftGold,
                            size: responsiveFont(14, context), // MODIFIED
                          ),
                          SizedBox(width: responsiveFont(4, context)),
                          Text(
                            (plan['booked_seat'] ?? 0).toString(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: kPrimaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: responsiveFont(13, context), // MODIFIED
                              letterSpacing: 0.5,
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
    );
  }

  // Widget custom untuk Assigned Bus
  Widget _buildAssignedBusCard() {
    if (_isLoadingBus) {
      return _buildStatCard(
        icon: Icons.directions_bus_rounded,
        title: 'Assigned Bus',
        value: 'Loading...',
        color: kAccentGold,
      );
    }
    if (_busErrorMessage != null) {
      return _buildStatCard(
        icon: Icons.directions_bus_rounded,
        title: 'Assigned Bus',
        value: 'Error loading bus',
        color: kAccentGold,
      );
    }
    if (_assignedBus == null) {
      return _buildStatCard(
        icon: Icons.directions_bus_rounded,
        title: 'Assigned Bus',
        value: 'No bus assigned',
        color: kAccentGold,
      );
    }
    int statusSeq = _assignedBus!['status_seq'] ?? 0;
    String statusLabel = busStatusMap[statusSeq]?['label'] ?? 'Unknown';
    Color statusColor = busStatusMap[statusSeq]?['color'] ?? Colors.grey;
    return Container(
      padding: EdgeInsets.all(responsiveFont(16, context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.directions_bus_rounded,
            color: kAccentGold,
            size: responsiveFont(22, context),
          ),
          SizedBox(height: responsiveFont(12, context)),
          Text(
            'Assigned Bus',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: kSlateGray,
              fontSize: responsiveFont(12, context),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: responsiveFont(4, context)),
          Text(
            '${_assignedBus!['model_name']} - ${_assignedBus!['license_plate']}',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: kAccentGold,
              fontSize: responsiveFont(14, context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: responsiveFont(8, context)),
          Row(
            children: [
              // Badge status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: responsiveFont(11, context),
                    color: statusColor,
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Tombol edit
              InkWell(
                onTap: () => _showEditBusStatusDialog(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.edit, color: kPrimaryBlue, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dialog untuk edit status bus
  void _showEditBusStatusDialog() async {
    if (_assignedBus == null) return;
    int currentStatus = _assignedBus!['status_seq'] ?? 0;
    int busId = _assignedBus!['id'];
    int? selectedStatus = currentStatus;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Bus Status'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var entry in busStatusMap.entries)
                    RadioListTile<int>(
                      value: entry.key,
                      groupValue: selectedStatus,
                      title: Text(entry.value['label']),
                      activeColor: entry.value['color'],
                      onChanged: (val) {
                        setState(() => selectedStatus = val);
                      },
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStatus == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _updateBusStatus(busId, selectedStatus!);
                    },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Method untuk update status bus dan refresh Assigned Bus
  Future<void> _updateBusStatus(int busId, int statusSeq) async {
    try {
      final result = await _fleetService.updateVehicleStatus(
        busId: busId,
        statusSeq: statusSeq,
      );
      if (result['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status bus berhasil diupdate!')),
          );
          await _loadAssignedBus();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal update status bus'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
