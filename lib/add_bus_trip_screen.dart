import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'core/services/bus_point_service.dart';
import 'core/services/fleet_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/bus_trip_service.dart';
import 'models/bus_point.dart';
import 'models/fleet.dart';
import 'route_form_screen.dart';

const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);
const kSlateGray = Color(0xFF4C5C74);
const kSoftGold = Color(0xFFE0B352);
const kBlueTint = Color(0xFFE6EDF6);

class AddBusTripScreen extends StatefulWidget {
  const AddBusTripScreen({super.key});

  @override
  State<AddBusTripScreen> createState() => _AddBusTripScreenState();
}

class _AddBusTripScreenState extends State<AddBusTripScreen> {
  final BusPointService _busPointService = BusPointService();
  final FleetService _fleetService = FleetService();
  final AuthService _authService = AuthService();
  final BusTripService _busTripService = BusTripService();
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  BusPoint? _selectedFromLocation;
  BusPoint? _selectedToLocation;
  Fleet? _selectedFleet;
  bool _isLoading = false;
  bool _isLoadingData = false;
  String? _errorMessage;

  List<BusPoint> _busPoints = [];
  List<Fleet> _fleets = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      // Load bus points and fleets in parallel
      await Future.wait([_loadBusPoints(), _loadFleets()]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadBusPoints() async {
    try {
      final result = await _busPointService.getBusPoints();
      if (result['status'] == true) {
        final List<dynamic> busPointsData = result['data'];
        setState(() {
          _busPoints = busPointsData
              .map((point) => BusPoint.fromJson(point))
              .toList();
        });
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      throw Exception('Failed to load bus points: $e');
    }
  }

  Future<void> _loadFleets() async {
    try {
      final result = await _fleetService.getFleets();
      if (result['status'] == true) {
        final List<dynamic> fleetsData = result['data'];
        setState(() {
          _fleets = fleetsData.map((fleet) => Fleet.fromJson(fleet)).toList();
        });
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      throw Exception('Failed to load fleets: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Helper badge status
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'standby':
        color = Colors.green;
        break;
      case 'driving':
        color = Colors.blue;
        break;
      case 'drop off or pick up':
        color = Colors.orange;
        break;
      case 'maintenance':
        color = Colors.red;
        break;
      case 'rest':
        color = Colors.purple;
        break;
      case 'change shift':
        color = Colors.brown;
        break;
      case 'no driver':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Dialog pencarian BusPoint
  Future<void> _showBusPointDialog({required bool isFrom}) async {
    final searchController = TextEditingController();
    List<BusPoint> filtered = List.from(_busPoints);
    BusPoint? selected = isFrom ? _selectedFromLocation : _selectedToLocation;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Pilih ${isFrom ? 'From' : 'To'} Location'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari lokasi',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      setState(() {
                        filtered = _busPoints
                            .where(
                              (point) => point.name.toLowerCase().contains(
                                query.toLowerCase(),
                              ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    width: double.maxFinite,
                    child: filtered.isEmpty
                        ? const Center(child: Text('Tidak ada data'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, idx) {
                              final point = filtered[idx];
                              final isSelected = selected?.id == point.id;
                              return Material(
                                color: isSelected
                                    ? kPrimaryBlue.withOpacity(0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                child: ListTile(
                                  leading: Container(
                                    decoration: BoxDecoration(
                                      color: kPrimaryBlue.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      isFrom
                                          ? Icons.location_on_rounded
                                          : Icons.flag_rounded,
                                      color: isFrom
                                          ? kPrimaryBlue
                                          : kAccentGold,
                                    ),
                                  ),
                                  title: Text(
                                    point.name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: kPrimaryBlue,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: kAccentGold,
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.of(context).pop(point);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result is BusPoint) {
        setState(() {
          if (isFrom) {
            _selectedFromLocation = result;
          } else {
            _selectedToLocation = result;
          }
        });
      }
    });
  }

  // Dialog pencarian Fleet
  Future<void> _showFleetDialog() async {
    final searchController = TextEditingController();
    List<Fleet> filtered = List.from(_fleets);
    Fleet? selected = _selectedFleet;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Pilih Bus/Fleet'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari bus/fleet',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      setState(() {
                        filtered = _fleets
                            .where(
                              (fleet) =>
                                  fleet.displayName.toLowerCase().contains(
                                    query.toLowerCase(),
                                  ) ||
                                  fleet.driver.toLowerCase().contains(
                                    query.toLowerCase(),
                                  ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    width: double.maxFinite,
                    child: filtered.isEmpty
                        ? const Center(child: Text('Tidak ada data'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, idx) {
                              final fleet = filtered[idx];
                              final isSelected = selected?.id == fleet.id;
                              return Material(
                                color: isSelected
                                    ? kAccentGold.withOpacity(0.10)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                child: ListTile(
                                  leading: Container(
                                    decoration: BoxDecoration(
                                      color: kSoftGold.withOpacity(0.13),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.directions_bus_rounded,
                                      color: kSoftGold,
                                    ),
                                  ),
                                  title: Text(
                                    fleet.displayName,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: kPrimaryBlue,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            size: 16,
                                            color: kSlateGray,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              fleet.driver,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: kSlateGray,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      _buildStatusBadge(fleet.status),
                                    ],
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: kAccentGold,
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.of(context).pop(fleet);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result is Fleet) {
        setState(() {
          _selectedFleet = result;
        });
      }
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        if (_selectedDate == null ||
            _selectedFromLocation == null ||
            _selectedToLocation == null ||
            _selectedFleet == null) {
          throw Exception('Required data is missing');
        }

        final result = await _busTripService.createBusTrip(
          date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
          fromLocation: _selectedFromLocation!.id,
          toLocation: _selectedToLocation!.id,
          fleetId: _selectedFleet!.id,
          passengerQuantity: 0,
        );

        final wizardData = result['data'];
        final searchResultIds =
            wizardData?['result']?['search_result_ids'] as List?;
        if (result['status'] == true &&
            (searchResultIds == null || searchResultIds.isEmpty)) {
          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Rute belum tersedia'),
                content: const Text(
                  'Rute belum tersedia. Apakah Anda ingin membuat rute ini?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentGold,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              RouteFormScreen(title: 'Tambah Rute'),
                        ),
                      );
                    },
                    child: const Text('Buat Rute'),
                  ),
                ],
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (result['status'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bus trip created successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGray,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        title: const Text(
          'New Trip',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadInitialData,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentGold,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Field
                        TextFormField(
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          initialValue: _selectedDate != null
                              ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                              : 'Select Date',
                          decoration: InputDecoration(
                            labelText: 'Trip Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(
                              Icons.calendar_today_rounded,
                              color: kPrimaryBlue,
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // From Location Field
                        TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _selectedFromLocation?.name ?? '',
                          ),
                          onTap: () => _showBusPointDialog(isFrom: true),
                          decoration: InputDecoration(
                            labelText: 'From Location',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(
                              Icons.location_on_rounded,
                              color: kPrimaryBlue,
                            ),
                            suffixIcon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                            ),
                          ),
                          validator: (v) => (_selectedFromLocation == null)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // To Location Field
                        TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _selectedToLocation?.name ?? '',
                          ),
                          onTap: () => _showBusPointDialog(isFrom: false),
                          decoration: InputDecoration(
                            labelText: 'To Location',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(
                              Icons.flag_rounded,
                              color: kAccentGold,
                            ),
                            suffixIcon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                            ),
                          ),
                          validator: (v) =>
                              (_selectedToLocation == null) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Fleet Field
                        TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _selectedFleet?.displayName ?? '',
                          ),
                          onTap: _showFleetDialog,
                          decoration: InputDecoration(
                            labelText: 'Bus/Fleet',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(
                              Icons.directions_bus_rounded,
                              color: kSoftGold,
                            ),
                            suffixIcon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                            ),
                          ),
                          validator: (v) =>
                              (_selectedFleet == null) ? 'Required' : null,
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccentGold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _submitForm,
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
