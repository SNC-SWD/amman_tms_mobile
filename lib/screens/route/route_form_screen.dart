import 'package:flutter/material.dart';
import 'package:amman_tms_mobile/models/route_line.dart' as model_route_line;

import 'routes_screen.dart' as routes;
import 'package:amman_tms_mobile/core/services/fleet_service.dart';
import 'package:amman_tms_mobile/core/services/bus_point_service.dart';
import 'package:amman_tms_mobile/models/fleet.dart';
import 'package:amman_tms_mobile/models/bus_point.dart';
import 'package:amman_tms_mobile/core/services/route_service.dart';

const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);
const kSlateGray = Color(0xFF4C5C74);
const kSoftGold = Color(0xFFE0B352);
const kBlueTint = Color(0xFFE6EDF6);

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

class RouteFormScreen extends StatefulWidget {
  final routes.RouteData? initialData;
  final String title;
  final void Function(routes.RouteData)? onSave;
  const RouteFormScreen({
    Key? key,
    this.initialData,
    required this.title,
    this.onSave,
  }) : super(key: key);

  @override
  State<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _RouteFormScreenState extends State<RouteFormScreen> {
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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController busController = TextEditingController();
  final TextEditingController boardingPointController = TextEditingController();
  final TextEditingController droppingPointController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  List<model_route_line.RouteLine> lines = [];
  final FleetService _fleetService = FleetService();
  final BusPointService _busPointService = BusPointService();
  final RouteService _routeService = RouteService();
  List<Fleet> _fleets = [];
  List<Fleet> _filteredFleets = [];
  List<BusPoint> _busPoints = [];
  List<BusPoint> _filteredBusPoints = [];
  Fleet? _selectedFleet;
  BusPoint? _selectedBoardingPoint;
  BusPoint? _selectedDroppingPoint;
  bool _isLoadingFleets = false;
  bool _isLoadingBusPoints = false;
  bool _isLoadingDialog = false;
  bool _isSubmitting = false;
  String? _fleetSearchQuery;
  String? _busPointSearchQuery;

  // Helper function to convert time format
  String _convertTimeFormat(String time, {bool toApi = false}) {
    try {
      if (toApi) {
        // Convert from HH:mm to H.M format for API
        final parts = time.split(':');
        final hours = int.parse(parts[0]);
        final minutes = parts[1];
        return '$hours.$minutes';
      } else {
        // Convert from H.M to HH:mm format for display
        final parts = time.split('.');
        if (parts.length != 2) return time;
        final hours = int.parse(parts[0]).toString().padLeft(2, '0');
        final minutes = parts[1].padLeft(2, '0');
        return '$hours:$minutes';
      }
    } catch (_) {
      return time;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData().then((_) {
      // Initialize form data after loading fleets and bus points
      if (widget.initialData != null) {
        print('📝 [RouteForm] Initializing form with existing route data');
        nameController.text = widget.initialData!.name;

        // Set fleet
        _selectedFleet = _fleets.firstWhere(
          (fleet) => fleet.id == widget.initialData!.busId,
          orElse: () => _fleets.first,
        );
        busController.text = _selectedFleet?.displayName ?? '';
        print('🚌 [RouteForm] Set fleet: ${_selectedFleet?.displayName}');

        // Set boarding point
        _selectedBoardingPoint = _busPoints.firstWhere(
          (point) => point.name == widget.initialData!.boardingPoint,
          orElse: () => _busPoints.first,
        );
        boardingPointController.text = _selectedBoardingPoint?.name ?? '';
        print(
          '📍 [RouteForm] Set boarding point: ${_selectedBoardingPoint?.name}',
        );

        // Set dropping point
        _selectedDroppingPoint = _busPoints.firstWhere(
          (point) => point.name == widget.initialData!.droppingPoint,
          orElse: () => _busPoints.first,
        );
        droppingPointController.text = _selectedDroppingPoint?.name ?? '';
        print(
          '📍 [RouteForm] Set dropping point: ${_selectedDroppingPoint?.name}',
        );

        // Set times
        startTimeController.text = _convertTimeFormat(
          widget.initialData!.startTime ?? '',
        );
        endTimeController.text = _convertTimeFormat(
          widget.initialData!.endTime ?? '',
        );
        print(
          '⏰ [RouteForm] Set times - Start: ${startTimeController.text}, End: ${endTimeController.text}',
        );

        // Initialize route lines with their IDs and convert time format
        lines = List<model_route_line.RouteLine>.from(
          widget.initialData?.lines?.map(
                (line) => model_route_line.RouteLine(
                  id: line.id,
                  from: line.from,
                  to: line.to,
                  startTime: _convertTimeFormat(line.startTime ?? ''),
                  endTime: _convertTimeFormat(line.endTime ?? ''),
                ),
              ) ??
              [],
        );
        print('🛣️ [RouteForm] Set route lines: ${lines.length} lines');
      }
    });
  }

  Future<void> _loadInitialData() async {
    print('🔄 [RouteForm] Starting initial data loading sequence');

    // Show loading state
    setState(() {
      _isLoadingDialog = true;
    });

    try {
      // Load fleets first
      print('🚌 [RouteForm] Loading fleets data...');
      await _loadFleets();

      // Then load bus points
      print('📍 [RouteForm] Loading bus points data...');
      await _loadBusPoints();

      print('✅ [RouteForm] All initial data loaded successfully');
    } catch (e) {
      print('❌ [RouteForm] Error loading initial data: $e');
    } finally {
      // Hide loading state
      setState(() {
        _isLoadingDialog = false;
      });
    }
  }

  Future<void> _loadFleets() async {
    print('🔄 [RouteForm] Loading fleets');
    setState(() {
      _isLoadingFleets = true;
    });

    try {
      final result = await _fleetService.getFleets();

      print('📡 [RouteForm] Fleet API response status: ${result['status']}');

      if (result['status'] == true) {
        final List<dynamic> fleetsData = result['data'];
        setState(() {
          _fleets = fleetsData.map((fleet) => Fleet.fromJson(fleet)).toList();
          _filteredFleets = List.from(_fleets);
        });
        print('✅ [RouteForm] Successfully loaded ${_fleets.length} fleets');
      } else {
        print('❌ [RouteForm] Failed to load fleets: ${result['message']}');
      }
    } catch (e) {
      print('❌ [RouteForm] Error loading fleets: $e');
    } finally {
      setState(() {
        _isLoadingFleets = false;
      });
    }
  }

  void _filterFleets(String query) {
    print('🔍 [RouteForm] Filtering fleets with query: $query');
    setState(() {
      if (query.isEmpty) {
        _filteredFleets = List.from(_fleets);
      } else {
        _filteredFleets = _fleets.where((fleet) {
          final nameLower = fleet.displayName.toLowerCase();
          final driverLower = fleet.driver.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              driverLower.contains(queryLower);
        }).toList();
      }
    });
    print('✅ [RouteForm] Filtered to ${_filteredFleets.length} fleets');
  }

  void _showFleetSearchDialog() async {
    print('🔍 [RouteForm] Opening fleet search dialog');
    final searchController = TextEditingController();
    Fleet? selectedFleet;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsiveFont(8, context)),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: kPrimaryBlue,
                  size: responsiveFont(20, context),
                ),
              ),
              SizedBox(width: responsiveFont(10, context)),
              Text(
                'Pilih Bus',
                style: TextStyle(
                  fontSize: responsiveFont(15, context),
                  fontWeight: FontWeight.bold,
                  color: kPrimaryBlue,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kLightGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBlueTint, width: 1),
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari bus...',
                      hintStyle: TextStyle(
                        color: kSlateGray.withOpacity(0.7),
                        fontSize: responsiveFont(11, context),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: kPrimaryBlue,
                        size: responsiveFont(16, context),
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: kSlateGray,
                                size: responsiveFont(14, context),
                              ),
                              onPressed: () {
                                print('🧹 [RouteForm] Clearing search query');
                                searchController.clear();
                                setState(() {
                                  _filterFleets('');
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: responsiveFont(12, context),
                        vertical: responsiveFont(8, context),
                      ),
                    ),
                    style: TextStyle(fontSize: responsiveFont(12, context)),
                    onChanged: (value) {
                      print('🔍 [RouteForm] Search query changed: $value');
                      setState(() {
                        _filterFleets(value);
                      });
                    },
                  ),
                ),
                SizedBox(height: responsiveFont(12, context)),
                if (_isLoadingFleets)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kAccentGold),
                      strokeWidth: 2,
                    ),
                  )
                else if (_filteredFleets.isEmpty)
                  Container(
                    padding: EdgeInsets.all(responsiveFont(16, context)),
                    decoration: BoxDecoration(
                      color: kLightGray,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_bus_outlined,
                          size: responsiveFont(32, context),
                          color: kSlateGray.withOpacity(0.5),
                        ),
                        SizedBox(height: responsiveFont(8, context)),
                        Text(
                          'Tidak ada bus ditemukan',
                          style: TextStyle(
                            color: kSlateGray,
                            fontSize: responsiveFont(12, context),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: responsiveFont(220, context),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredFleets.length,
                      itemBuilder: (context, index) {
                        final fleet = _filteredFleets[index];
                        return Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kBlueTint, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryBlue.withOpacity(0.03),
                                    blurRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  padding: EdgeInsets.all(
                                    responsiveFont(6, context),
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.directions_bus_rounded,
                                    color: kPrimaryBlue,
                                    size: 10,
                                  ),
                                ),
                                title: Text(
                                  fleet.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryBlue,
                                    fontSize: 11,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 9,
                                      color: kSlateGray,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      fleet.driver,
                                      style: TextStyle(
                                        color: kSlateGray,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 9,
                                  color: kSlateGray,
                                ),
                                onTap: () {
                                  print(
                                    '✅ [RouteForm] Selected fleet: ${fleet.displayName}',
                                  );
                                  selectedFleet = fleet;
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('❌ [RouteForm] Fleet selection cancelled');
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: kSlateGray,
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: responsiveFont(11, context),
                ),
              ),
              child: Text(
                'Batal',
                style: TextStyle(fontSize: responsiveFont(12, context)),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedFleet != null) {
      print(
        '✅ [RouteForm] Setting selected fleet: ${selectedFleet!.displayName}',
      );
      setState(() {
        _selectedFleet = selectedFleet;
        busController.text = selectedFleet!.displayName;
      });
    }
  }

  Future<void> _loadBusPoints() async {
    print('📍 [RouteForm] Loading bus points');
    setState(() {
      _isLoadingBusPoints = true;
    });

    try {
      final result = await _busPointService.getBusPoints();

      print(
        '📡 [RouteForm] Bus Points API response status: ${result['status']}',
      );

      if (result['status'] == true) {
        final List<dynamic> busPointsData = result['data'];
        setState(() {
          _busPoints = busPointsData
              .map((point) => BusPoint.fromJson(point))
              .toList();
          _filteredBusPoints = List.from(_busPoints);
        });
        print(
          '✅ [RouteForm] Successfully loaded ${_busPoints.length} bus points',
        );
      } else {
        print('❌ [RouteForm] Failed to load bus points: ${result['message']}');
      }
    } catch (e) {
      print('❌ [RouteForm] Error loading bus points: $e');
    } finally {
      setState(() {
        _isLoadingBusPoints = false;
      });
    }
  }

  void _filterBusPoints(String query) {
    print('🔍 [RouteForm] Filtering bus points with query: $query');
    setState(() {
      if (query.isEmpty) {
        _filteredBusPoints = List.from(_busPoints);
      } else {
        _filteredBusPoints = _busPoints.where((point) {
          final nameLower = point.name.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower);
        }).toList();
      }
    });
    print('✅ [RouteForm] Filtered to ${_filteredBusPoints.length} bus points');
  }

  void _showBusPointSearchDialog(bool isBoardingPoint) async {
    print('🔍 [RouteForm] Opening bus point search dialog');
    final searchController = TextEditingController();
    BusPoint? selectedPoint;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsiveFont(8, context)),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isBoardingPoint
                      ? Icons.location_on_rounded
                      : Icons.flag_rounded,
                  color: kPrimaryBlue,
                  size: responsiveFont(20, context),
                ),
              ),
              SizedBox(width: responsiveFont(10, context)),
              Text(
                isBoardingPoint
                    ? 'Pilih Boarding Point'
                    : 'Pilih Dropping Point',
                style: TextStyle(
                  fontSize: responsiveFont(15, context),
                  fontWeight: FontWeight.bold,
                  color: kPrimaryBlue,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kLightGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBlueTint, width: 1),
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari titik pemberhentian...',
                      hintStyle: TextStyle(
                        color: kSlateGray.withOpacity(0.7),
                        fontSize: responsiveFont(11, context),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: kPrimaryBlue,
                        size: responsiveFont(16, context),
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: kSlateGray,
                                size: responsiveFont(14, context),
                              ),
                              onPressed: () {
                                print('🧹 [RouteForm] Clearing search query');
                                searchController.clear();
                                setState(() {
                                  _filterBusPoints('');
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: responsiveFont(12, context),
                        vertical: responsiveFont(8, context),
                      ),
                    ),
                    style: TextStyle(fontSize: responsiveFont(12, context)),
                    onChanged: (value) {
                      print('🔍 [RouteForm] Search query changed: $value');
                      setState(() {
                        _filterBusPoints(value);
                      });
                    },
                  ),
                ),
                SizedBox(height: responsiveFont(12, context)),
                if (_isLoadingBusPoints)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kAccentGold),
                      strokeWidth: 2,
                    ),
                  )
                else if (_filteredBusPoints.isEmpty)
                  Container(
                    padding: EdgeInsets.all(responsiveFont(16, context)),
                    decoration: BoxDecoration(
                      color: kLightGray,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBoardingPoint
                              ? Icons.location_off_rounded
                              : Icons.flag_outlined,
                          size: responsiveFont(32, context),
                          color: kSlateGray.withOpacity(0.5),
                        ),
                        SizedBox(height: responsiveFont(8, context)),
                        Text(
                          'Tidak ada titik pemberhentian ditemukan',
                          style: TextStyle(
                            color: kSlateGray,
                            fontSize: responsiveFont(12, context),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: responsiveFont(220, context),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredBusPoints.length,
                      itemBuilder: (context, index) {
                        final point = _filteredBusPoints[index];
                        return Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kBlueTint, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryBlue.withOpacity(0.03),
                                    blurRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  padding: EdgeInsets.all(
                                    responsiveFont(6, context),
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isBoardingPoint
                                        ? Icons.location_on_rounded
                                        : Icons.flag_rounded,
                                    color: kPrimaryBlue,
                                    size: 9,
                                  ),
                                ),
                                title: Text(
                                  point.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryBlue,
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 9,
                                  color: kSlateGray,
                                ),
                                onTap: () {
                                  print(
                                    '✅ [RouteForm] Selected point: ${point.name}',
                                  );
                                  selectedPoint = point;
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('❌ [RouteForm] Point selection cancelled');
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: kSlateGray,
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: responsiveFont(11, context),
                ),
              ),
              child: Text(
                'Batal',
                style: TextStyle(fontSize: responsiveFont(12, context)),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedPoint != null) {
      print('✅ [RouteForm] Setting selected point: ${selectedPoint!.name}');
      setState(() {
        if (isBoardingPoint) {
          _selectedBoardingPoint = selectedPoint;
          boardingPointController.text = selectedPoint!.name;
        } else {
          _selectedDroppingPoint = selectedPoint;
          droppingPointController.text = selectedPoint!.name;
        }
      });
    }
  }

  Future<void> pickTime(TextEditingController controller) async {
    // Convert current time to TimeOfDay if exists
    TimeOfDay initial = TimeOfDay.now();
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        initial = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (_) {
        // If parsing fails, use current time
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryBlue,
              secondary: kAccentGold,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format time as HH:mm for display
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formatted;
    }
  }

  void _addOrEditLine({model_route_line.RouteLine? initial, int? index}) async {
    final fromController = TextEditingController(text: initial?.from ?? '');
    final toController = TextEditingController(text: initial?.to ?? '');
    final startTimeController = TextEditingController(
      text: initial?.startTime ?? '',
    );
    final endTimeController = TextEditingController(
      text: initial?.endTime ?? '',
    );
    final formKeyLine = GlobalKey<FormState>();
    BusPoint? selectedFromPoint;
    BusPoint? selectedToPoint;

    // Set initial selected points if editing
    if (initial != null) {
      selectedFromPoint = _busPoints.firstWhere(
        (point) => point.name == initial.from,
        orElse: () => _busPoints.first,
      );
      selectedToPoint = _busPoints.firstWhere(
        (point) => point.name == initial.to,
        orElse: () => _busPoints.first,
      );
    }

    final result = await showModalBottomSheet<model_route_line.RouteLine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kSlateGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: kPrimaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.alt_route_rounded,
                            color: kPrimaryBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          initial == null ? 'Tambah Line' : 'Edit Line',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: kPrimaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: formKeyLine,
                      child: Column(
                        children: [
                          DropdownButtonFormField<BusPoint>(
                            value: selectedFromPoint,
                            decoration: InputDecoration(
                              labelText: 'Dari (From)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(
                                Icons.location_on_rounded,
                                color: kPrimaryBlue,
                              ),
                            ),
                            items: _busPoints.map((BusPoint point) {
                              return DropdownMenuItem<BusPoint>(
                                value: point,
                                child: Text(point.name),
                              );
                            }).toList(),
                            onChanged: (BusPoint? newValue) {
                              setState(() {
                                selectedFromPoint = newValue;
                                fromController.text = newValue?.name ?? '';
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<BusPoint>(
                            value: selectedToPoint,
                            decoration: InputDecoration(
                              labelText: 'Ke (To)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(
                                Icons.flag_rounded,
                                color: kPrimaryBlue,
                              ),
                            ),
                            items: _busPoints.map((BusPoint point) {
                              return DropdownMenuItem<BusPoint>(
                                value: point,
                                child: Text(point.name),
                              );
                            }).toList(),
                            onChanged: (BusPoint? newValue) {
                              setState(() {
                                selectedToPoint = newValue;
                                toController.text = newValue?.name ?? '';
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: startTimeController,
                            readOnly: true,
                            onTap: () async {
                              await pickTime(startTimeController);
                            },
                            decoration: InputDecoration(
                              labelText: 'Jam Berangkat',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(
                                Icons.access_time_rounded,
                                color: kAccentGold,
                              ),
                              suffixIcon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: kSlateGray,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: endTimeController,
                            readOnly: true,
                            onTap: () async {
                              await pickTime(endTimeController);
                            },
                            decoration: InputDecoration(
                              labelText: 'Jam Tiba',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(
                                Icons.access_time_filled_rounded,
                                color: kAccentGold,
                              ),
                              suffixIcon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: kSlateGray,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: kSlateGray,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentGold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (formKeyLine.currentState!.validate()) {
                              Navigator.of(context).pop(
                                model_route_line.RouteLine(
                                  id: initial?.id,
                                  from: fromController.text,
                                  to: toController.text,
                                  startTime: startTimeController.text,
                                  endTime: endTimeController.text,
                                ),
                              );
                            }
                          },
                          child: Text(initial == null ? 'Tambah' : 'Simpan'),
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
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          lines[index] = result;
        } else {
          lines.add(result);
        }
      });
    }
  }

  void _removeLine(int index) {
    setState(() {
      lines.removeAt(index);
    });
  }

  void _submit() async {
    if (formKey.currentState!.validate()) {
      print('🔍 [RouteForm] Validating form fields...');
      print('🚌 Fleet: ${_selectedFleet?.displayName}');
      print('📍 Boarding Point: ${_selectedBoardingPoint?.name}');
      print('📍 Dropping Point: ${_selectedDroppingPoint?.name}');
      print('⏰ Start Time: ${startTimeController.text}');
      print('⏰ End Time: ${endTimeController.text}');
      print('🛣️ Route Lines: ${lines.length}');
      print('🆔 Route ID: ${widget.initialData?.id}');

      // Final validation check
      if (_selectedFleet == null ||
          _selectedBoardingPoint == null ||
          _selectedDroppingPoint == null ||
          startTimeController.text.isEmpty ||
          endTimeController.text.isEmpty ||
          lines.isEmpty) {
        print('❌ [RouteForm] Validation failed: Missing required fields');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mohon lengkapi semua field yang diperlukan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final routeLines = lines.map((line) {
          final fromPoint = _busPoints.firstWhere(
            (point) => point.name == line.from,
            orElse: () => _busPoints.first,
          );
          final toPoint = _busPoints.firstWhere(
            (point) => point.name == line.to,
            orElse: () => _busPoints.first,
          );
          return {
            'id': line.id,
            'bording_from': fromPoint.id,
            'to': toPoint.id,
            'start_times': _convertTimeFormat(
              line.startTime ?? '',
              toApi: true,
            ),
            'end_times': _convertTimeFormat(line.endTime ?? '', toApi: true),
          };
        }).toList();

        print('📤 [RouteForm] Submitting route data...');
        Map<String, dynamic> result;
        if (widget.initialData != null) {
          // Validate route ID for update
          final routeId = widget.initialData!.id;
          print('🆔 [RouteForm] Updating route with ID: $routeId');

          if (routeId == null || routeId <= 0) {
            print('❌ [RouteForm] Invalid route ID: $routeId');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ID rute tidak valid'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pop(false);
            return;
          }

          result = await _routeService.updateRoute(
            name: widget.initialData!.name,
            routeId: routeId,
            boardingId: _selectedBoardingPoint!.id,
            droppingId: _selectedDroppingPoint!.id,
            fleetId: _selectedFleet!.id,
            startTime: startTimeController.text,
            endTime: endTimeController.text,
            routeLines: routeLines,
          );
        } else {
          print('➕ [RouteForm] Creating new route...');
          result = await _routeService.createRoute(
            boardingPoint: _selectedBoardingPoint!,
            droppingPoint: _selectedDroppingPoint!,
            fleet: _selectedFleet!,
            startTime: startTimeController.text,
            endTime: endTimeController.text,
            routeLines: lines,
            busPoints: _busPoints,
          );
        }

        if (result['status'] == true) {
          print('✅ [RouteForm] Route saved successfully');
          if (widget.onSave != null) {
            final route = routes.RouteData(
              id: widget.initialData?.id,
              bus: _selectedFleet!.displayName,
              busId: _selectedFleet!.id,
              boardingPoint: boardingPointController.text,
              droppingPoint: droppingPointController.text,
              startTime: _convertTimeFormat(
                startTimeController.text,
                toApi: true,
              ),
              endTime: _convertTimeFormat(endTimeController.text, toApi: true),
              lines: lines,
            );
            print('🆔 [RouteForm] Saving route with ID: ${route.id}');
            widget.onSave!(route);
          }

          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop(true);
        } else {
          print('❌ [RouteForm] Failed to save route: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal menyimpan rute'),
              backgroundColor: Colors.red,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop(false);
        }
      } catch (e) {
        print('❌ [RouteForm] Error saving route: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop(false);
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = responsivePadding(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: responsiveFont(16, context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kPrimaryBlue,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: busController,
                    readOnly: true,
                    onTap: _showFleetSearchDialog,
                    style: TextStyle(fontSize: responsiveFont(11, context)),
                    decoration: InputDecoration(
                      labelText: 'Bus',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelStyle: TextStyle(
                        fontSize: responsiveFont(12, context),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(
                        Icons.directions_bus_rounded,
                        color: kSoftGold,
                      ),
                      suffixIcon: _isLoadingDialog
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  kAccentGold,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: kSlateGray,
                            ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  SizedBox(height: responsiveFont(14, context)),
                  TextFormField(
                    controller: boardingPointController,
                    readOnly: true,
                    onTap: () => _showBusPointSearchDialog(true),
                    style: TextStyle(fontSize: responsiveFont(11, context)),
                    decoration: InputDecoration(
                      labelText: 'Boarding Point',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelStyle: TextStyle(
                        fontSize: responsiveFont(12, context),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on_rounded,
                        color: kPrimaryBlue,
                      ),
                      suffixIcon: _isLoadingDialog
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  kAccentGold,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: kSlateGray,
                            ),
                    ),
                  ),
                  SizedBox(height: responsiveFont(14, context)),
                  TextFormField(
                    controller: droppingPointController,
                    readOnly: true,
                    onTap: () => _showBusPointSearchDialog(false),
                    style: TextStyle(fontSize: responsiveFont(11, context)),
                    decoration: InputDecoration(
                      labelText: 'Dropping Point',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelStyle: TextStyle(
                        fontSize: responsiveFont(12, context),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(
                        Icons.flag_rounded,
                        color: kAccentGold,
                      ),
                      suffixIcon: _isLoadingDialog
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  kAccentGold,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: kSlateGray,
                            ),
                    ),
                  ),
                  SizedBox(height: responsiveFont(14, context)),
                  TextFormField(
                    controller: startTimeController,
                    readOnly: true,
                    onTap: () => pickTime(startTimeController),
                    style: TextStyle(fontSize: responsiveFont(11, context)),
                    decoration: InputDecoration(
                      labelText: 'Jam Berangkat',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelStyle: TextStyle(
                        fontSize: responsiveFont(12, context),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(
                        Icons.access_time_rounded,
                        color: kAccentGold,
                      ),
                      suffixIcon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: kSlateGray,
                      ),
                    ),
                  ),
                  SizedBox(height: responsiveFont(14, context)),
                  TextFormField(
                    controller: endTimeController,
                    readOnly: true,
                    onTap: () => pickTime(endTimeController),
                    style: TextStyle(fontSize: responsiveFont(11, context)),
                    decoration: InputDecoration(
                      labelText: 'Jam Tiba',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelStyle: TextStyle(
                        fontSize: responsiveFont(12, context),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(
                        Icons.access_time_filled_rounded,
                        color: kAccentGold,
                      ),
                      suffixIcon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: kSlateGray,
                      ),
                    ),
                  ),
                  SizedBox(height: responsiveFont(24, context)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Route Lines',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: responsiveFont(14, context),
                            color: kPrimaryBlue,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _addOrEditLine(),
                          icon: Icon(
                            Icons.add,
                            color: kAccentGold,
                            size: responsiveFont(16, context),
                          ),
                          label: Text(
                            'Add Line',
                            style: TextStyle(
                              color: kAccentGold,
                              fontSize: responsiveFont(12, context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  lines.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: responsiveFont(16, context),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.alt_route_rounded,
                                color: kBlueTint,
                                size: responsiveFont(36, context),
                              ),
                              SizedBox(height: responsiveFont(8, context)),
                              Text(
                                'Belum ada route line',
                                style: TextStyle(
                                  color: kSlateGray,
                                  fontSize: responsiveFont(12, context),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            ...lines.asMap().entries.map(
                              (entry) => Container(
                                margin: EdgeInsets.symmetric(
                                  vertical: responsiveFont(8, context),
                                ),
                                child: Material(
                                  color: Colors.white,
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(18),
                                  shadowColor: kPrimaryBlue.withOpacity(0.08),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsiveFont(14, context),
                                      vertical: responsiveFont(12, context),
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.location_on_rounded,
                                                  color: kPrimaryBlue,
                                                  size: responsiveFont(
                                                    14,
                                                    context,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: responsiveFont(
                                                    6,
                                                    context,
                                                  ),
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    entry.value.from,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: responsiveFont(
                                                        12,
                                                        context,
                                                      ),
                                                      color: kPrimaryBlue,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: responsiveFont(
                                                    8,
                                                    context,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: kSlateGray,
                                                  size: responsiveFont(
                                                    12,
                                                    context,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: responsiveFont(
                                                    8,
                                                    context,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.flag_rounded,
                                                  color: kAccentGold,
                                                  size: responsiveFont(
                                                    14,
                                                    context,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: responsiveFont(
                                                    6,
                                                    context,
                                                  ),
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    entry.value.to,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: responsiveFont(
                                                        12,
                                                        context,
                                                      ),
                                                      color: kAccentGold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: responsiveFont(
                                                8,
                                                context,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  color: kSlateGray,
                                                  size: responsiveFont(
                                                    12,
                                                    context,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: responsiveFont(
                                                    4,
                                                    context,
                                                  ),
                                                ),
                                                Text(
                                                  'Berangkat:',
                                                  style: TextStyle(
                                                    fontSize: responsiveFont(
                                                      10,
                                                      context,
                                                    ),
                                                    color: kSlateGray,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: responsiveFont(
                                                    2,
                                                    context,
                                                  ),
                                                ),
                                                Text(
                                                  entry.value.startTime ?? '-',
                                                  style: TextStyle(
                                                    fontSize: responsiveFont(
                                                      11,
                                                      context,
                                                    ),
                                                    color: kPrimaryBlue,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: responsiveFont(
                                                    12,
                                                    context,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons
                                                      .access_time_filled_rounded,
                                                  color: kSlateGray,
                                                  size: responsiveFont(
                                                    12,
                                                    context,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: responsiveFont(
                                                    4,
                                                    context,
                                                  ),
                                                ),
                                                Text(
                                                  'Tiba:',
                                                  style: TextStyle(
                                                    fontSize: responsiveFont(
                                                      10,
                                                      context,
                                                    ),
                                                    color: kSlateGray,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: responsiveFont(
                                                    2,
                                                    context,
                                                  ),
                                                ),
                                                Text(
                                                  entry.value.endTime ?? '-',
                                                  style: TextStyle(
                                                    fontSize: responsiveFont(
                                                      11,
                                                      context,
                                                    ),
                                                    color: kAccentGold,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: responsiveFont(
                                                6,
                                                context,
                                              ),
                                            ),
                                            Divider(
                                              height: responsiveFont(
                                                12,
                                                context,
                                              ),
                                              thickness: 0.7,
                                              color: kBlueTint,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit_outlined,
                                                    color: kPrimaryBlue,
                                                    size: responsiveFont(
                                                      16,
                                                      context,
                                                    ),
                                                  ),
                                                  tooltip: 'Edit',
                                                  onPressed: () =>
                                                      _addOrEditLine(
                                                        initial: entry.value,
                                                        index: entry.key,
                                                      ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                    size: responsiveFont(
                                                      16,
                                                      context,
                                                    ),
                                                  ),
                                                  tooltip: 'Hapus',
                                                  onPressed: () =>
                                                      _removeLine(entry.key),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  SizedBox(height: responsiveFont(24, context)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: kSlateGray,
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: responsiveFont(11, context),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: responsiveFont(12, context),
                          ),
                        ),
                      ),
                      SizedBox(width: responsiveFont(12, context)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentGold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: responsiveFont(11, context),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsiveFont(8, context),
                            vertical: responsiveFont(2, context),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: responsiveFont(16, context),
                                  height: responsiveFont(16, context),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize: responsiveFont(12, context),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoadingDialog || _isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kAccentGold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}